#include <string.h>
#include "biblioteca.h.h"

void inicializar_biblioteca(Biblioteca *b) {
    b->num_livros = 0;
    b->num_usuarios = 0;
    b->num_emprestimos = 0;
}

int buscar_indice_livro(Biblioteca *b, int codigo_livro) {
    int i;
    for (i = 0; i < b->num_livros; i++) {
        if (b->livros[i].codigo == codigo_livro) {
            return i;
        }
    }
    return -1;
}

int buscar_indice_usuario(Biblioteca *b, int codigo_usuario) {
    int i;
    for (i = 0; i < b->num_usuarios; i++) {
        if (b->usuarios[i].codigo == codigo_usuario) {
            return i;
        }
    }
    return -1;
}

int usuario_possui_livro_ativo(Biblioteca *b, int codigo_usuario, int codigo_livro) {
    int i;
    for (i = 0; i < b->num_emprestimos; i++) {
        if (b->emprestimos[i].codigo_usuario == codigo_usuario &&
            b->emprestimos[i].codigo_livro == codigo_livro &&
            b->emprestimos[i].ativo == 1) {
            return 1;
        }
    }
    return 0;
}

int contar_emprestimos_ativos(Biblioteca *b, int codigo_usuario) {
    int i;
    int total = 0; 
    for (i = 0; i < b->num_emprestimos; i++) {
        if (b->emprestimos[i].codigo_usuario == codigo_usuario &&
            b->emprestimos[i].ativo == 1) {
            total = total + 1; 
        }
    }
    return total;
}

CodigoResultado cadastrar_livro(Biblioteca *b, int codigo, const char *titulo, int copias) {
   
    if (buscar_indice_livro(b, codigo) != -1) {
        return ERRO_LIVRO_JA_CADASTRADO;
    }
    if (b->num_livros >= MAX_LIVROS) {
        return ERRO_CAPACIDADE_EXCEDIDA;
    }

    b->livros[b->num_livros].codigo = codigo;
    strncpy(b->livros[b->num_livros].titulo, titulo, TAM_TITULO - 1);
    b->livros[b->num_livros].titulo[TAM_TITULO - 1] = '\0';
    b->livros[b->num_livros].copias_disponiveis = copias;
    b->num_livros = b->num_livros + 1;

    return OK;
}

CodigoResultado cadastrar_usuario(Biblioteca *b, int codigo, const char *nome) {
    if (buscar_indice_usuario(b, codigo) != -1) {
        return ERRO_USUARIO_JA_CADASTRADO;
    }
    if (b->num_usuarios >= MAX_USUARIOS) {
        return ERRO_CAPACIDADE_EXCEDIDA;
    }

    b->usuarios[b->num_usuarios].codigo = codigo;
    strncpy(b->usuarios[b->num_usuarios].nome, nome, TAM_NOME - 1);
    b->usuarios[b->num_usuarios].nome[TAM_NOME - 1] = '\0';
    b->num_usuarios = b->num_usuarios + 1;

    return OK;
}

CodigoResultado emprestar_livro(Biblioteca *b, int codigo_usuario, int codigo_livro) {
    int idx_livro = buscar_indice_livro(b, codigo_livro);
    int idx_usuario = buscar_indice_usuario(b, codigo_usuario);

    if (idx_livro == -1) {
        return ERRO_LIVRO_NAO_ENCONTRADO;
    }
    if (idx_usuario == -1) {
        return ERRO_USUARIO_NAO_ENCONTRADO;
    }
    if (b->livros[idx_livro].copias_disponiveis <= 0) {
        return ERRO_LIVRO_INDISPONIVEL;
    }
    if (contar_emprestimos_ativos(b, codigo_usuario) >= LIMITE_EMPRESTIMOS_POR_USUARIO) {
        return ERRO_LIMITE_EMPRESTIMOS_ATINGIDO;
    }
    if (usuario_possui_livro_ativo(b, codigo_usuario, codigo_livro)) {
        return ERRO_USUARIO_JA_POSSUI_TITULO;
    }
    if (b->num_emprestimos >= MAX_EMPRESTIMOS) {
        return ERRO_CAPACIDADE_EXCEDIDA;
    }

    b->livros[idx_livro].copias_disponiveis = b->livros[idx_livro].copias_disponiveis - 1;

    b->emprestimos[b->num_emprestimos].codigo_usuario = codigo_usuario;
    b->emprestimos[b->num_emprestimos].codigo_livro = codigo_livro;
    b->emprestimos[b->num_emprestimos].ativo = 1;
    b->num_emprestimos = b->num_emprestimos + 1;

    return OK;
}

CodigoResultado devolver_livro(Biblioteca *b, int codigo_usuario, int codigo_livro) {
    int idx_livro = buscar_indice_livro(b, codigo_livro);
    int idx_emprestimo = -1;
    int i;

    if (idx_livro == -1) {
        return ERRO_LIVRO_NAO_ENCONTRADO;
    }
    if (buscar_indice_usuario(b, codigo_usuario) == -1) {
        return ERRO_USUARIO_NAO_ENCONTRADO;
    }

    for (i = 0; i < b->num_emprestimos; i++) {
        if (b->emprestimos[i].codigo_usuario == codigo_usuario &&
            b->emprestimos[i].codigo_livro == codigo_livro &&
            b->emprestimos[i].ativo == 1) {
            idx_emprestimo = i;
        }
    }

    if (idx_emprestimo == -1) {
        return ERRO_EMPRESTIMO_NAO_ENCONTRADO;
    }

    b->emprestimos[idx_emprestimo].ativo = 0;
    b->livros[idx_livro].copias_disponiveis = b->livros[idx_livro].copias_disponiveis + 1;

    return OK;
}

int consultar_disponibilidade(Biblioteca *b, int codigo_livro) {
    int idx = buscar_indice_livro(b, codigo_livro);
    if (idx == -1) {
        return -1;
    }
    return b->livros[idx].copias_disponiveis;
}

void consultar_emprestimos_usuario(Biblioteca *b, int codigo_usuario,
                                    char titulos_saida[][TAM_TITULO], int *quantidade) {
    int i;
    int count = 0; 

    for (i = 0; i < b->num_emprestimos; i++) {
        if (b->emprestimos[i].codigo_usuario == codigo_usuario &&
            b->emprestimos[i].ativo == 1) {
            int idx_livro = buscar_indice_livro(b, b->emprestimos[i].codigo_livro);
            if (idx_livro != -1) {
                strncpy(titulos_saida[count], b->livros[idx_livro].titulo, TAM_TITULO - 1);
                titulos_saida[count][TAM_TITULO - 1] = '\0';
                count = count + 1;
            }
        }
    }

    *quantidade = count; 
}

const char *mensagem_resultado(CodigoResultado codigo) {
    
    switch (codigo) {
        case OK:
            return "Operacao realizada com sucesso.";
        case ERRO_LIVRO_JA_CADASTRADO:
            return "Ja existe um livro cadastrado com esse codigo.";
        case ERRO_USUARIO_JA_CADASTRADO:
            return "Ja existe um usuario cadastrado com esse codigo.";
        case ERRO_LIVRO_NAO_ENCONTRADO:
            return "Livro nao encontrado/cadastrado.";
        case ERRO_USUARIO_NAO_ENCONTRADO:
            return "Usuario nao encontrado/cadastrado.";
        case ERRO_LIVRO_INDISPONIVEL:
            return "O livro esta indisponivel no momento.";
        case ERRO_LIMITE_EMPRESTIMOS_ATINGIDO:
            return "O usuario atingiu o limite de 3 livros emprestados.";
        case ERRO_USUARIO_JA_POSSUI_TITULO:
            return "O usuario ja possui uma copia desse titulo emprestada.";
        case ERRO_EMPRESTIMO_NAO_ENCONTRADO:
            return "Nao ha emprestimo correspondente a essa devolucao.";
        case ERRO_CAPACIDADE_EXCEDIDA:
            return "Capacidade maxima do sistema atingida.";
        default:
            return "Codigo de resultado desconhecido.";
    }
}
