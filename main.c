#include "tree.c"


int main() {

    printf("a\n\n");

    TREE_NODE *tree = init_tree(); 
    TREE_NODE *fun1 = make_function(&tree, "fun1", 1);
    TREE_NODE *fun2 = make_function(&tree, "fun2", 1);
    TREE_NODE *fun3 = make_function(&tree, "fun3", 1);
    TREE_NODE *parameter1 = make_parameter(&fun1, "par1", 1);
    TREE_NODE *fun4 = NULL;
    TREE_NODE *parameter2 = make_parameter(&fun1, "par2", 1);
    TREE_NODE *p3 = make_parameter(&fun1, "par3", 1);
    TREE_NODE *f4 = make_function(&tree, "fun4", 1);
    TREE_NODE *p4 = make_parameter(&f4, "par3", 1);
    // TREE_NODE *l1 = make_literal(&fun1, "lit1", 1);
    // TREE_NODE *l2 = make_literal(&fun1, "lit2", 1);
    // TREE_NODE *l3 = make_literal(&fun1, "lit3", 1);
    // TREE_NODE *l4 = make_literal(&fun1, "lit4", 1);
    // TREE_NODE *l5 = make_literal(&fun1, "1", 1);
    TREE_NODE *var1 = make_variable(&fun1, "var1", 1);

    printf("b\n\n");

    TREE_NODE *node = find_f(&tree, "fun4");
    // printf("%s\n\n", node -> node_data -> name);

    printf("%s\n\n", fun1 -> child -> node_data -> name);

    TREE_NODE *set = set_value(&fun1, "var1", 1);


    // printf("%s\n\n", fun1 -> child -> node_data -> name);

    // update_node(&fun1, "1", 2);



    // printf("%s\n%s\n\n", fun1 -> parameter -> node_data -> name, fun1 -> parameter ->sibling -> node_data -> name);
    // printf("%s\n\n", fun1 -> child -> node_data -> name);
    // TREE_NODE *find = find_node(&tree, "lit3");
    // TREE_NODE *find = find_node(&tree, "par2");
    // printf("%s\n\n", find -> node_data -> name);
    // printf("%s\n\n", fun1 -> parameter -> sibling -> sibling -> node_data -> name);

    // print_tree(tree);
    
    return 0;
}