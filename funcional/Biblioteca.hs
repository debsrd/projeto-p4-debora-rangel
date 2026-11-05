{-
 Biblioteca.hs

 NUCLEO PURO do Sistema de Emprestimo de Livros (Etapa 6 - paradigma funcional).

 Este modulo NAO importa nada de entrada/saida (nem System.IO, nem IO nas
 assinaturas). Todas as funcoes daqui sao PURAS: dado o mesmo argumento,
 devolvem sempre o mesmo resultado, e nunca alteram nada fora de si.
 Quem interage com o mundo externo (teclado/tela) e o arquivo Main.hs.

 Ideia central: nenhuma operacao "modifica" a biblioteca. Cada operacao
 recebe a biblioteca atual e DEVOLVE UMA NOVA biblioteca (ou um erro).
-}
module Biblioteca where

import Control.Monad (foldM)
import qualified Data.Map as Map
import Data.Maybe (catMaybes, listToMaybe, mapMaybe)

-- ---------------------------------------------------------------------
-- Dados (todos imutaveis: em Haskell nao existe atribuicao a campo)
-- ---------------------------------------------------------------------

type CodigoLivro   = Int
type CodigoUsuario = Int

data Livro = Livro
  { lvCodigo :: CodigoLivro
  , lvTitulo :: String
  , lvCopias :: Int
  } deriving (Show, Eq)

data Usuario = Usuario
  { usCodigo :: CodigoUsuario
  , usNome   :: String
  } deriving (Show, Eq)

-- Um emprestimo e apenas o par (usuario, livro). Quando o livro e devolvido,
-- o par simplesmente deixa de existir na nova lista (nao ha flag "ativo").
data Emprestimo = Emprestimo
  { emUsuario :: CodigoUsuario
  , emLivro   :: CodigoLivro
  } deriving (Show, Eq)

-- O "estado" do sistema e um VALOR, nao uma variavel que muda.
data Biblioteca = Biblioteca
  { livros      :: Map.Map CodigoLivro Livro
  , usuarios    :: Map.Map CodigoUsuario Usuario
  , emprestimos :: [Emprestimo]
  } deriving (Show, Eq)

-- Erros sao dados comuns (um tipo soma), tratados por casamento de padrao.
data Erro
  = LivroJaCadastrado
  | UsuarioJaCadastrado
  | CopiasInvalidas
  | LivroNaoEncontrado
  | UsuarioNaoEncontrado
  | LivroIndisponivel
  | LimiteAtingido
  | TituloJaEmprestado
  | EmprestimoNaoEncontrado
  deriving (Show, Eq)

limiteEmprestimos :: Int
limiteEmprestimos = 3

bibliotecaVazia :: Biblioteca
bibliotecaVazia = Biblioteca
  { livros      = Map.empty
  , usuarios    = Map.empty
  , emprestimos = []
  }

-- ---------------------------------------------------------------------
-- Cadastros: Biblioteca -> Either Erro Biblioteca (transformacoes de dados)
-- ---------------------------------------------------------------------

cadastrarLivro :: CodigoLivro -> String -> Int -> Biblioteca -> Either Erro Biblioteca
cadastrarLivro cod tit n b
  | Map.member cod (livros b) = Left LivroJaCadastrado
  | n < 0                     = Left CopiasInvalidas
  | otherwise                 = Right (b { livros = Map.insert cod (Livro cod tit n) (livros b) })

cadastrarUsuario :: CodigoUsuario -> String -> Biblioteca -> Either Erro Biblioteca
cadastrarUsuario cod nm b
  | Map.member cod (usuarios b) = Left UsuarioJaCadastrado
  | otherwise                   = Right (b { usuarios = Map.insert cod (Usuario cod nm) (usuarios b) })

-- ---------------------------------------------------------------------
-- Consultas auxiliares (puras, so leem)
-- ---------------------------------------------------------------------

-- Composicao de funcoes: filtra pelos emprestimos do usuario, depois de
-- extrair a lista de emprestimos da biblioteca.
emprestimosDe :: CodigoUsuario -> Biblioteca -> [Emprestimo]
emprestimosDe cu = filter ((== cu) . emUsuario) . emprestimos

ehEmprestimo :: CodigoUsuario -> CodigoLivro -> Emprestimo -> Bool
ehEmprestimo cu cl e = emUsuario e == cu && emLivro e == cl

-- ---------------------------------------------------------------------
-- Regras de emprestimo: funcoes de primeira classe
-- ---------------------------------------------------------------------

-- Uma regra e uma FUNCAO. Devolve Nothing se a regra e satisfeita ou
-- (Just erro) se foi violada. Regras sao valores comuns: ficam em listas,
-- sao passadas como argumento e podem ser criadas por outras funcoes.
type Regra = Biblioteca -> Usuario -> Livro -> Maybe Erro

violaSe :: Bool -> Erro -> Maybe Erro
violaSe condicao erro = if condicao then Just erro else Nothing

regraDisponivel :: Regra
regraDisponivel _ _ l = violaSe (lvCopias l <= 0) LivroIndisponivel

-- Funcao de alta ordem no sentido de "fabrica": recebe o limite e DEVOLVE uma regra.
regraLimite :: Int -> Regra
regraLimite limite b u _ =
  violaSe (length (emprestimosDe (usCodigo u) b) >= limite) LimiteAtingido

regraTituloNaoDuplicado :: Regra
regraTituloNaoDuplicado b u l =
  violaSe (any ((== lvCodigo l) . emLivro) (emprestimosDe (usCodigo u) b)) TituloJaEmprestado

-- A ordem da lista e a ordem de verificacao.
regrasPadrao :: [Regra]
regrasPadrao = [regraDisponivel, regraLimite limiteEmprestimos, regraTituloNaoDuplicado]

-- Funcao de alta ordem: recebe uma lista de funcoes (as regras) e aplica
-- cada uma. Como Haskell e preguicoso, para na primeira violacao.
primeiraViolacao :: [Regra] -> Biblioteca -> Usuario -> Livro -> Maybe Erro
primeiraViolacao regras b u l = listToMaybe (catMaybes (map (\r -> r b u l) regras))

-- ---------------------------------------------------------------------
-- Emprestimo e devolucao
-- ---------------------------------------------------------------------

procurarLivro :: CodigoLivro -> Biblioteca -> Either Erro Livro
procurarLivro cl b = maybe (Left LivroNaoEncontrado) Right (Map.lookup cl (livros b))

procurarUsuario :: CodigoUsuario -> Biblioteca -> Either Erro Usuario
procurarUsuario cu b = maybe (Left UsuarioNaoEncontrado) Right (Map.lookup cu (usuarios b))

-- Recebe as regras como parametro (extensibilidade sem alterar esta funcao).
-- O bloco "do" encadeia passos que podem falhar: o primeiro Left interrompe tudo.
emprestarCom :: [Regra] -> CodigoUsuario -> CodigoLivro -> Biblioteca -> Either Erro Biblioteca
emprestarCom regras cu cl b = do
  l <- procurarLivro cl b
  u <- procurarUsuario cu b
  case primeiraViolacao regras b u l of
    Just erro -> Left erro
    Nothing   -> Right (b
      { livros      = Map.insert cl (l { lvCopias = lvCopias l - 1 }) (livros b)
      , emprestimos = emprestimos b ++ [Emprestimo cu cl]
      })

-- Aplicacao parcial (currying): fixa o primeiro argumento de emprestarCom.
emprestar :: CodigoUsuario -> CodigoLivro -> Biblioteca -> Either Erro Biblioteca
emprestar = emprestarCom regrasPadrao

devolver :: CodigoUsuario -> CodigoLivro -> Biblioteca -> Either Erro Biblioteca
devolver cu cl b = do
  l <- procurarLivro cl b
  _ <- procurarUsuario cu b
  if any (ehEmprestimo cu cl) (emprestimos b)
    then Right (b
      { livros      = Map.insert cl (l { lvCopias = lvCopias l + 1 }) (livros b)
      , emprestimos = filter (not . ehEmprestimo cu cl) (emprestimos b)
      })
    else Left EmprestimoNaoEncontrado

-- ---------------------------------------------------------------------
-- Consultas
-- ---------------------------------------------------------------------

consultarDisponibilidade :: CodigoLivro -> Biblioteca -> Either Erro Int
consultarDisponibilidade cl b = fmap lvCopias (procurarLivro cl b)

consultarEmprestimos :: CodigoUsuario -> Biblioteca -> Either Erro [String]
consultarEmprestimos cu b = do
  _ <- procurarUsuario cu b
  Right (mapMaybe tituloDe (emprestimosDe cu b))
  where
    tituloDe e = fmap lvTitulo (Map.lookup (emLivro e) (livros b))

-- Aplica uma LISTA DE OPERACOES (funcoes) em sequencia ao estado, parando no
-- primeiro erro. foldM e uma funcao de alta ordem: "dobra" a lista de funcoes
-- sobre o estado inicial. Nao ha laco nem variavel de acumulacao mutavel.
aplicarTodas :: [Biblioteca -> Either Erro Biblioteca] -> Biblioteca -> Either Erro Biblioteca
aplicarTodas operacoes inicial = foldM (\estado operacao -> operacao estado) inicial operacoes

-- ---------------------------------------------------------------------
-- Mensagens (casamento de padrao sobre o tipo Erro)
-- ---------------------------------------------------------------------

mensagem :: Erro -> String
mensagem LivroJaCadastrado       = "Ja existe um livro cadastrado com esse codigo."
mensagem UsuarioJaCadastrado     = "Ja existe um usuario cadastrado com esse codigo."
mensagem CopiasInvalidas         = "O numero de copias nao pode ser negativo."
mensagem LivroNaoEncontrado      = "Livro nao encontrado/cadastrado."
mensagem UsuarioNaoEncontrado    = "Usuario nao encontrado/cadastrado."
mensagem LivroIndisponivel       = "O livro esta indisponivel no momento."
mensagem LimiteAtingido          = "O usuario atingiu o limite de " ++ show limiteEmprestimos ++ " livros emprestados."
mensagem TituloJaEmprestado      = "O usuario ja possui uma copia desse titulo emprestada."
mensagem EmprestimoNaoEncontrado = "Nao ha emprestimo correspondente a essa devolucao."
