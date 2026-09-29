# ETAPA 05 — Comparação entre Imperativo e Orientado a Objetos

**Tag:** `[P4-ETAPA-05]`
**Base da análise:** `imperativo/biblioteca.h`, `imperativo/biblioteca.c`, `imperativo/main.c`, `imperativo/validacao.c` (C) comparados a `poo/Main.java`, `poo/Validacao.java` (Java), ambos validados pelos mesmos 15 casos de `testes/casos.md`.

## Parte 1 — Análise comparativa por aspecto

### Representação do estado

Na implementação imperativa, todo o estado do sistema está concentrado em uma única `struct Biblioteca`, contendo três vetores de tamanho fixo (`livros[MAX_LIVROS]`, `usuarios[MAX_USUARIOS]`, `emprestimos[MAX_EMPRESTIMOS]`) e seus respectivos contadores. Qualquer função com um ponteiro `Biblioteca *b` enxerga o sistema inteiro de uma vez.

Na implementação orientada a objetos, o estado está **distribuído**: `Livro` guarda apenas suas próprias cópias disponíveis, `Usuario` guarda apenas sua própria lista de empréstimos, e `Biblioteca` guarda apenas dois `Map<Integer, ...>` para localizar livros e usuários por código. Não existe mais "o estado do sistema" como um bloco único — existe uma rede de estados menores, cada um pertencente a um objeto.

### Mutabilidade

Nas duas implementações o estado é **mutável** — nenhuma delas é funcional/imutável. A diferença não está em *se* algo muda, mas em *quem pode* mudá-lo:

- Em C, qualquer função que receba `Biblioteca *b` pode escrever em qualquer campo de qualquer struct dentro dela (`b->livros[i].copias_disponiveis = -5;` compilaria sem erro nenhum).
- Em Java, `Livro.copiasDisponiveis` é `private` e só é alterado por `retirarCopia()`/`devolverCopia()`, que impedem que o valor fique negativo. A mutabilidade continua existindo, mas fica **confinada** a poucos pontos protegidos.

### Fluxo de controle

Na implementação C, o fluxo é **linear e explícito**: `emprestar_livro` é uma sequência de `if`s com retorno antecipado, na mesma ordem das regras da Etapa 1, seguida das atribuições que alteram o estado. Basta ler de cima para baixo para saber o que acontece.

Na implementação Java, o fluxo é **delegado**: `Biblioteca.emprestar()` não valida nada sozinha — percorre uma `List<RegraEmprestimo>` chamando `verificar()` polimorficamente, e depois chama `usuario.pegarEmprestado(livro)`, que cria um `Emprestimo`, que por sua vez chama `livro.retirarCopia()`. Entender o fluxo completo exige acompanhar a execução "pulando" entre objetos, não apenas lendo uma função.

### Decomposição do problema

Em C, a decomposição é **por tarefa**: existem funções como `buscar_indice_livro`, `contar_emprestimos_ativos`, cada uma resolvendo um passo específico do algoritmo, chamadas por quem precisa delas.

Em Java, a decomposição é **por responsabilidade/entidade**: não existe uma função solta "contar empréstimos ativos" — existe `usuario.quantidadeEmprestimosAtivos()`, porque contar é uma responsabilidade que pertence ao próprio usuário.

### Reutilização

Em C, o reaproveitamento acontece via funções auxiliares reutilizadas dentro de `biblioteca.c` (ex.: `buscar_indice_livro` é usada por `emprestar_livro`, `devolver_livro` e `consultar_disponibilidade`), mas essas funções dependem da forma exata da `struct Biblioteca`.

Em Java, o reaproveitamento é maior: as regras de negócio (`RegraLivroDisponivel`, `RegraLimiteEmprestimos`, `RegraTituloNaoDuplicado`) são objetos independentes que podem ser combinados em qualquer ordem ou reaproveitados em uma `Biblioteca` com política diferente (`new Biblioteca(minhasRegras)`), sem duplicar código.

### Manutenção

Alterar uma regra de negócio em C exige editar diretamente a função `emprestar_livro`, no meio de uma cadeia de `if`s já existente — o risco de introduzir um efeito colateral em uma regra vizinha é maior.

Em Java, alterar uma regra específica significa editar **apenas a classe daquela regra** (ex.: mudar `RegraLimiteEmprestimos` não tem como afetar `RegraTituloNaoDuplicado`), o que reduz o risco de regressão ao dar manutenção.

### Facilidade de extensão

Em C, adicionar uma nova regra de empréstimo exige: acrescentar um novo valor ao `enum CodigoResultado`, um novo `case` em `mensagem_resultado`, e um novo `if` dentro de `emprestar_livro` — três pontos diferentes do código existente precisam ser tocados.

Em Java, a mesma extensão exige apenas criar uma nova classe que implemente `RegraEmprestimo` e adicioná-la à lista de regras da `Biblioteca` — nenhuma classe já existente precisa ser modificada. Isso é o princípio aberto/fechado (open/closed) na prática, e foi a vantagem mais concreta observada no projeto.

### Tratamento de erros

Em C, os erros são representados por um `enum CodigoResultado` (10 valores possíveis) e uma função `mensagem_resultado` com `switch` para traduzir cada código em texto. Quem chama a função precisa lembrar de checar o valor de retorno — nada obriga a isso.

Em Java, os erros são uma **hierarquia de exceções** (`BibliotecaException` → `EmprestimoRecusadoException` → `LivroIndisponivelException`, etc.). O compilador **obriga** o tratamento (exceções checadas), e é possível capturar de forma genérica (`catch (BibliotecaException e)`, usado em `Main.java`) ou específica (usado em `Validacao.java`, que verifica *qual* subclasse foi lançada).

### Efeitos colaterais

Em C, efeitos colaterais são livres: qualquer função pode alterar qualquer campo de `Biblioteca`, sem nenhuma barreira da linguagem.

Em Java, os efeitos colaterais continuam existindo (nenhum dos dois paradigmas é livre de estado mutável), mas ficam **confinados**: só `Livro.retirarCopia()`/`devolverCopia()` alteram `copiasDisponiveis`, e esses métodos protegem o invariante "nunca negativo".

### Facilidade para testar

As duas implementações foram testadas com os **mesmos 15 casos de teste** da Etapa 2 (`validacao.c` e `Validacao.java`), com 100% de aprovação em ambas. Isso, por si só, mostra que os testes definidos na Etapa 2 são de fato independentes de paradigma, como o enunciado da Etapa 2 previa.

A diferença observada foi na forma de **verificar** um erro esperado: em C, basta comparar o `CodigoResultado` retornado com uma constante (`resultado == ERRO_LIVRO_INDISPONIVEL`). Em Java, foi necessário criar uma função auxiliar `lanca(classeEsperada, acao)` que executa a operação dentro de um `try/catch` e verifica o **tipo** da exceção lançada — um pouco mais verboso de escrever, mas equivalente em poder de verificação.

### Organização do código

Em C, a organização é **por camada**, em arquivos separados: `biblioteca.h` (declarações), `biblioteca.c` (lógica), `main.c` (interação com o usuário), `validacao.c` (testes) — quatro arquivos com papéis bem distintos.

Em Java, a organização é **por classe**, todas agrupadas dentro de `Main.java` (17 classes/interfaces de domínio) mais `Validacao.java` separado para os testes. A separação deixou de ser "por camada em arquivo" e passou a ser "por conceito em classe", ainda que fisicamente concentradas em poucos arquivos, por decisão de simplificar a entrega do repositório.

### Complexidade

Para o tamanho deste problema específico (biblioteca simples, poucas regras), a implementação em C tem **menos elementos** para acompanhar: uma struct, um enum e um punhado de funções. A implementação em Java introduziu mais conceitos (17 classes/interfaces) para resolver o mesmo problema, o que representa uma complexidade **estrutural maior**, ainda que cada peça individual seja mais simples de entender isoladamente.

Em outras palavras: C tem menos peças, mas peças mais "carregadas" de responsabilidade cada uma; Java tem mais peças, cada uma mais enxuta e focada.

## Parte 2 — Perguntas obrigatórias

### 1. Qual problema ficou mais fácil de expressar de forma imperativa?

As regras de validação em sequência — por exemplo, a cadeia de checagens de `emprestar_livro` (livro existe → usuário existe → tem cópia → não passou do limite → não duplica título) — foram mais diretas de expressar em C. Uma sequência de `if`s com retorno antecipado é exatamente como a Etapa 1 descreveu as regras, uma depois da outra; não foi preciso decidir "de quem é a responsabilidade" de cada checagem, bastou escrever a ordem certa.

### 2. Qual problema ficou mais fácil de expressar utilizando orientação a objetos?

A relação entre um empréstimo e o livro/usuário envolvidos. Em Java, `Emprestimo` simplesmente guarda uma referência direta ao `Livro` (`private final Livro livro`), e perguntar "esse empréstimo é desse livro?" é comparar referências. Em C, essa mesma pergunta exigia comparar `codigo_livro` (um inteiro) e, sempre que era preciso usar o livro de fato, refazer uma busca sequencial (`buscar_indice_livro`) no vetor.

### 3. Onde a orientação a objetos realmente trouxe vantagem?

Na extensibilidade das regras de negócio. Transformar cada regra em uma implementação de `RegraEmprestimo` tornou possível adicionar, remover ou reordenar regras sem tocar em `Biblioteca.emprestar()` — o método já testado não precisa ser reaberto. Em C, qualquer nova regra exige editar a própria função `emprestar_livro`, arriscando quebrar uma regra já validada.

### 4. Em quais situações a utilização de objetos acrescentou complexidade desnecessária?

No cadastro simples de livros e usuários. Em C, `cadastrar_livro(b, codigo, titulo, copias)` é uma função de poucas linhas que escreve direto no vetor. Em Java, a mesma operação passa por um `Map`, um construtor que valida (`if (copias < 0) throw ...`), e ainda depende de uma exceção (`CadastroDuplicadoException`) só para sinalizar "código repetido" — para uma operação tão simples, o mecanismo de exceções chega a ser mais pesado do que o problema exige.

### 5. Que partes do problema praticamente não mudaram entre as duas implementações?

As **regras de negócio em si** não mudaram — o "o quê" validar é idêntico nas duas versões (mesmo limite de 3 livros, mesma proibição de título duplicado, mesma exigência de cópia disponível). Os 15 casos de teste da Etapa 2 passaram sem nenhuma alteração de conteúdo nas duas implementações, o que confirma que o **contrato de comportamento** definido na Etapa 1/2 é, de fato, independente de paradigma.

### 6. Que partes precisaram ser completamente remodeladas?

A forma de relacionar empréstimo, livro e usuário. Em C, o `Emprestimo` era um registro "solto", ligado aos outros só por números (`codigo_usuario`, `codigo_livro`), e o histórico de quem tinha o quê era reconstruído a cada consulta, varrendo o vetor de empréstimos. Em Java, isso virou uma composição: cada `Usuario` já **contém** seus próprios `Emprestimo`s desde o início, e cada `Emprestimo` já aponta diretamente para seu `Livro`. Não foi uma tradução mecânica de sintaxe — foi uma mudança real de onde a informação "mora" e de quem é responsável por ela.

## Conclusão

A comparação confirma o que o documento geral do projeto antecipava: o **problema** não muda entre paradigmas, mas a **forma de modelá-lo** muda substancialmente. O paradigma imperativo favoreceu a expressão direta de regras sequenciais; o orientado a objetos favoreceu a expressão de relações entre entidades e a extensibilidade do sistema — ao custo de mais estrutura para resolver o mesmo problema.
