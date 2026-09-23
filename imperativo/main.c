#include <stdio.h>
#include <string.h>
#include "biblioteca.h.h"

static void ler_linha(char *destino, int tamanho) {
    if (fgets(destino, tamanho, stdin) != NULL) {
        size_t len = strlen(destino);
        if (len > 0 && destino[len - 1] == '\n') {
            destino[len - 1] = '\0';
        }
    } else {
        destino[0] = '\0';
    }
}

static int ler_inteiro(void) {
    int valor = 0;
    if (scanf("%d", &valor) != 1) {
        valor = -1; 
    }
    while (getchar() != '\n') {
        
    }
    return valor;
}

static void exibir_menu(void) {
    printf("\n===== Sistema de Emprestimo de Livros da Biblioteca =====\n");
    printf("1. Cadastrar livro\n");
    printf("2. Cadastrar usuario\n");
    printf("3. Emprestar livro\n");
    printf("4. Devolver livro\n");
    printf("5. Consultar disponibilidade de um livro\n");
    printf("6. Consultar livros emprestados por um usuario\n");
    printf("0. Sair\n");
    printf("Escolha uma opcao: ");
}

static void opcao_cadastrar_livro(Biblioteca *b) {
    int codigo, copias;
    char titulo[TAM_TITULO];
    CodigoResultado resultado;

    printf("Codigo do livro: ");
    codigo = ler_inteiro();

    printf("Titulo do livro: ");
    ler_linha(titulo, TAM_TITULO);

    printf("Numero de copias: ");
    copias = ler_inteiro();

    resultado = cadastrar_livro(b, codigo, titulo, copias);
    printf(">> %s\n", mensagem_resultado(resultado));
}

static void opcao_cadastrar_usuario(Biblioteca *b) {
    int codigo;
    char nome[TAM_NOME];
    CodigoResultado resultado;

    printf("Codigo do usuario: ");
    codigo = ler_inteiro();

    printf("Nome do usuario: ");
    ler_linha(nome, TAM_NOME);

    resultado = cadastrar_usuario(b, codigo, nome);
    printf(">> %s\n", mensagem_resultado(resultado));
}

static void opcao_emprestar_livro(Biblioteca *b) {
    int codigo_usuario, codigo_livro;
    CodigoResultado resultado;

    printf("Codigo do usuario: ");
    codigo_usuario = ler_inteiro();

    printf("Codigo do livro: ");
    codigo_livro = ler_inteiro();

    resultado = emprestar_livro(b, codigo_usuario, codigo_livro);
    printf(">> %s\n", mensagem_resultado(resultado));
}

static void opcao_devolver_livro(Biblioteca *b) {
    int codigo_usuario, codigo_livro;
    CodigoResultado resultado;

    printf("Codigo do usuario: ");
    codigo_usuario = ler_inteiro();

    printf("Codigo do livro: ");
    codigo_livro = ler_inteiro();

    resultado = devolver_livro(b, codigo_usuario, codigo_livro);
    printf(">> %s\n", mensagem_resultado(resultado));
}

static void opcao_consultar_disponibilidade(Biblioteca *b) {
    int codigo_livro, disponiveis;

    printf("Codigo do livro: ");
    codigo_livro = ler_inteiro();

    disponiveis = consultar_disponibilidade(b, codigo_livro);
    if (disponiveis == -1) {
        printf(">> %s\n", mensagem_resultado(ERRO_LIVRO_NAO_ENCONTRADO));
    } else {
        printf(">> O livro %d possui %d copia(s) disponivel(is).\n",
               codigo_livro, disponiveis);
    }
}

static void opcao_consultar_emprestimos_usuario(Biblioteca *b) {
    int codigo_usuario, quantidade, i;
    char titulos[LIMITE_EMPRESTIMOS_POR_USUARIO][TAM_TITULO];

    printf("Codigo do usuario: ");
    codigo_usuario = ler_inteiro();

    if (buscar_indice_usuario(b, codigo_usuario) == -1) {
        printf(">> %s\n", mensagem_resultado(ERRO_USUARIO_NAO_ENCONTRADO));
        return;
    }

    consultar_emprestimos_usuario(b, codigo_usuario, titulos, &quantidade);

    if (quantidade == 0) {
        printf(">> O usuario %d nao possui livros emprestados no momento.\n",
               codigo_usuario);
    } else {
        printf(">> Livros emprestados ao usuario %d:\n", codigo_usuario);
        for (i = 0; i < quantidade; i++) {
            printf("   - %s\n", titulos[i]);
        }
    }
}

int main(void) {
    Biblioteca biblioteca;
    int opcao;
    int continuar = 1; 

    inicializar_biblioteca(&biblioteca);

    printf("Sistema de Emprestimo de Livros - Biblioteca\n");
   
    while (continuar) {
        exibir_menu();
        opcao = ler_inteiro();

        switch (opcao) {
            case 1:
                opcao_cadastrar_livro(&biblioteca);
                break;
            case 2:
                opcao_cadastrar_usuario(&biblioteca);
                break;
            case 3:
                opcao_emprestar_livro(&biblioteca);
                break;
            case 4:
                opcao_devolver_livro(&biblioteca);
                break;
            case 5:
                opcao_consultar_disponibilidade(&biblioteca);
                break;
            case 6:
                opcao_consultar_emprestimos_usuario(&biblioteca);
                break;
            case 0:
                continuar = 0; 
                printf("Encerrando o sistema. Ate mais!\n");
                break;
            default:
                printf(">> Opcao invalida. Tente novamente.\n");
                break;
        }
    }

    return 0;
}
