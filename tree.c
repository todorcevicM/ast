
#include "tree.h"

int indent = 0;

TREE_NODE *create_node(char *name, unsigned kind, unsigned type, TREE_NODE *parent, TREE_NODE *sibling) {
    TREE_NODE *node = (TREE_NODE *) malloc(sizeof(TREE_NODE));
    node -> node_data = (NODE_DATA *) malloc(sizeof(NODE_DATA));

    strcpy(node -> node_data -> name, name);
    node -> node_data -> kind = kind;
    node -> node_data -> type = type;

    if (kind == LIT) {
        if (type == INT) {
            node -> node_data -> value = (VALUE *) malloc(sizeof(int));
            node -> node_data -> value -> i = atoi(name);
        }
        else if (type == UINT) {
            node -> node_data -> value = (VALUE *) malloc(sizeof(unsigned));
            node -> node_data -> value -> u = atoi(name);
        }
    }

    node -> parent = parent;
    node -> sibling = sibling;
    node -> child = NULL;

    return node;
}

TREE_NODE* init_tree() {
    return create_node("program", NO_KIND, NO_TYPE, NULL, NULL);
}

TREE_NODE *make_function(TREE_NODE **tree, char* name, unsigned type) {
    TREE_NODE *function_root = NULL;

    // ako slucajno nije kreirao program
    if (!(*tree)) {
        (*tree) = init_tree();

        return make_function(tree, name, type);
    }
    // poseban slucaj za kad nema dete
    else if (!((*tree) -> child)) {
        function_root = create_node(name, FUN, type, *tree, NULL);
        (*tree) -> child = function_root;

        return function_root;
    }
    // kada poseduje child 
    else {
        TREE_NODE *temp = (*tree) -> child;
        TREE_NODE *temp1 = NULL;
        // provera za sam child
        if (!strcmp(temp -> node_data -> name, name) && temp -> node_data -> kind == FUN) {
            printf("Greska, funckija sa imenom %s vec postoji\n\n", name);
            return NULL;
        }
        else {
            temp = temp -> sibling;
            // nema sibling 
            if (!temp) {
                function_root = create_node(name, FUN, type, NULL, NULL);
                (*tree) -> child -> sibling = function_root;

                return function_root;
            }
            // ima sibling
            else {
                while (temp) {
                    if (!strcmp(temp -> node_data -> name, name) && temp -> node_data -> kind == FUN) {
                        printf("Greska, funckija sa imenom %s vec postoji\n\n", name);
                        return NULL;
                    }
                    temp1 = temp;
                    temp = temp -> sibling;
                }
                // nije pronasao funkciju sa tim imenom, moze da napravi cvor
                function_root = create_node(name, FUN, type, NULL, NULL);
                temp1 -> sibling = function_root;

                return function_root;
            }
        }
    }
}

TREE_NODE *make_parameter(TREE_NODE **function_node, char* param_name, unsigned type) {

    if (!(*function_node)) {
        printf("Greska, niste prosledili funckiju pri kreiranju parametra\n\n");
        return NULL;
    }

    TREE_NODE *temp = (*function_node) -> parameter;
    // nema ni jedan parametar
    if (!temp) {
        temp = create_node(param_name, PAR, type, *function_node, NULL);
        (*function_node) -> parameter = temp; 

        return temp;
    }
    // ima barem jedan parametar
    else {
        // provera imena
        while (temp) {
            if (!strcmp(temp -> node_data -> name, param_name)) {
                printf("Parametar %s vec postoji kao parametar koji funckija %s prima\n\n", param_name, (*function_node) -> node_data -> name); 

                return NULL;
            }
            if (!(temp -> sibling)) {
                TREE_NODE *temp1 = create_node(param_name, PAR, type, *function_node, NULL);
                temp -> sibling = temp1;

                return temp1;
            }
            temp = temp -> sibling;
        } 
    }
}

TREE_NODE *make_variable(TREE_NODE **tree, char *name, unsigned type) {
    /* 
        prosledjujem tree zbog globalnih promenljivih za koje sad nemam pravilo
        ali svakako msm da ce biti ovako lakse
     */
    // da li funkcija postoji
    if (!(*tree)) {
        printf("Greska, funkcija ne postoji!\n\n");
        return NULL;
    }
    // prvo provera imena sa parametrima koje funkcija prima
    TREE_NODE *parameter = (*tree) -> parameter;
    while (parameter) {
        if (!strcmp(parameter -> node_data -> name, name)) {
            printf("Greska, funckija %s kao parametar prima vec %s\n\n", (*tree) -> node_data -> name, name);

            return NULL;
        }
        parameter = parameter -> sibling;
    }
    // ne postoji parametar sa tim imenom
    TREE_NODE *temp = (*tree) -> child;
    TREE_NODE *temp1 = NULL;
    // nema child
    if (!temp) {
        TREE_NODE *variable = create_node(name, VAR, type, *tree, NULL);
        (*tree) -> child = variable;

        return variable;
    }
    // ima child
    else {
        while (temp) {
            if (!strcmp(temp -> node_data -> name, name)) {
                printf("Greska, funckija %s vec ima deklarisanu promenljivu %s\n\n", temp -> parent -> node_data -> name, name);

                return NULL;
            }
            temp1 = temp;
            temp = temp -> sibling;
        }
        // dosao je do kraja, treba da kreira cvor
        TREE_NODE *variable = create_node(name, VAR, type, *tree, NULL);
        temp1 -> sibling = variable;

        return variable;
    }
}

TREE_NODE *make_literal(TREE_NODE **tree, char *name, unsigned type) {
    TREE_NODE *temp = (*tree) -> child;
    TREE_NODE *temp1 = NULL;
    // nema child
    if (!temp) {
        TREE_NODE *literal = create_node(name, LIT, type, *tree, NULL);
        (*tree) -> child = literal;

        return literal;
    }
    // ima child
    else {
        while (temp) {
            temp1 = temp;
            temp = temp -> sibling;
        }
        // dosao je do kraja, treba da kreira cvor
        TREE_NODE *literal = create_node(name, LIT, type, *tree, NULL);
        temp1 -> sibling = literal;

        return literal;
    }
}

TREE_NODE *find_node(TREE_NODE **root, char *name) {
    TREE_NODE *temp = NULL;

    if (!strcmp((*root) -> node_data -> name, name)) {
        // printf("%s\n\n", (*root) -> parent -> node_data -> name);
        return *root;
    }
    if ((*root) -> node_data -> kind == FUN) {
        temp = find_node(&((*root) -> parameter), name);
        if (temp) {
            return temp;
        }
    }    
    if ((*root) -> child) {
        temp = find_node(&((*root) -> child), name);
        if (temp) {
            return temp;
        }
    }
    if ((*root) -> sibling) {
        temp = find_node(&((*root) -> sibling), name);
        if (temp) {
            return temp;
        }
    }
}

TREE_NODE *find_function(TREE_NODE **root, char *name) {
    TREE_NODE *temp = NULL;
    
    if (!strcmp((*root) -> node_data -> name, name)) {
        return *root;
    }
    if ((*root) -> sibling) {
        temp = find_function(&((*root) -> sibling), name);
        if (temp) {
            return temp;
        }
    }
    return NULL;
}
TREE_NODE *find_f(TREE_NODE **root, char *name) {
    if ((*root) -> child) {
        return find_function(&((*root) -> child), name);
    }
}

TREE_NODE *update_node(TREE_NODE **root, char *name, unsigned update_type) {
    TREE_NODE *temp = find_node(root, name);
    int i;
    char *s;

    if (update_type == 1) {
        i = atoi(temp -> node_data -> name);
        i++;
        sprintf(s, "%d", i);
        strcpy(temp -> node_data -> name, s);
    }
    else if (update_type == 2) {
        i = atoi(temp -> node_data -> name);
        i--;
        sprintf(s, "%d", i);
        strcpy(temp -> node_data -> name, s);
    }

    return temp;
}


// TREE_NODE *set_value(TREE_NODE **tree, char *name, int value) {

//     TREE_NODE *temp = find_node(tree, name);

//     // printf("%s\n\n", temp -> node_data -> name);

//     temp -> node_data -> value = malloc(sizeof(VALUE));
//     temp -> node_data -> value -> i = value;

//     // printf("%d\n\n", temp -> node_data -> value -> i);

//     // temp -> child = 


// }

TREE_NODE *set_value(TREE_NODE **tree, int value) {
    // TREE_NODE *temp = find_node(tree -> parent

    (*tree) -> node_data -> value = malloc(sizeof(VALUE));
    (*tree) -> node_data -> value -> i = value;

    char *s;
    sprintf(s, "%d", value);
    TREE_NODE *literal = find_node(&((*tree) -> parent), s);

    return update_literal_parent(tree, &literal);

    // (*tree) -> child = 

}

TREE_NODE *update_literal_parent(TREE_NODE **tree, TREE_NODE **literal) {
    TREE_NODE *temp = (*tree) -> parent -> child;
    TREE_NODE *temp1 = NULL;

    while (temp) {
        if (!strcmp(temp -> node_data -> name, (*literal) -> node_data -> name)) {
            temp -> parent = (*tree);
            (*tree) -> child = temp;
            temp1 -> sibling = NULL;

            return temp;
        }        
        temp1 = temp;
        temp = temp -> sibling;    
    }
}

unsigned print_tree(TREE_NODE *tree) {

    if (tree) {
        unsigned size = 0;
        size += 36;
        size += strlen(tree -> node_data -> name);
        size += 5;
        if (tree -> node_data -> kind < 8) {
            size--;
        }
        if (tree -> node_data -> type == NO_TYPE) {
            size++;
        }
        
        if (indent == 2) {
            size += 1;
        }

        int i = 0;
        for (i = 0; i < indent; i++) {
            printf("\t");
        }
        for (i = 0; i < size; i++) {
            printf("-");
        }
        printf("\n");
        for (i = 0; i < indent; i++) {
            printf("\t");
        }
        printf("|Node name: %s; Node type: %u; Node kind: %u|\n", 
            tree -> node_data -> name, tree -> node_data -> type, tree -> node_data -> kind);
        for (i = 0; i < indent; i++) {
            printf("\t");
        }
        for (i = 0; i < size; i++) {
            printf("-");
        }
        printf("\n");

        if (tree -> node_data -> kind == FUN) {
            indent++;
            if (print_tree(tree -> parameter)) {
                // printf("Funkcija %s nema parametre\n", tree -> node_data -> name);
                indent--;
            }
        }
        indent++;

        if (print_tree(tree -> child)) {
            // printf("%s nema child\n", tree -> node_data -> name);
            indent--;
        }
        if (print_tree(tree -> sibling)) {
            // printf("%s nema sibling\n", tree -> node_data -> name);
            indent--;
        }

        return 0;
    }
    return 1;
}

void free_tree(TREE_NODE *tree) {
    TREE_NODE *temp = tree -> child;

    while (temp) {

        if (temp -> node_data -> kind == FUN) {  
            free_tree(temp -> parameter);
        }

        free(temp -> node_data);
        
        if (temp -> child) {
            free_tree(temp -> child);
        }
        if (temp -> sibling) {
            free_tree(temp -> sibling);
        }
    }

    free(tree);
}
