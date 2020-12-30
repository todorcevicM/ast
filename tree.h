
#ifndef TREE_H
#define TREE_H

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "defs.h"

#define NODE_NAME_BUFFER 16

typedef struct val {
    // char name[NODE_NAME_BUFFER];
    // MA NE PADA MI NAPAMET DA MENJAM SAD DA MI OVO BUDE OVAKO
    int i;
    unsigned u;
} VALUE;

typedef struct node_data {
    char name[NODE_NAME_BUFFER];
    unsigned kind;
    unsigned type;
    VALUE *value;
} NODE_DATA;

typedef struct tree_node {
    NODE_DATA *node_data;

    struct tree_node *parameter;
        // sibling od parameter ce biti sledeci parametar koji funckija zahteva, nece imati child 
    struct tree_node *parent;

    struct tree_node *child;
        // znaci svaki cvor ce tehnicki imati jedan podcvor, dok ce taj podcvor imati pokazivac na sibling cvora koji ce biti na istom nivou kao i taj sam
    struct tree_node *sibling;
        // moguc, ali nije obavezan za svaki cvor
} TREE_NODE;

TREE_NODE *create_node(char *name, unsigned kind, unsigned type, TREE_NODE *parent, TREE_NODE *sibling);
TREE_NODE *init_tree();
TREE_NODE *make_function(TREE_NODE **tree, char *name, unsigned type);
TREE_NODE *make_parameter(TREE_NODE **function_node, char *name, unsigned type);
TREE_NODE *make_variable(TREE_NODE **tree, char *name, unsigned type);
TREE_NODE *make_literal(TREE_NODE **tree, char  *name, unsigned type);
TREE_NODE *find_node(TREE_NODE **root, char *name);
TREE_NODE *update_node(TREE_NODE **root, char *name, unsigned update_type);

unsigned print_tree(TREE_NODE *tree);
void free_tree(TREE_NODE *tree);


#endif