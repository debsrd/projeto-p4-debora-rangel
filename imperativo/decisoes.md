# ETAPA 03 — Decisões de Implementação (Paradigma Imperativo)

**Tag:** `[P4-ETAPA-03]`
**Linguagem:** C
**Arquivos:** `imperativo/biblioteca.h`, `imperativo/biblioteca.c`, `imperativo/main.c`

## 1. Quais estados são mantidos

O estado central do sistema é concentrado na struct `Biblioteca`, que agrupa três coleções e seus respectivos contadores:

- **Acervo de livros** (`livros[]`, `num_livros`): cada livro mantém `codigo`, `titulo` e `copias_disponiveis`. O campo `copias_disponiveis` é o estado mais volátil do sistema — muda a cada empréstimo e devolução.
- **Usuários cadastrados** (`usuarios[]`, `num_usuarios`): cada usuário mantém `codigo` e `nome`. É um estado praticamente imutável após o cadastro.
- **Empréstimos** (`emprestimos[]`, `num_emprestimos`): cada registro mantém `codigo_usuario`, `codigo_livro` e um flag `ativo`. Em vez de remover um empréstimo do vetor quando o livro é devolvido, o sistema apenas marca `ativo = 0`, preservando o histórico completo de operações — essa foi uma decisão deliberada para manter rastreabilidade sem precisar de estruturas de dados mais complexas (como listas encadeadas com remoção).

## 2. Quais operações modificam estado

| Operação | Estado modificado |
|---|---|
| `cadastrar_livro` | Adiciona um item a `livros[]`, incrementa `num_livros` |
| `cadastrar_usuario` | Adiciona um item a `usuarios[]`, incrementa `num_usuarios` |
| `emprestar_livro` | Decrementa `copias_disponiveis` do livro; adiciona um item a `emprestimos[]`, incrementa `num_emprestimos` |
| `devolver_livro` | Incrementa `copias_disponiveis` do livro; altera `ativo` de 1 para 0 no registro de empréstimo correspondente |

As operações de consulta (`consultar_disponibilidade`, `consultar_emprestimos_usuario`) são as únicas que **não** alteram nenhum estado — apenas leem a `Biblioteca` e retornam informações, o que foi uma escolha consciente para deixar claro, pelo próprio nome e assinatura da função, quais operações têm efeito colateral e quais não têm.

## 3. Onde aparecem efeitos colaterais

Os efeitos colaterais aparecem sempre que uma função recebe `Biblioteca *b` (ponteiro) e escreve diretamente em algum campo apontado por `b`, sem devolver um novo valor. Exemplos concretos:

- Em `emprestar_livro`, a linha `b->livros[idx_livro].copias_disponiveis = b->livros[idx_livro].copias_disponiveis - 1;` altera o estado do acervo como consequência colateral de uma operação que, à primeira vista, "só registra um empréstimo".
- Em `cadastrar_livro` e `cadastrar_usuario`, os contadores (`num_livros`, `num_usuarios`) são incrementados como efeito colateral do cadastro, e são esses contadores que definem até onde os vetores são considerados válidos nas buscas subsequentes.

Essa é uma diferença central em relação ao paradigma funcional: aqui, a mesma chamada de função pode retornar valores diferentes em momentos diferentes, dependendo do estado atual da `Biblioteca`, porque o estado é compartilhado e mutável.

## 4. Quais estruturas de controle foram escolhidas

- **Laços `for`**: usados em todas as buscas sequenciais (`buscar_indice_livro`, `buscar_indice_usuario`, `contar_emprestimos_ativos`, etc.), já que o problema não exige nenhuma estrutura de dados mais sofisticada (como tabelas hash) dado o tamanho limitado do acervo.
- **Estruturas `if` em cadeia com retorno antecipado**: usadas em todas as operações que têm pré-condições (ex.: `emprestar_livro` valida, em sequência, se o livro existe, se o usuário existe, se há cópia disponível, se o limite foi atingido e se o usuário já possui o título — retornando o código de erro correspondente assim que a primeira violação é encontrada). Essa abordagem deixa o contrato de regras da Etapa 1 diretamente visível no código, na mesma ordem em que foram descritas na especificação.
- **`switch`**: usado em `mensagem_resultado` (para mapear cada código de erro a uma mensagem) e no laço principal de `main.c` (para direcionar a opção escolhida pelo usuário ao subprograma correspondente).
- **Laço `while`**: usado em `main.c` para manter o menu interativo em execução até que o usuário escolha sair (variável de controle `continuar`).

## 5. Como os subprogramas foram organizados

O código foi dividido em três arquivos com responsabilidades bem distintas:

- **`biblioteca.h`**: contém apenas as definições de estado (structs) e as assinaturas das funções — nenhuma lógica.
- **`biblioteca.c`**: contém toda a lógica de negócio (as seis operações da Etapa 1, mais as funções auxiliares de busca e contagem). Esse arquivo não sabe nada sobre menus, entrada de teclado ou impressão — ele só manipula o estado da `Biblioteca`.
- **`main.c`**: é a camada de interação com o usuário (menu de console). Cada opção do menu tem seu próprio subprograma (`opcao_cadastrar_livro`, `opcao_emprestar_livro`, etc.), que só se preocupa em ler dados do teclado, chamar a função correspondente de `biblioteca.c` e exibir o resultado.

Essa separação em subprogramas pequenos e de responsabilidade única (uma função por regra, uma função por operação de menu) foi a principal técnica de decomposição usada, em vez de qualquer forma de encapsulamento orientado a objetos.

## 6. Por que a solução pode ser considerada predominantemente imperativa

- O estado do sistema (`Biblioteca` e seus vetores) é armazenado explicitamente em memória e alterado por **atribuições diretas** (`b->livros[i].copias_disponiveis = ...`), não por criação de novos valores imutáveis.
- O **fluxo de controle** é determinado por decisões explícitas (`if`, `switch`, `for`, `while`) que o programador escreve passo a passo — não há recursão, funções de ordem superior, nem inferência declarativa de comportamento.
- As **structs usadas (`Livro`, `Usuario`, `Emprestimo`, `Biblioteca`) não possuem métodos**: são apenas agrupamentos de dados manipulados por funções externas que recebem ponteiros. Isso evita qualquer aparência de encapsulamento orientado a objetos, que esconderia a manipulação direta do estado.
- A comunicação entre os subprogramas se dá por **parâmetros e valores de retorno simples** (ponteiros para o estado, códigos de resultado inteiros, parâmetros de saída como `titulos_saida` e `*quantidade`), técnica típica de C imperativo — sem uso de exceções, callbacks ou qualquer mecanismo de mais alto nível.

Por esses motivos, a solução expressa diretamente o modelo de computação imperativo: um programa é uma sequência de comandos que leem e escrevem em um estado compartilhado e mutável, controlada por estruturas de controle explícitas.

## 7. Validação dos Casos da Etapa 2

Os casos de teste definidos na Etapa 2 serviram como referência analítica para validar o comportamento computacional do sistema de empréstimo de livros implementado no paradigma imperativo.

### 7.1 Casos Normais

* **NORM-01 (Cadastro de livro):** Atendido. A rotina `cadastrar_livro` recorre a `buscar_indice_livro` para atestar a inexistência prévia do identificador; após a validação da capacidade em `MAX_LIVROS`, o registo é copiado para o vetor `livros[]` e `num_livros` é incrementado[cite: 1, 2].
* **NORM-02 (Cadastro de utilizador):** Atendido. A função `cadastrar_usuario` verifica a unicidade do código via `buscar_indice_usuario` e insere o novo registo na posição `num_usuarios`, incrementando o respetivo contador[cite: 1, 2].
* **NORM-03 (Empréstimo padrão):** Atendido. O procedimento `emprestar_livro` valida a presença do exemplar e do leitor, confirma que `copias_disponiveis > 0`, decrementa o stock no vetor de livros e acrescenta uma entrada com `ativo = 1` em `emprestimos[]`[cite: 1, 2].
* **NORM-04 (Consulta de disponibilidade):** Atendido. A função `consultar_disponibilidade` pesquisa a posição do volume no vetor e retorna diretamente o valor do campo `copias_disponiveis` sem produzir efeitos colaterais[cite: 1, 2].
* **NORM-05 (Consulta de empréstimos ativos):** Atendido. O procedimento `consultar_emprestimos_usuario` itera sobre `emprestimos[]`, filtra as ocorrências associadas ao utilizador com `ativo == 1` e preenche o vetor de saída com os respetivos títulos[cite: 1, 2].
* **NORM-06 (Devolução de livro):** Atendido. A rotina `devolver_livro` localiza o par correspondente em aberto no vetor de empréstimos, transita a flag de estado para `ativo = 0` e incrementa `copias_disponiveis` no acervo[cite: 1, 2].
* **NORM-07 (Segundo empréstimo distinto):** Atendido. A função `contar_emprestimos_ativos` retorna `1`, permitindo a concessão do novo volume por se encontrar abaixo de `LIMITE_EMPRESTIMOS_POR_USUARIO`[cite: 1, 2].
* **NORM-08 (Terceiro empréstimo no limite máximo):** Atendido. Ao computar `2` empréstimos prévios, o fluxo aceita a operação por não exceder estritamente o limite estabelecido de 3 títulos simultâneos[cite: 1, 2].
* **NORM-09 (Múltiplos cadastros no acervo):** Atendido. Chamadas sequenciais a `cadastrar_livro` populam posições consecutivas em `livros[]`, mantendo a integridade individual de códigos e quantidades de cópias[cite: 1].
* **NORM-10 (Consulta de utilizador sem empréstimos):** Atendido. O laço de varredura não identifica correspondências ativas, configurando o parâmetro de saída `*quantidade` com o valor zero[cite: 1, 2].

### 7.2 Casos-limite

* **LIM-01 (Limite de empréstimos excedido):** Atendido. A função `contar_emprestimos_ativos` contabiliza 3 contratos ativos; a guarda condicional na rotina `emprestar_livro` interrompe o processamento e devolve `ERRO_LIMITE_EMPRESTIMOS_ATINGIDO`[cite: 1, 2].
* **LIM-02 (Livro sem cópias disponíveis):** Atendido. A verificação `copias_disponiveis <= 0` é avaliada antes de qualquer mutação de estado, retornando imediatamente `ERRO_LIVRO_INDISPONIVEL`[cite: 1, 2].
* **LIM-03 (Duplicidade do mesmo título para o mesmo utilizador):** Atendido. A função auxiliar `usuario_possui_livro_ativo` analisa o histórico recente e aciona a interrupção da rotina com `ERRO_USUARIO_JA_POSSUI_TITULO`[cite: 1, 2].

### 7.3 Casos de Entrada Inválida

* **INV-01 (Livro inexistente no acervo):** Atendido. A função `buscar_indice_livro` devolve `-1` ao término do ciclo de pesquisa sequencial, culminando no retorno imediato de `ERRO_LIVRO_NAO_ENCONTRADO`[cite: 1, 2].
* **INV-02 (Devolução sem empréstimo associado):** Atendido. A busca por um contrato em aberto contendo a chave combinada (utilizador, livro) falha em localizar um índice válido, disparando o retorno de `ERRO_EMPRESTIMO_NAO_ENCONTRADO` sem alterações nas cópias[cite: 1, 2].
