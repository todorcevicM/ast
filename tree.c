
#include "tree.h"

int indent = 0;

// creates a node with name name, of kind kind and its type is type
// has a parent node parent and a sibling node sibling
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

// initialize tree
TREE_NODE* init_tree() {
    // initializes the root node
    // its a node with name program that doesnt have a kind or a type
    // its pointers to a parend and a child are NULL as it doesnt have either one
    return create_node("program", NO_KIND, NO_TYPE, NULL, NULL);
}

// creating the function node with name name and type type
// attaching it to tree
TREE_NODE *make_function(TREE_NODE **tree, char* name, unsigned type) {
    TREE_NODE *function_root = NULL;

    // if the tree doesnt exist, which it most definitely should but just in case
    if (!(*tree)) {
        (*tree) = init_tree();

        return make_function(tree, name, type);
    }
    // when the tree doesnt have a child and so this function is the only one 
    else if (!((*tree) -> child)) {
        function_root = create_node(name, FUN, type, *tree, NULL);
        // since the function node has been created now the root tree needs to have it as a child
        (*tree) -> child = function_root;

        return function_root;
    }
    // when a child already exist and so this function is not the first one
    else {
        TREE_NODE *temp = (*tree) -> child;
        TREE_NODE *last_sibling = NULL;

        // name check with the already existing function which the root node points to
        if (!strcmp(temp -> node_data -> name, name) && temp -> node_data -> kind == FUN) {
            printf("Error, function with the name: %s already exists\n\n", name);

            return NULL;
        }
        // the name is different from the first functions
        // now i need to check if there already exists a function with the same name but iterating through the functions siblings
        else {
            temp = temp -> sibling;

            if (!temp) {
                // doesnt have a sibling and so i can just create the function
                // its parent is also the tree, and it makes some actions easier, but it doesnt have a sibling
                function_root = create_node(name, FUN, type, *tree, NULL);
                (*tree) -> child -> sibling = function_root;

                return function_root;
            }
            else {
                // has a sibling
                // now i have to iterate to find the last sibling while name checking 
                while (temp) {
                    if (!strcmp(temp -> node_data -> name, name) && temp -> node_data -> kind == FUN) {
                        printf("Error, function with the name: %s already exists\n\n", name);

                        return NULL;
                    }
                    // then last_sibling becomes the current temp
                    last_sibling = temp;
                    // and if there is no next sibling the last_sibling node gets a sibling that is the node in the making
                    temp = temp -> sibling;
                }
                // finished iterating through the siblings
                function_root = create_node(name, FUN, type, *tree, NULL);
                last_sibling -> sibling = function_root;

                return function_root;
            }
        }
    }
}

// creating functions parameters
TREE_NODE *make_parameter(TREE_NODE **function_node, char* param_name, unsigned type) {

    // check if there exists a function to which im trying to attach the parameters
    // this will probably never get triggered but again just a check
    if (!(*function_node)) {
        printf("Error, no such function exists\n\n");

        return NULL;
    }

    TREE_NODE *temp = (*function_node) -> parameter;
    // check if the function already has parameters
    if (!temp) {
        // the function has no parameters
        temp = create_node(param_name, PAR, type, *function_node, NULL);
        // after creating the parameter node it needs to be attached to the functions parameters list
        (*function_node) -> parameter = temp; 

        return temp;
    }
    else {
        // the function has parameters
        // iterating through the existing parameters and name checking
        while (temp) {
            if (!strcmp(temp -> node_data -> name, param_name)) {
                printf("Error, parameter: %s already exists as a parameter of function: %s\n\n", param_name, (*function_node) -> node_data -> name);

                return NULL;
            }
            // if the current parameter has no sibling it can make it 
            if (!(temp -> sibling)) {
                TREE_NODE *new_parameter = create_node(param_name, PAR, type, *function_node, NULL);
                // also the temp node (current parameter) gets a new sibling the new_paramter node
                temp -> sibling = new_parameter;

                return new_parameter;
            }
            temp = temp -> sibling;
        } 
    }
}

// creating variables
// made so i can send the root of the tree as well for global variables
TREE_NODE *make_variable(TREE_NODE **tree, char *name, unsigned type) {
    
    if (!(*tree)) {
        // does the tree/ function exist
        printf("Error, function: %s does not exist\n\n", (*tree) -> node_data -> name);

        return NULL;
    }
    // prvo provera imena sa parametrima koje funkcija prima
    // first i need to name check the functions parameters
    TREE_NODE *parameter = (*tree) -> parameter;
    while (parameter) {
        if (!strcmp(parameter -> node_data -> name, name)) {
            printf("Error, function: %s has a parameter named: %s\n\n", (*tree) -> node_data -> name, name);

            return NULL;
        }
        parameter = parameter -> sibling;
    }
    // no parameters with the same name found
    // i can now name check the functions children
    TREE_NODE *temp = (*tree) -> child;
    TREE_NODE *last_sibling = NULL;
    if (!temp) {
        // has no child
        TREE_NODE *variable = create_node(name, VAR, type, *tree, NULL);
        (*tree) -> child = variable;

        return variable;
    }
    else {
        // has a child and so need to name check
        while (temp) {
            if (!strcmp(temp -> node_data -> name, name)) {
                printf("Error, function: %s already has a variable named: %s\n\n", temp -> parent -> node_data -> name, name);

                return NULL;
            }
            last_sibling = temp;
            temp = temp -> sibling;
        }
        // found the last sibling
        TREE_NODE *variable = create_node(name, VAR, type, *tree, NULL);
        last_sibling -> sibling = variable;

        return variable;
    }
}

// creating literals
TREE_NODE *make_literal(TREE_NODE **tree, char *name, unsigned type) {
    TREE_NODE *temp = (*tree) -> child;
    TREE_NODE *last_sibling = NULL;

    if (!temp) {
        // has no child
        TREE_NODE *literal = create_node(name, LIT, type, *tree, NULL);
        (*tree) -> child = literal;

        return literal;
    }
    else {
        // has a child
        while (temp) {
            last_sibling = temp;
            temp = temp -> sibling;
        }
        // found the last sibling
        TREE_NODE *literal = create_node(name, LIT, type, *tree, NULL);
        last_sibling -> sibling = literal;

        return literal;
    }
}

// fining a node
TREE_NODE *find_node(TREE_NODE **root, char *name) {
    TREE_NODE *temp = NULL;

    // root is either the actual root or is a function
    if (!strcmp((*root) -> node_data -> name, name)) {
        return *root;
    }
    // if its a function i need to check its parameters
    if ((*root) -> node_data -> kind == FUN) {
        temp = find_node(&((*root) -> parameter), name);
        if (temp) {
            // if its not NULL its been found and can be returned, and in this case its a function parameter
            return temp;
        }
    }
    if ((*root) -> child) {
        temp = find_node(&((*root) -> child), name);
        if (temp) {
            // if its not NULL its been found and can be returned, and in this case its a something
            return temp;
        }
    }
    if ((*root) -> sibling) {
        temp = find_node(&((*root) -> sibling), name);
        if (temp) {
            // if its not NULL its been found and can be returned, and in this case its a something
            return temp;
        }
    }
    // hasnt found any node that has the name name
    return NULL;
}

// finding functions
// i dont really know why i made this function when theres a find node up above
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
// also no idea why this exists 
TREE_NODE *find_f(TREE_NODE **root, char *name) {
    if ((*root) -> child) {
        return find_function(&((*root) -> child), name);
    }
}

// TODO:

// updating nodes, mostly for updating literals and values of parameters and variables 
TREE_NODE *update_node(TREE_NODE **root, char *name, unsigned update_type) {
    // finding the node which is to be updated
    TREE_NODE *temp = find_node(root, name);
    int type = temp -> node_data -> type;
    temp = temp -> child;
    int i;
    char *s = malloc(sizeof(char *));

    if (type == INT) {
        if (update_type == 1) {
            temp -> node_data -> value -> i++;
            i = atoi(temp -> node_data -> name);
            i++;
            sprintf(s, "%d", i);
            strcpy(temp -> node_data -> name, s);
        }
        else if (update_type == 2) {
            temp -> node_data -> value -> i--;
            i = atoi(temp -> node_data -> name);
            i--;
            sprintf(s, "%d", i);
            strcpy(temp -> node_data -> name, s);
        }
    }
    else if (type == UINT) {
        if (update_type == 1) {
            temp -> node_data -> value -> u++;
            i = atoi(temp -> node_data -> name);
            i++;
            sprintf(s, "%d", i);
            strcpy(temp -> node_data -> name, s);
        }
        else if (update_type == 2) {
            temp -> node_data -> value -> u--;
            i = atoi(temp -> node_data -> name);
            i--;
            if (i < 0) {
                printf("Greska, unsigned vrednost ne moze biti manja od 0\n\n");
                return NULL;
            }
            sprintf(s, "%d", i);
            strcpy(temp -> node_data -> name, s);
        }
    }

    return temp;
}

TREE_NODE *update_value(TREE_NODE **variable, int value_i, unsigned value_u, unsigned literal_type) {
    TREE_NODE *temp = (*variable) -> child;
    int i;
    char *s = malloc(sizeof(char *));

    if (temp) {
        if (literal_type == INT) {
            (*variable) -> node_data -> value -> i = value_i;
            sprintf(s, "%d", value_i);
            strcpy(temp -> node_data -> name, s);
        }
        else if (literal_type == UINT) {
            (*variable) -> node_data -> value -> u = value_u;
            sprintf(s, "%d", value_u);
            strcpy(temp -> node_data -> name, s);
        }
    }
} 

TREE_NODE *set_value(TREE_NODE **tree, int value) {

    (*tree) -> node_data -> value = malloc(sizeof(VALUE));
    (*tree) -> node_data -> value -> i = value;

    char *s;
    sprintf(s, "%d", value);
    TREE_NODE *literal = find_node(&((*tree) -> parent), s);

    return update_literal_parent(tree, &literal);
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

TREE_NODE *get_sibling(TREE_NODE **tree, TREE_NODE **is_sibling) {
    TREE_NODE *temp = (*tree) -> child -> sibling;
    TREE_NODE *temp1 = (*tree) -> child;

    while (temp) {
        if (!strcmp(temp -> node_data -> name, (*is_sibling) -> node_data -> name)) {
            return temp1;
        }

        temp = temp -> sibling;
        temp1 = temp1 -> sibling;
    }  
}

TREE_NODE *make_arop(TREE_NODE **tree, TREE_NODE **exp1, TREE_NODE **exp2, int arop) {
    char *s = get_arop(arop);
    
    printf("%s\n\n", s);

    TREE_NODE *sibling = get_sibling(tree, exp1);
    TREE_NODE *arop_node = create_node(s, NO_KIND, NO_TYPE, NULL, NULL);

    printf("%s\n\n", sibling -> node_data -> name);
    printf("%s\n\n", sibling -> sibling -> node_data -> name);
    printf("%s\n\n", sibling -> sibling -> sibling -> node_data -> name);
    arop_node -> child = *exp1;
    printf("aaaaaaaa%s\n\n", arop_node -> child -> node_data -> name);

    sibling -> child = arop_node;
    printf("%s\n\n", sibling -> child -> node_data -> name);
    // printf("%s\n\n", sibling -> child -> sibling -> node_data -> name);
    sibling -> sibling = NULL;

    // sibling -> child = arop_node;
    // arop_node -> parent = sibling;
    // printf("%s\n\n", sibling -> child -> node_data -> name);

    arop_node -> node_data -> value = malloc(sizeof(VALUE *));

    if ((*exp1) -> node_data -> type == (*exp2) -> node_data -> type) {
        if ((*exp1) -> node_data -> type == INT) {
            arop_node -> node_data -> value -> i = atoi((*exp1) -> node_data -> name) + atoi((*exp2) -> node_data -> name);
        }
        else if ((*exp1) -> node_data -> type == UINT) {
            arop_node -> node_data -> value -> u = atoi((*exp1) -> node_data -> name) + atoi((*exp2) -> node_data -> name);
        }
    }
    else {
        printf("Greska, izrazi se ne razlikuju po tipu\n\n");
        return NULL;
    }
    printf("%d\n\n", arop_node -> node_data -> value -> i);
    sibling -> node_data -> value = malloc(sizeof(VALUE *));
    sibling -> node_data -> value -> i = arop_node -> node_data -> value -> i;

    // update_literal_parent(&arop_node, exp1);

    // printf("aaaaaaaaaaaaaaaaaaa%s\n\n", sibling -> child -> node_data -> name);
    // printf("%s\n\n", (*exp1) -> node_data -> name);
    // printf("Aa");



}

char* get_arop(int a) {
    char *s;

    switch (a) {
        case ADD: s = "+"; break;
        case SUB: s = "-"; break;
        case MUL: s = "*"; break;
        case DIV: s = "/"; break;
        case MIV: s = "%"; break;
        default: s = ""; break;
    }

    return s;
}

unsigned print_tree(TREE_NODE *tree) {

    if (tree) {
        unsigned size = 0;
        // char *type_s;
        // char *kind_s;
        // char *s;
        // s = "";
        // printf("%s", s);
        // sprintf(type_s, "%d", tree -> node_data -> type);
        // sprintf(kind_s, "%d", tree -> node_data -> kind);
        // printf("%s%s", type_s, kind_s);

        // strcat(s, "|Node name: ");
        // strcat(s, tree -> node_data -> name);
        // strcat(s, "; Node type: ");
        // strcat(s, type);
        // strcat(s, "; Node kind: ");
        // strcat(s, kind);
        // strcat(s, "|\n");

        // int size_s = strlen(s);

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
        // printf("%s", s);
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
