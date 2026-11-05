{-
 Main.hs

 Camada de ENTRADA/SAIDA (a "casca impura") do sistema funcional.

 Duas partes bem separadas neste arquivo:
   1. PARTE PURA   - casos de teste (dados) e formatacao de texto;
   2. PARTE IMPURA - tudo que tem tipo IO: ler teclado, imprimir, encerrar.

 Toda a logica de negocio esta em Biblioteca.hs (puro). Aqui so se le
 dados do mundo externo, chama-se uma funcao pura e imprime-se o resultado.

 Uso (a partir da pasta funcional/):
   runghc Main.hs             -> sistema interativo (menu)
   runghc Main.hs --validar   -> roda os 15 casos da Etapa 2
-}
module Main (main) where

import Biblioteca
import System.Environment (getArgs)
import System.Exit (ExitCode (..), exitWith)
import System.IO (hFlush, isEOF, stdout)
import Text.Read (readMaybe)

-- =====================================================================
-- PARTE PURA: casos de teste da Etapa 2 como DADOS
-- =====================================================================

data Caso = Caso
  { casoId   :: String
  , casoDesc :: String
  , casoOk   :: Bool      -- resultado do teste, calculado por funcoes puras
  }

-- Cenario base: 5 livros e 2 usuarios, sem emprestimos. E um VALOR constante,
-- construido aplicando uma lista de funcoes ao estado vazio.
cenarioBase :: Biblioteca
cenarioBase = either (error . mensagem) id (aplicarTodas operacoes bibliotecaVazia)
  where
    operacoes =
      [ cadastrarLivro 1 "Dom Casmurro" 2
      , cadastrarLivro 2 "O Cortico" 3
      , cadastrarLivro 3 "Vidas Secas" 1
      , cadastrarLivro 4 "Iracema" 1
      , cadastrarLivro 5 "Capitaes da Areia" 4
      , cadastrarUsuario 10 "Ana"
      , cadastrarUsuario 20 "Bruno"
      ]

-- Estados derivados do cenario base. Nenhum "altera" cenarioBase: cada um e
-- um valor novo, e cenarioBase continua intacto para os demais testes.
aposDevolucao :: Either Erro Biblioteca
aposDevolucao = emprestar 10 1 cenarioBase >>= devolver 10 1

doisEmprestimos :: Either Erro Biblioteca
doisEmprestimos = aplicarTodas [emprestar 10 1, emprestar 10 2] cenarioBase

tresEmprestimos :: Either Erro Biblioteca
tresEmprestimos = aplicarTodas [emprestar 10 1, emprestar 10 2, emprestar 10 3] cenarioBase

casos :: [Caso]
casos =
  [ Caso "NORM-01" "Livro 1 cadastrado com 2 copias disponiveis"
      (consultarDisponibilidade 1 cenarioBase == Right 2)
  , Caso "NORM-02" "Usuario 10 ja cadastrado (cadastro original valido)"
      (cadastrarUsuario 10 "Ana Duplicada" cenarioBase == Left UsuarioJaCadastrado)
  , Caso "NORM-03" "Emprestimo do livro 1 ao usuario 10 e livro 1 passa a ter 1 copia"
      ((emprestar 10 1 cenarioBase >>= consultarDisponibilidade 1) == Right 1)
  , Caso "NORM-04" "Disponibilidade do livro 1 sem emprestimos (2 copias)"
      (consultarDisponibilidade 1 cenarioBase == Right 2)
  , Caso "NORM-05" "Usuario 10 possui apenas Dom Casmurro emprestado"
      ((emprestar 10 1 cenarioBase >>= consultarEmprestimos 10) == Right ["Dom Casmurro"])
  , Caso "NORM-06" "Devolucao registrada, livro 1 volta a 2 copias e usuario sem emprestimos"
      (  (aposDevolucao >>= consultarDisponibilidade 1) == Right 2
      && (aposDevolucao >>= consultarEmprestimos 10) == Right [] )
  , Caso "NORM-07" "Segundo titulo diferente emprestado (2 emprestimos ativos)"
      ((doisEmprestimos >>= consultarEmprestimos 10) == Right ["Dom Casmurro", "O Cortico"])
  , Caso "NORM-08" "Terceiro titulo emprestado (limite maximo valido)"
      ((tresEmprestimos >>= consultarEmprestimos 10)
         == Right ["Dom Casmurro", "O Cortico", "Vidas Secas"])
  , Caso "NORM-09" "Livros 4 (1 copia) e 5 (4 copias) cadastrados"
      (  consultarDisponibilidade 4 cenarioBase == Right 1
      && consultarDisponibilidade 5 cenarioBase == Right 4 )
  , Caso "NORM-10" "Usuario 20 sem emprestimos (lista vazia)"
      (consultarEmprestimos 20 cenarioBase == Right [])
  , Caso "LIM-01" "Quarto emprestimo recusado por limite atingido"
      ((tresEmprestimos >>= emprestar 10 4) == Left LimiteAtingido)
  , Caso "LIM-02" "Emprestimo recusado por livro indisponivel"
      ((emprestar 10 3 cenarioBase >>= emprestar 20 3) == Left LivroIndisponivel)
  , Caso "LIM-03" "Segunda copia do mesmo titulo recusada para o mesmo usuario"
      ((emprestar 10 1 cenarioBase >>= emprestar 10 1) == Left TituloJaEmprestado)
  , Caso "INV-01" "Emprestimo recusado: livro com codigo inexistente"
      (emprestar 10 999 cenarioBase == Left LivroNaoEncontrado)
  , Caso "INV-02" "Devolucao recusada: emprestimo inexistente para o par usuario/livro"
      (devolver 10 5 cenarioBase == Left EmprestimoNaoEncontrado)
  ]

formatar :: Caso -> String
formatar c = (if casoOk c then "[PASS] " else "[FAIL] ") ++ casoId c ++ " - " ++ casoDesc c

-- =====================================================================
-- PARTE IMPURA: tudo abaixo tem tipo IO (interage com o mundo externo)
-- =====================================================================

validar :: IO ()
validar = do
  putStrLn "=== Validacao da implementacao funcional (Etapa 6) ==="
  putStrLn "Casos de teste baseados em testes/casos.md (Etapa 2)\n"
  mapM_ (putStrLn . formatar) casos
  let total   = length casos
      passaram = length (filter casoOk casos)
  putStrLn ("\n=== Resultado final: " ++ show passaram ++ "/" ++ show total ++ " testes passaram ===")
  exitWith (if passaram == total then ExitSuccess else ExitFailure 1)

exibirMenu :: IO ()
exibirMenu = do
  putStrLn "\n===== Sistema de Emprestimo de Livros da Biblioteca ====="
  putStrLn "1. Cadastrar livro"
  putStrLn "2. Cadastrar usuario"
  putStrLn "3. Emprestar livro"
  putStrLn "4. Devolver livro"
  putStrLn "5. Consultar disponibilidade de um livro"
  putStrLn "6. Consultar livros emprestados por um usuario"
  putStrLn "0. Sair"
  putStr "Escolha uma opcao: "
  hFlush stdout

-- Leitura segura: no fim da entrada devolve texto vazio em vez de falhar.
lerLinha :: IO String
lerLinha = do
  fim <- isEOF
  if fim then return "" else getLine

pergunta :: String -> IO String
pergunta rotulo = putStr rotulo >> hFlush stdout >> lerLinha

perguntaInt :: String -> IO Int
perguntaInt rotulo = do
  texto <- pergunta rotulo
  return (maybe (-1) id (readMaybe texto))

-- Recebe o resultado de uma operacao PURA e o estado atual. Imprime o
-- desfecho e devolve o estado a ser usado dali em diante: o novo, se deu
-- certo; o ANTIGO, se deu erro (como nada foi alterado, nao ha o que desfazer).
aplicar :: Either Erro Biblioteca -> Biblioteca -> IO Biblioteca
aplicar resultado atual = case resultado of
  Left erro  -> putStrLn (">> " ++ mensagem erro) >> return atual
  Right novo -> putStrLn ">> Operacao realizada com sucesso." >> return novo

opCadastrarLivro :: Biblioteca -> IO Biblioteca
opCadastrarLivro b = do
  cod <- perguntaInt "Codigo do livro: "
  tit <- pergunta "Titulo do livro: "
  qtd <- perguntaInt "Numero de copias: "
  aplicar (cadastrarLivro cod tit qtd b) b

opCadastrarUsuario :: Biblioteca -> IO Biblioteca
opCadastrarUsuario b = do
  cod <- perguntaInt "Codigo do usuario: "
  nm  <- pergunta "Nome do usuario: "
  aplicar (cadastrarUsuario cod nm b) b

opEmprestar :: Biblioteca -> IO Biblioteca
opEmprestar b = do
  cu <- perguntaInt "Codigo do usuario: "
  cl <- perguntaInt "Codigo do livro: "
  aplicar (emprestar cu cl b) b

opDevolver :: Biblioteca -> IO Biblioteca
opDevolver b = do
  cu <- perguntaInt "Codigo do usuario: "
  cl <- perguntaInt "Codigo do livro: "
  aplicar (devolver cu cl b) b

opDisponibilidade :: Biblioteca -> IO Biblioteca
opDisponibilidade b = do
  cl <- perguntaInt "Codigo do livro: "
  case consultarDisponibilidade cl b of
    Left erro -> putStrLn (">> " ++ mensagem erro)
    Right n   -> putStrLn (">> O livro " ++ show cl ++ " possui " ++ show n ++ " copia(s) disponivel(is).")
  return b

opEmprestimosUsuario :: Biblioteca -> IO Biblioteca
opEmprestimosUsuario b = do
  cu <- perguntaInt "Codigo do usuario: "
  case consultarEmprestimos cu b of
    Left erro -> putStrLn (">> " ++ mensagem erro)
    Right []  -> putStrLn (">> O usuario " ++ show cu ++ " nao possui livros emprestados no momento.")
    Right ts  -> do
      putStrLn (">> Livros emprestados ao usuario " ++ show cu ++ ":")
      mapM_ (\t -> putStrLn ("   - " ++ t)) ts
  return b

-- Laco principal por RECURSAO: em vez de uma variavel de estado que e
-- reatribuida a cada volta (como o while do C e do Java), o estado e
-- PARAMETRO da funcao e a proxima volta recebe o estado novo.
laco :: Biblioteca -> IO ()
laco b = do
  exibirMenu
  fim <- isEOF
  if fim
    then putStrLn ""
    else do
      linha <- getLine
      case (readMaybe linha :: Maybe Int) of
        Just 0 -> putStrLn "Encerrando o sistema. Ate mais!"
        Just 1 -> opCadastrarLivro b >>= laco
        Just 2 -> opCadastrarUsuario b >>= laco
        Just 3 -> opEmprestar b >>= laco
        Just 4 -> opDevolver b >>= laco
        Just 5 -> opDisponibilidade b >>= laco
        Just 6 -> opEmprestimosUsuario b >>= laco
        _      -> putStrLn ">> Opcao invalida. Tente novamente." >> laco b

main :: IO ()
main = do
  args <- getArgs
  case args of
    ["--validar"] -> validar
    _ -> do
      putStrLn "Sistema de Emprestimo de Livros - Biblioteca (Funcional)"
      putStrLn "(estado mantido apenas em memoria durante a execucao)"
      laco bibliotecaVazia
