#include "tree.c"


int main() {

    TREE_NODE *tree = init_tree();

    TREE_NODE *fun1 = make_function(&tree, "fun1", 1);

    TREE_NODE *fun2 = make_function(&tree, "fun2", 1);

    // printf("e\n\n");
    TREE_NODE *fun3 = make_function(&tree, "fun3", 1);

    TREE_NODE *parameter1 = make_parameter(&fun1, "par1", 1);

    TREE_NODE *fun4 = NULL;
    TREE_NODE *parameter2 = make_parameter(&fun1, "par2", 1);

    // printf("%s\n%s\n\n", fun1 -> parameter -> node_data -> name, fun1 -> parameter ->sibling -> node_data -> name);

    TREE_NODE *p3 = make_parameter(&fun1, "par3", 1);
    TREE_NODE *f4 = make_function(&tree, "fun4", 1);
    TREE_NODE *p4 = make_parameter(&f4, "par3", 1);
    // TREE_NODE *f5 = make_function(&tree, "fun4", 1);
    // TREE_NODE *p5 = make_parameter(&f4, "par3", 1);
    print_tree(tree);
    // printf("%s\n\n", fun1 -> parameter -> sibling -> sibling -> node_data -> name);

    // printf("f\n\n");

    // free_tree(tree);
    // printf("a");

    return 0;

}