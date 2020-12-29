
#include "tree.h"

int indent = 0;

TREE_NODE *create_node(char *name, unsigned kind, unsigned type, TREE_NODE *parent, TREE_NODE *sibling) {
    TREE_NODE *node = (TREE_NODE *) malloc(sizeof(TREE_NODE));
    node -> node_data = (NODE_DATA *) malloc(sizeof(NODE_DATA));

    strcpy(node -> node_data -> name, name);
    node -> node_data -> kind = kind;
    node -> node_data -> type = type;
    node -> parent = parent;
    node -> sibling = sibling;
    node -> child = NULL;

    // if (kind == FUN) {
    //     printf("%s\n\n", parent -> node_data -> name);
    // }
    // if (kind == PAR || kind == VAR || kind == LIT) {
    //     // printf("%s\n\n", parent);

    //     printf("This parameter is for this function: %s\n\n", node -> parent -> node_data -> name);
    // }

    return node;
}

TREE_NODE* init_tree() {
    return create_node("program", NO_KIND, NO_TYPE, NULL, NULL);
}

TREE_NODE *make_function(TREE_NODE **tree, char* name, unsigned type) {
    TREE_NODE *function_root = NULL;
    // ako slucajno nije kreirao program
    if (!(*tree)) {
        printf("Greska, program nije zapocet\n\n");
        return NULL;
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
                    // moram da uvezem ono sto kreiram
                return function_root;
            }
        }
    }
}

TREE_NODE *make_parameter(TREE_NODE **function_node, char* param_name, unsigned type) {
    // to bi onda bilo to za ovu funkciju

    if (!(*function_node)) {
        printf("Greska, niste prosledili funckiju pri kreiranju parametra\n\n");
        return NULL;
    }

    TREE_NODE *temp = (*function_node) -> parameter;
    if (!temp) {
        temp = create_node(param_name, PAR, type, *function_node, NULL);
        (*function_node) -> parameter = temp; 

        return temp;
    }
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

unsigned print_tree(TREE_NODE *tree) {

    if (tree) {
        unsigned size = 0;
        size += 36;
        size += strlen(tree -> node_data -> name);
        size += 5;
        
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
        // printf("---------------------------------------------------------\n");
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
        // printf("---------------------------------------------------------\n");
        indent++;

        if (tree -> node_data -> kind == FUN) {
            if (print_tree(tree -> parameter)) {
                // printf("Funkcija %s nema parametre\n", tree -> node_data -> name);
            }
        }
        if (print_tree(tree -> child)) {
            // printf("%s nema child\n", tree -> node_data -> name);
            indent--;
        }
        if (print_tree(tree -> sibling)) {
            // printf("%s nema sibling\n", tree -> node_data -> name);
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


// int main() {

//     TREE_NODE *tree = init_tree();
//     print_tree(tree);

//     TREE_NODE *fun1 = make_function(&tree, "fun1", 1);

//     TREE_NODE *fun2 = make_function(&tree, "fun2", 1);

//     TREE_NODE *fun3 = make_function(&tree, "fun3", 1);

//     TREE_NODE *parameter1 = make_parameter(&fun1, "par1", 1);

//     TREE_NODE *fun4 = NULL;
//     TREE_NODE *parameter2 = make_parameter(&fun1, "par2", 1);

//     // printf("%s\n%s\n\n", fun1 -> parameter -> node_data -> name, fun1 -> parameter -> sibling -> node_data -> name);

//     TREE_NODE *p3 = make_parameter(&fun1, "par3", 1);
//     // printf("%s\n\n", fun1 -> parameter -> sibling -> sibling -> node_data -> name);


//     free_tree(tree);

//     return 0;

// }