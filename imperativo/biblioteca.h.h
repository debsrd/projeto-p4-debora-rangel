#ifndef BIBLIOTECA_H
#define BIBLIOTECA_H

#define MAX_LIVROS       50
#define MAX_USUARIOS     50
#define MAX_EMPRESTIMOS  200
#define LIMITE_EMPRESTIMOS_POR_USUARIO 3
#define TAM_TITULO       100
#define TAM_NOME         100

typedef enum {
    OK = 0,
    ERRO_LIVRO_JA_CADASTRADO,
    ERRO_USUARIO_JA_CADASTRADO,
    ERRO_LIVRO_NAO_ENCONTRADO,
    ERRO_USUARIO_NAO_ENCONTRADO,
    ERRO_LIVRO_INDISPONIVEL,
    ERRO_LIMITE_EMPRESTIMOS_ATINGIDO,
    ERRO_USUARIO_JA_POSSUI_TITULO,
    ERRO_EMPRESTIMO_NAO_ENCONTRADO,
    ERRO_CAPACIDADE_EXCEDIDA
} CodigoResultado;

typedef struct {
    int codigo;
    char titulo[TAM_TITULO];
    int copias_disponiveis;
} Livro;

typedef struct {
    int codigo;
    char nome[TAM_NOME];
} Usuario;

typedef struct {
    int codigo_usuario;
    int codigo_livro;
    int ativo; 
} Emprestimo;

typedef struct {
    Livro livros[MAX_LIVROS];
    int num_livros;

    Usuario usuarios[MAX_USUARIOS];
    int num_usuarios;

    Emprestimo emprestimos[MAX_EMPRESTIMOS];
    int num_emprestimos;
} Biblioteca;

void inicializar_biblioteca(Biblioteca *b);

CodigoResultado cadastrar_livro(Biblioteca *b, int codigo, const char *titulo, int copias);

CodigoResultado cadastrar_usuario(Biblioteca *b, int codigo, const char *nome);

CodigoResultado emprestar_livro(Biblioteca *b, int codigo_usuario, int codigo_livro);

CodigoResultado devolver_livro(Biblioteca *b, int codigo_usuario, int codigo_livro);

int consultar_disponibilidade(Biblioteca *b, int codigo_livro);

void consultar_emprestimos_usuario(Biblioteca *b, int codigo_usuario,
                                    char titulos_saida[][TAM_TITULO], int *quantidade);

int buscar_indice_livro(Biblioteca *b, int codigo_livro);
int buscar_indice_usuario(Biblioteca *b, int codigo_usuario);

int usuario_possui_livro_ativo(Biblioteca *b, int codigo_usuario, int codigo_livro);

int contar_emprestimos_ativos(Biblioteca *b, int codigo_usuario);

const char *mensagem_resultado(CodigoResultado codigo);

#endif 
