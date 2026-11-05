# ETAPA 04 — Reflexão: do paradigma imperativo ao orientado a objetos

**Tag:** `[P4-ETAPA-04]`
**Linguagem:** Java
**Pergunta:** Como meu modelo mudou ao passar do paradigma imperativo para o orientado a objetos?

## Visão geral da nova modelagem

No modelo imperativo (C), o sistema era **um grande estado** (`struct Biblioteca` com três vetores) manipulado por **funções livres** que recebiam um ponteiro para esse estado. No modelo orientado a objetos (Java), o sistema passou a ser **um conjunto de objetos que colaboram**, cada um dono do seu pedaço de estado e das regras que o protegem.

| Classe / tipo | Responsabilidade |
|---|---|
| `Livro` | Guardar título e cópias; garantir que as cópias nunca fiquem negativas |
| `Usuario` | Guardar seus empréstimos; responder quantos tem ativos e se já possui um livro |
| `Emprestimo` | Representar um empréstimo com ciclo de vida próprio (nasce ativo, sabe se encerrar) |
| `RegraEmprestimo` (interface) | Abstrair "uma condição que um empréstimo precisa cumprir" |
| `RegraLivroDisponivel`, `RegraLimiteEmprestimos`, `RegraTituloNaoDuplicado` | Uma regra da Etapa 1 cada |
| `Biblioteca` | Coordenar: localizar objetos, aplicar as regras, delegar o trabalho |
| `BibliotecaException` e subclasses | Representar os erros do domínio |
| `Main` | Interface de console |

A mudança não foi apenas "trocar `struct` por `class`". Três decisões mudaram a forma de pensar o problema: **(1)** o empréstimo virou uma entidade com comportamento, **(2)** as regras viraram objetos intercambiáveis, **(3)** os códigos de erro viraram uma hierarquia de exceções.

## 1. Representação do estado

**Imperativo:** todo o estado ficava em uma única `struct Biblioteca` com três vetores e três contadores (`num_livros`, `num_usuarios`, `num_emprestimos`). O empréstimo era um registro com um flag `ativo` manipulado por fora, e os contadores precisavam ser mantidos coerentes à mão.

**POO:** o estado está distribuído entre os objetos que o "possuem":

- `Livro` guarda suas próprias cópias;
- `Usuario` guarda a lista dos seus empréstimos (composição);
- `Emprestimo` guarda o livro e o seu próprio estado (`ativo`);
- `Biblioteca` guarda apenas dois mapas (livros e usuários por código) e a lista de regras.

Consequência prática: desapareceram os contadores e os vetores de tamanho fixo (`MAX_LIVROS` etc.). Em Java, `Map` e `List` crescem sozinhos, e a consulta por código deixou de ser uma busca sequencial escrita à mão. Também deixou de existir "estado global que todo mundo pode alterar": cada pedaço de estado tem um dono.

## 2. Responsabilidades

**Imperativo:** `emprestar_livro` fazia tudo sozinha: procurava livro e usuário, verificava as cinco regras, decrementava a cópia e criava o registro de empréstimo. As regras estavam **misturadas dentro de uma função**, numa cadeia de `if`.

**POO:** a responsabilidade foi dividida por quem tem o conhecimento:

- quem sabe se há cópia é o `Livro`;
- quem sabe quantos empréstimos ativos existem é o `Usuario`;
- quem sabe se encerrar (e repor a cópia) é o `Emprestimo`;
- cada regra de negócio é responsabilidade de uma classe `Regra...`;
- a `Biblioteca` só orquestra.

A operação de devolução mostra bem a diferença: em C, `devolver_livro` alterava ao mesmo tempo o flag do empréstimo e o contador do livro. Em Java, `Biblioteca.devolver` só pede ao `Usuario` que devolva; o `Usuario` localiza o `Emprestimo`, que se encerra e devolve a cópia ao `Livro`. Cada passo acontece onde os dados moram.

## 3. Relacionamento entre componentes

**Imperativo:** os componentes se relacionavam por **códigos inteiros** (`codigo_usuario`, `codigo_livro`) e por **buscas** nos vetores. Um empréstimo apontava para um usuário e um livro apenas pelo número, e cada função precisava refazer a busca.

**POO:** os relacionamentos são **referências entre objetos**:

- **Composição:** `Usuario` *contém* seus `Emprestimo`s (o ciclo de vida do empréstimo pertence ao usuário e a lista nunca é exposta de forma modificável).
- **Associação:** `Emprestimo` referencia o `Livro` emprestado (o livro existe independentemente do empréstimo).
- **Agregação:** `Biblioteca` reúne livros e usuários, que existem no acervo/cadastro.
- **Dependência por abstração:** `Biblioteca` depende de `RegraEmprestimo` (a interface), não das regras concretas.

Os códigos numéricos continuam existindo, mas só na fronteira do sistema (menu e busca inicial na `Biblioteca`). Depois disso, o código trabalha com objetos.

## 4. Reutilização

**Imperativo:** o reaproveitamento era por **funções auxiliares** (`buscar_indice_livro`, `contar_emprestimos_ativos`). Funciona, mas essas funções dependiam da forma exata da `struct Biblioteca` e dos seus vetores.

**POO:** o reaproveitamento é por **objetos e contratos**:

- as regras são reutilizáveis e combináveis: a `Biblioteca` pode ser criada com qualquer lista de regras (`new Biblioteca(minhasRegras)`);
- `RegraLimiteEmprestimos` recebe o limite por parâmetro, então a mesma classe serve para limites 1, 3 ou 10;
- `Livro`, `Usuario` e `Emprestimo` não sabem nada de menu ou de console, e poderiam ser usados por uma interface gráfica ou web sem alteração;
- a mesma `Biblioteca` é usada por `Main` (sistema) e `Validacao` (testes), como no modelo imperativo, mas agora sem depender de detalhes internos de armazenamento.

## 5. Encapsulamento

**Imperativo:** os campos das `struct`s eram públicos por natureza. Qualquer função podia escrever `b->livros[i].copias_disponiveis = -5;` e o compilador não reclamava. A consistência dependia da **disciplina do programador**.

**POO:** os campos são `private`, e as únicas formas de alterar o estado são métodos que **protegem os invariantes**:

- `Livro.retirarCopia()` recusa a operação se não houver cópia, então é impossível ter número negativo de cópias;
- o construtor de `Livro` rejeita cópias negativas;
- os métodos que mudam estado (`retirarCopia`, `devolverCopia`, `pegarEmprestado`, `devolver`, `encerrar`) têm visibilidade de pacote: código externo não consegue chamá-los diretamente, só a `Biblioteca` e as classes do domínio;
- `Usuario.getEmprestimosAtivos()` devolve uma lista **não modificável**, impedindo que quem consulta altere o estado do usuário por acidente.

Observação honesta: a regra "livro disponível" existe em dois lugares, em `RegraLivroDisponivel` e dentro de `Livro.retirarCopia()`. Não é acidente: a regra garante uma **mensagem e ordem de validação** previsíveis para a `Biblioteca`, enquanto o método do `Livro` é uma **defesa do invariante** do próprio objeto, caso alguém o use sem passar pela `Biblioteca`.

## 6. Extensão do sistema

**Imperativo:** para criar uma nova regra (por exemplo, "usuário com pendência não pode pegar livro") seria preciso **editar `emprestar_livro`**, acrescentando mais um `if` e, possivelmente, novos códigos no `enum` e novos `case` no `switch` de mensagens. Cada extensão mexe em código já testado.

**POO:** a mesma extensão exige apenas:

1. criar uma classe `RegraUsuarioSemPendencia implements RegraEmprestimo`;
2. (opcional) criar uma exceção que estenda `EmprestimoRecusadoException`;
3. incluir a nova regra na lista passada à `Biblioteca`.

Nenhuma classe existente precisa ser modificada (princípio aberto/fechado). Do mesmo modo, uma biblioteca infantil com limite de 1 livro é só `new RegraLimiteEmprestimos(1)`.

## Uso de herança, polimorfismo e composição (e por quê)

- **Polimorfismo:** aparece em `RegraEmprestimo`. A `Biblioteca` percorre a lista de regras e chama `verificar(...)` sem saber qual regra é qual; cada implementação decide o que checar. Aqui o polimorfismo tem um papel real: é o mecanismo que torna o sistema extensível.
- **Herança:** usada **apenas** onde a relação "é-um" é natural, na hierarquia de exceções. `LivroIndisponivelException`, `LimiteEmprestimosException` e `TituloJaEmprestadoException` *são* recusas de empréstimo (`EmprestimoRecusadoException`), e todas *são* erros da biblioteca (`BibliotecaException`). Isso permite tratar erros de forma genérica (`catch (BibliotecaException e)`, como faz o `Main`) ou específica (como faz a `Validacao`, que verifica *qual* regra falhou).
- **Herança que NÃO foi usada:** não criei subclasses de `Livro` (por exemplo `LivroFisico`/`LivroDigital`) nem de `Usuario` (`Aluno`/`Professor`), porque o problema da Etapa 1 não distingue tipos de livro nem de usuário. Criar essas hierarquias seria herança só "para cumprir requisito". Se no futuro os usuários tivessem limites diferentes, a solução preferível seria **composição**: cada `Usuario` receberia uma regra de limite própria, em vez de subclasses.
- **Composição:** `Usuario` contém `Emprestimo`s; `Biblioteca` contém as regras. Foi a ferramenta principal de modelagem.

## Custos e limitações da abordagem

Para ser justa na comparação, o modelo orientado a objetos também tem custos neste problema:

- **Mais classes e mais indireção:** o sistema que em C cabia em três arquivos (`biblioteca.h`, `biblioteca.c`, `main.c`) agora é organizado em 17 classes/interfaces de domínio (agrupadas dentro de `Main.java`, com `Validacao.java` à parte). O número de conceitos distintos aumentou mesmo mantendo poucos arquivos; para um problema tão pequeno, isso é mais estrutura do que o estritamente necessário — o benefício aparece quando o sistema cresce.
- **Fluxo menos linear:** em C, era possível ler `emprestar_livro` de cima para baixo e ver tudo o que acontecia. Em Java, o mesmo fluxo atravessa `Biblioteca`, as regras, `Usuario`, `Emprestimo` e `Livro`.
- **Estado continua mutável:** apesar do encapsulamento, o estado ainda é alterado por efeitos colaterais (`copiasDisponiveis--`). A diferença é que esse efeito colateral está **confinado** a poucos métodos que protegem o invariante, e não espalhado por qualquer função.

## Conclusão

Ao migrar do imperativo para o orientado a objetos, o modelo deixou de ser "dados + funções que os manipulam" e passou a ser "objetos que sabem manter a si mesmos consistentes e colaboram para cumprir as regras". O que mais mudou não foi a sintaxe, e sim **onde as decisões moram**: as regras do problema, que antes estavam concentradas em uma função longa, agora estão distribuídas em objetos pequenos e substituíveis, o que torna o sistema mais fácil de estender e de proteger contra estados inválidos, ao custo de mais estrutura e de um fluxo de execução mais indireto.
