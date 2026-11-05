# ETAPA 06 — Implementação Funcional (Haskell)

**Tag:** `[P4-ETAPA-06]`
**Linguagem:** Haskell
**Arquivos:** `funcional/Biblioteca.hs` (núcleo puro), `funcional/Main.hs` (entrada/saída e casos de teste)

**Como executar** (a partir da pasta `funcional/`):

- `runghc Main.hs` — sistema interativo (menu);
- `runghc Main.hs --validar` — roda os 15 casos de teste da Etapa 2.

## 1. Como a solução está organizada

O núcleo da solução foi separado das operações de entrada e saída, como o enunciado pede:

- **`Biblioteca.hs`** não importa nada de entrada/saída e nenhuma assinatura contém `IO`. Todas as regras do problema estão aqui.
- **`Main.hs`** é a "casca" que conversa com o mundo externo (teclado e tela). Ele lê dados, chama uma função pura do núcleo e imprime o resultado. Também guarda os casos de teste, que são **dados** calculados por funções puras.

A ideia central é que **nenhuma operação modifica a biblioteca**. Cada operação recebe a biblioteca atual e **devolve uma nova** (ou um erro):

```haskell
emprestar :: CodigoUsuario -> CodigoLivro -> Biblioteca -> Either Erro Biblioteca
```

## 2. Identificação dos elementos pedidos

### Funções puras

Todas as funções de `Biblioteca.hs`, mais as partes de `Main.hs` que não têm tipo `IO`:

| Função | O que faz |
|---|---|
| `cadastrarLivro`, `cadastrarUsuario` | Recebem a biblioteca e devolvem uma nova com o item inserido |
| `emprestar`, `emprestarCom`, `devolver` | Transformam a biblioteca aplicando as regras do problema |
| `consultarDisponibilidade`, `consultarEmprestimos` | Só leem; devolvem um valor |
| `regraDisponivel`, `regraLimite`, `regraTituloNaoDuplicado` | Cada regra do problema, como função |
| `primeiraViolacao`, `aplicarTodas` | Combinam listas de funções |
| `emprestimosDe`, `ehEmprestimo`, `procurarLivro`, `procurarUsuario`, `mensagem` | Auxiliares |
| `cenarioBase`, `casos`, `formatar` (em `Main.hs`) | Dados e texto dos testes |

Todas têm **transparência referencial**: `emprestar 10 1 cenarioBase` resulta sempre no mesmo valor, em qualquer momento. Isso é diferente de `emprestar_livro(&b, 10, 1)` em C, que na segunda chamada dá resultado diferente porque `b` mudou.

### Funções impuras

Todas e somente as de tipo `IO`, em `Main.hs`: `main`, `laco`, `validar`, `exibirMenu`, `lerLinha`, `pergunta`, `perguntaInt`, `aplicar` e as `op...` de cada opção do menu. Elas são impuras porque leem do teclado, escrevem na tela ou encerram o programa.

Observação: `aplicar` recebe um resultado **já calculado** por uma função pura. A parte impura dela é apenas imprimir e escolher qual estado seguir usando.

### Pontos de interação com o mundo externo

São exatamente quatro, todos em `Main.hs`: **ler** uma linha do teclado (`lerLinha`), **escrever** na tela (`putStrLn`/`putStr`), **detectar o fim da entrada** (`isEOF`) e **encerrar o processo** com código de saída (`exitWith`). Fora disso, o programa é cálculo puro.

### Dados imutáveis

`Livro`, `Usuario`, `Emprestimo` e `Biblioteca` são `data` do Haskell: não existe atribuição a um campo depois de criado. A sintaxe `b { livros = ... }` **não altera** `b`; cria um valor novo que reaproveita o que não mudou. Os mapas (`Data.Map`) também são estruturas persistentes: inserir devolve um novo mapa.

Consequência prática: quando uma operação falha, o estado anterior continua exatamente como estava. Em `Main.hs`, `aplicar` simplesmente segue usando o estado antigo, sem precisar "desfazer" nada.

### Transformações de dados

Cada operação do sistema é uma transformação `Biblioteca -> Either Erro Biblioteca`. O empréstimo, por exemplo, transforma uma biblioteca em outra em que (1) o livro tem uma cópia a menos e (2) a lista de empréstimos tem um par `(usuário, livro)` a mais. A devolução faz o inverso: devolve a cópia e filtra o par da lista.

### Funções de primeira classe e de alta ordem

- **Primeira classe:** as regras são valores comuns. `regrasPadrao` é uma **lista de funções**; podem ser passadas, guardadas e combinadas.
- **Alta ordem:** `primeiraViolacao` recebe uma lista de regras; `emprestarCom` recebe as regras como parâmetro; `regraLimite` recebe um número e **devolve uma função** (uma regra); `aplicarTodas` usa `foldM` para aplicar uma lista de operações ao estado; e as funções padrão `map`, `filter`, `any`, `mapMaybe`, `mapM_` recebem funções como argumento.
- **Aplicação parcial (currying):** `emprestar = emprestarCom regrasPadrao` e expressões como `cadastrarLivro 1 "Dom Casmurro" 2`, que já é uma função `Biblioteca -> Either Erro Biblioteca` esperando só o estado.

### Composição funcional

- `emprestimosDe cu = filter ((== cu) . emUsuario) . emprestimos`
- `filter (not . ehEmprestimo cu cl) (emprestimos b)`
- `mapM_ (putStrLn . formatar) casos`
- `either (error . mensagem) id ...`
- Encadeamento de operações com `>>=`: `emprestar 10 1 cenarioBase >>= devolver 10 1` (cada passo recebe o resultado do anterior e o primeiro erro interrompe tudo).

### Recursão

O laço principal do menu (`laco`) é **recursivo**: o estado é um **parâmetro** da função e cada volta chama `laco` com o estado novo (`opEmprestar b >>= laco`). Não há variável reatribuída. Nas partes puras, a repetição fica a cargo de funções de alta ordem (`map`, `filter`, `foldM`), que dispensam recursão explícita; ela só foi usada onde é a forma natural de expressar a repetição (o menu).

## 3. Reflexão: de "que estado devo modificar?" para "que transformação aplicar aos dados?"

**No imperativo (C)**, para emprestar um livro eu pensava: "quais campos devo alterar?" A resposta era uma lista de comandos: decrementar `copias_disponiveis`, escrever um registro novo em `emprestimos[]`, incrementar `num_emprestimos`. O raciocínio era sobre **o que acontece na memória, e em que ordem**. A correção do programa dependia de eu lembrar de manter esses campos coerentes entre si.

**No orientado a objetos (Java)**, a pergunta passou a ser "quem é responsável por alterar isso?" e a resposta foi distribuir a alteração entre `Livro`, `Usuario` e `Emprestimo`, cada um protegendo seu estado. O estado continuava mudando, mas em pontos controlados.

**No funcional (Haskell)**, a pergunta deixou de falar em alterar. Passou a ser: "dada uma biblioteca, qual biblioteca deve resultar?" Emprestar é descrever a relação entre o valor de entrada e o valor de saída: *a biblioteca de saída é a de entrada, com uma cópia a menos neste livro e mais um par na lista de empréstimos*. Não existe "antes" e "depois" dentro da função; existe um valor que entra e outro que sai.

Mudanças concretas que isso trouxe para o código:

1. **Sumiram variáveis de controle.** Não há contadores (`num_livros`...), flag `ativo` nem `while` com variável de estado. A devolução não marca o empréstimo como inativo: ela produz uma lista **sem** aquele par.
2. **Regras viraram dados que se combinam.** A cadeia de `if` do C virou uma lista de funções. Para mudar a política basta mudar a lista, sem editar `emprestarCom`.
3. **Erros viraram valores.** `Either Erro Biblioteca` torna o erro parte do tipo: quem chama é obrigado a tratar os dois casos. O encadeamento com `do`/`>>=` interrompe no primeiro `Left`, sem `if` repetido depois de cada passo.
4. **Testar ficou mais simples.** Como as funções são puras, cada caso de teste é só uma comparação de valores (`emprestar 10 1 cenarioBase == ...`). Não é preciso reconstruir estado nem capturar exceções; o `cenarioBase` é um valor constante que nunca é alterado pelos testes.
5. **O estado "mora" só no laço.** O único lugar em que "o estado atual" aparece é o parâmetro de `laco`, que o repassa adiante. Todo o restante do programa é cálculo sem memória.

## 4. Comparação resumida com as etapas anteriores

| Aspecto | Imperativo (C) | POO (Java) | Funcional (Haskell) |
|---|---|---|---|
| Pergunta central | Que campos altero? | Quem é responsável por alterar? | Que transformação aplico aos dados? |
| Estado | `struct` alterada por ponteiro | Distribuído em objetos | Valor imutável passado adiante |
| Erros | `enum` de códigos | Hierarquia de exceções | `Either Erro` (valor) |
| Regras | Cadeia de `if` | Objetos `RegraEmprestimo` | Lista de funções `Regra` |
| Repetição | `for`/`while` | `for`/`while` | `map`/`filter`/`foldM` e recursão |
| Efeitos colaterais | Livres | Confinados nos métodos | Isolados em `IO` (`Main.hs`) |

## 5. Custos e limitações observados

- **Perda de histórico:** em C e Java, o empréstimo devolvido continua registrado com `ativo = 0`/`false`. Aqui, ao devolver, o par é removido e o histórico não é mantido. As regras e os 15 casos da Etapa 2 não dependem do histórico, mas se ele fosse necessário bastaria adicionar um campo `ativo` ou uma segunda lista.
- **Curva de aprendizado:** `Either`, `>>=`, `foldM` e aplicação parcial exigem familiaridade com conceitos que C e Java não pedem. Em troca, o código é bem mais curto.
- **Eficiência:** `emprestimos` é uma lista, então as consultas percorrem a lista inteira (mesma complexidade das buscas sequenciais do C). Para este problema o tamanho é pequeno, e a estrutura seria trocada por um `Map` se o volume crescesse.
- **A casca impura continua existindo:** não se elimina o efeito colateral, ele é **isolado**. O sistema precisa ler e escrever; a diferença é que isso fica restrito a `Main.hs`.
