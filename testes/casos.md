# Casos de Teste — Sistema de Empréstimo de Livros de uma Biblioteca

**Descrição:** Conjunto de testes independentes de paradigma para avaliar o cadastro, empréstimo, devolução e consulta de livros em uma biblioteca. **Entradas Base:** Acervo (lista de livros com código, título e cópias disponíveis), Usuários (lista de usuários com código e nome) e Empréstimos (relação entre usuário e livro). **Saídas Base:** Confirmação ou recusa da operação, com o motivo exato no caso de recusa, e listas de consulta (disponibilidade de um livro ou livros emprestados por um usuário).

## Casos Normais (10 casos)

- **Identificador:** NORM-01
  - **Entrada:** Cadastrar livro (código 1, título "Dom Casmurro", 2 cópias).
  - **Saída esperada:** Livro cadastrado com sucesso; 2 cópias disponíveis.
  - **Descrição:** Cadastro básico de um livro novo no acervo.

- **Identificador:** NORM-02
  - **Entrada:** Cadastrar usuário (código 10, nome "Ana").
  - **Saída esperada:** Usuário cadastrado com sucesso.
  - **Descrição:** Cadastro básico de um usuário novo na biblioteca.

- **Identificador:** NORM-03
  - **Entrada:** Livro 1 com 2 cópias disponíveis; usuário 10 solicita empréstimo do livro 1.
  - **Saída esperada:** Empréstimo registrado; livro 1 passa a ter 1 cópia disponível.
  - **Descrição:** Empréstimo de um livro com cópia disponível para um usuário sem empréstimos anteriores.

- **Identificador:** NORM-04
  - **Entrada:** Consultar disponibilidade do livro 1 (2 cópias cadastradas, nenhum empréstimo ativo).
  - **Saída esperada:** 2 cópias disponíveis.
  - **Descrição:** Consulta de disponibilidade de um livro sem empréstimos registrados.

- **Identificador:** NORM-05
  - **Entrada:** Usuário 10 possui o livro 1 ("Dom Casmurro") emprestado; consultar livros emprestados pelo usuário 10.
  - **Saída esperada:** ["Dom Casmurro"].
  - **Descrição:** Consulta dos livros atualmente emprestados a um usuário específico.

- **Identificador:** NORM-06
  - **Entrada:** Usuário 10 possui o livro 1 emprestado; devolver o livro 1 do usuário 10.
  - **Saída esperada:** Devolução registrada; livro 1 passa a ter 2 cópias disponíveis.
  - **Descrição:** Devolução de um livro corretamente emprestado ao usuário.

- **Identificador:** NORM-07
  - **Entrada:** Usuário 10 já possui o livro 1 emprestado; solicita empréstimo do livro 2 ("O Cortiço", 3 cópias disponíveis).
  - **Saída esperada:** Empréstimo do livro 2 registrado; usuário 10 passa a ter 2 livros emprestados.
  - **Descrição:** Empréstimo de um segundo título diferente ao mesmo usuário, dentro do limite permitido.

- **Identificador:** NORM-08
  - **Entrada:** Usuário 10 já possui os livros 1 e 2 emprestados; solicita empréstimo do livro 3 ("Vidas Secas", 1 cópia disponível).
  - **Saída esperada:** Empréstimo do livro 3 registrado; usuário 10 passa a ter 3 livros emprestados (limite máximo atingido, mas ainda válido).
  - **Descrição:** Empréstimo do terceiro título simultâneo, exatamente no limite permitido pelas regras.

- **Identificador:** NORM-09
  - **Entrada:** Cadastrar dois livros com títulos diferentes e códigos distintos: livro 4 ("Iracema", 1 cópia) e livro 5 ("Capitães da Areia", 4 cópias).
  - **Saída esperada:** Ambos os livros cadastrados com sucesso, cada um com sua respectiva quantidade de cópias.
  - **Descrição:** Cadastro de múltiplos livros distintos no mesmo acervo.

- **Identificador:** NORM-10
  - **Entrada:** Usuário 20 (sem nenhum empréstimo ativo) consulta seus livros emprestados.
  - **Saída esperada:** Lista vazia [].
  - **Descrição:** Consulta de empréstimos para um usuário cadastrado que nunca pegou nenhum livro emprestado.

## Casos-limite (3 casos)

- **Identificador:** LIM-01
  - **Entrada:** Usuário 10 já possui 3 livros emprestados (livros 1, 2 e 3); solicita empréstimo de um quarto livro (livro 4).
  - **Saída esperada:** Empréstimo recusado; mensagem informando que o limite de 3 livros emprestados foi atingido.
  - **Descrição:** Tentativa de exceder o limite máximo de empréstimos simultâneos por usuário.

- **Identificador:** LIM-02
  - **Entrada:** Livro 3 ("Vidas Secas") com apenas 1 cópia, já emprestada a outro usuário (0 cópias disponíveis); usuário 20 solicita empréstimo do livro 3.
  - **Saída esperada:** Empréstimo recusado; mensagem informando que o livro está indisponível.
  - **Descrição:** Tentativa de emprestar um livro que não possui nenhuma cópia disponível no momento do pedido.

- **Identificador:** LIM-03
  - **Entrada:** Usuário 10 já possui uma cópia do livro 1 ("Dom Casmurro") emprestada; solicita emprestar novamente o mesmo livro 1.
  - **Saída esperada:** Empréstimo recusado; mensagem informando que o usuário já possui uma cópia desse título emprestada.
  - **Descrição:** Tentativa de um mesmo usuário pegar emprestada uma segunda cópia do mesmo título simultaneamente.

## Casos de Entrada Inválida (2 casos)

- **Identificador:** INV-01
  - **Entrada:** Usuário 10 solicita empréstimo de um livro com código inexistente no acervo (ex.: código 999).
  - **Saída esperada:** Erro tratado informando que o livro não foi encontrado/cadastrado.
  - **Descrição:** Validação de referência a um livro que não existe no sistema.

- **Identificador:** INV-02
  - **Entrada:** Usuário 10 solicita a devolução do livro 5, que nunca foi emprestado a ele.
  - **Saída esperada:** Erro tratado informando que não há empréstimo correspondente para aquele usuário e livro.
  - **Descrição:** Validação de tentativa de devolução sem um empréstimo ativo correspondente.
