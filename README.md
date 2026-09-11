# projeto-p4-debora-rangel



Etapas do Projeto - \[P4-ETAPA-01] Proposta e especificacao do problema

\# ETAPA 01 — Proposta e Especificação do Problema



\## Sistema de Empréstimo de Livros de uma Biblioteca



\## 1. Descrição do problema



Uma pequena biblioteca deseja controlar o empréstimo e a devolução de livros para seus

usuários de forma simples. Atualmente esse controle é feito em papel, o que causa

confusão sobre quais livros estão emprestados, quem os pegou e quando devem ser

devolvidos. O sistema a ser desenvolvido deverá gerenciar o acervo de livros, os

usuários cadastrados e os empréstimos realizados, permitindo saber a qualquer momento

quais livros estão disponíveis e quais estão emprestados.



\## 2. Objetivo



O sistema deverá ser capaz de:



\- Cadastrar livros no acervo da biblioteca;

\- Cadastrar usuários da biblioteca;

\- Registrar o empréstimo de um livro a um usuário;

\- Registrar a devolução de um livro;

\- Consultar a disponibilidade de um livro;

\- Consultar quais livros um usuário tem emprestados no momento.



\## 3. Entradas



\- Dados de um livro: código identificador, título e número de cópias disponíveis no acervo;

\- Dados de um usuário: código identificador e nome;

\- Pedido de empréstimo: código do usuário e código do livro;

\- Pedido de devolução: código do usuário e código do livro;

\- Pedido de consulta: código do livro ou código do usuário.



\## 4. Saídas



\- Confirmação de que um livro foi cadastrado, emprestado ou devolvido com sucesso;

\- Mensagem informando que uma operação não pôde ser realizada, com o motivo (ex.: livro indisponível, usuário com limite atingido, livro não emprestado ao usuário);

\- Lista de cópias disponíveis de um livro;

\- Lista de livros atualmente emprestados a um usuário.



\## 5. Regras do problema



1\. Cada livro possui um código único e uma quantidade de cópias físicas disponíveis no acervo.

2\. Um livro só pode ser emprestado se existir pelo menos uma cópia disponível no momento do pedido.

3\. Ao emprestar um livro, o número de cópias disponíveis desse livro é reduzido em uma unidade.

4\. Ao devolver um livro, o número de cópias disponíveis desse livro é aumentado em uma unidade.

5\. Cada usuário pode ter, no máximo, 3 (três) livros emprestados simultaneamente.

6\. Um usuário não pode pegar emprestada uma cópia adicional do mesmo título se já possuir uma cópia desse título emprestada.

7\. Não é possível devolver um livro que não conste como emprestado para aquele usuário.

8\. Todo empréstimo e toda devolução devem referenciar um usuário e um livro previamente cadastrados.



\## 6. Casos de exemplo



1\. Entrada: cadastrar livro (código 1, título "Dom Casmurro", 2 cópias)

&#x20;  Saída: livro cadastrado com sucesso, 2 cópias disponíveis.

2\. Entrada: cadastrar usuário (código 10, nome "Ana")

&#x20;  Saída: usuário cadastrado com sucesso.

3\. Entrada: emprestar livro 1 ao usuário 10

&#x20;  Saída: empréstimo registrado; livro 1 passa a ter 1 cópia disponível.

4\. Entrada: consultar livros emprestados pelo usuário 10

&#x20;  Saída: \["Dom Casmurro"].

5\. Entrada: devolver livro 1 do usuário 10

&#x20;  Saída: devolução registrada; livro 1 passa a ter 2 cópias disponíveis.



\## 7. Casos-limite



1\. Tentar emprestar um livro que não possui nenhuma cópia disponível: o sistema deve recusar o empréstimo e informar que o livro está indisponível.

2\. Tentar emprestar um quarto livro a um usuário que já possui 3 livros emprestados: o sistema deve recusar a operação, informando que o limite de empréstimos foi atingido.

3\. Tentar devolver um livro que o usuário não possui emprestado: o sistema deve recusar a devolução e informar que não há empréstimo correspondente.



\## 8. Restrições



Estão fora do escopo deste projeto:



\- Cálculo de multas por atraso na devolução;

\- Reservas antecipadas de livros indisponíveis;

\- Autenticação de usuários (login e senha);

\- Interface gráfica ou persistência em banco de dados — o foco é a lógica do domínio do problema.



\## 9. Principais conceitos do domínio



\- \*\*Livro\*\*: possui código, título e quantidade de cópias disponíveis;

\- \*\*Usuário\*\*: possui código e nome;

\- \*\*Empréstimo\*\*: relação entre um usuário e um livro, com uma data de início;

\- \*\*Acervo\*\*: coleção de todos os livros cadastrados na biblioteca;

\- \*\*Limite de empréstimos\*\*: regra que restringe a quantidade de livros que um usuário pode manter emprestados ao mesmo tempo.



\## 10. Adequação aos quatro paradigmas



\- \*\*Imperativo\*\*: o problema pode ser resolvido com estruturas de dados simples (vetores, listas ou registros) e funções que alteram esse estado passo a passo, como decrementar a quantidade de cópias disponíveis;

\- \*\*Orientado a objetos\*\*: livros, usuários e empréstimos são entidades naturais para serem modeladas como classes, cada uma responsável por seu próprio estado e comportamento (ex.: método `emprestar()` de um livro);

\- \*\*Funcional\*\*: as operações de empréstimo e devolução podem ser modeladas como funções puras que recebem o estado atual do sistema (acervo e empréstimos) e retornam um novo estado, sem alterar o estado original;

\- \*\*Lógico\*\*: as regras do problema (livro disponível, limite de empréstimos, empréstimo existente) podem ser expressas naturalmente como fatos e regras lógicas, permitindo que se façam consultas como "quais livros o usuário X pode pegar emprestado agora?".



\## 11. Linguagens inicialmente consideradas



\- \*\*Imperativo — C\*\*: linguagem clássica para o paradigma imperativo, com controle explícito de estruturas de dados e fluxo de execução;

\- \*\*Orientado a objetos — Java\*\*: linguagem amplamente utilizada para POO, com suporte robusto a classes, encapsulamento e herança;

\- \*\*Funcional — Haskell\*\*: linguagem puramente funcional, adequada para expressar as operações do sistema como funções sem efeitos colaterais;

\- \*\*Lógico — Prolog\*\*: linguagem natural para expressar as regras do problema como fatos e regras lógicas, permitindo consultas diretas ao motor de inferência.


