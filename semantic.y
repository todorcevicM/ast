%{
  #include <stdio.h>
  #include <stdlib.h>
  #include "defs.h"
  #include "symtab.h"
  #include "tree.h"

  int yyparse(void);
  int yylex(void);
  int yyerror(char *s);
  void warning(char *s);

  extern int yylineno;
  char char_buffer[CHAR_BUFFER_LENGTH];
  int error_count = 0;
  int warning_count = 0;
  int var_num = 0;
  int fun_idx = -1;
  int fcall_idx = -1;


    TREE_NODE *root;
    TREE_NODE *current_function;
    TREE_NODE *current_variable;
    TREE_NODE *current_literal;

    TREE_NODE *update;

    unsigned variable_type = NO_TYPE;
    unsigned post_operator = 0;
    unsigned literal_type = NO_TYPE;
    unsigned assign_type = 0;
    unsigned assign_exp = 0;
    unsigned post_op_op_var = -1;
    

%}

%union {
  int i;
  char *s;
}

%token <i> TYPE
%token <i> V_TYPE 

%token <s> ID 
%token <s> INT_NUMBER 
%token <s> UINT_NUMBER

%token IF 
%token ELSE 
%token RETURN 

%token LOOP 

%token JIRO 
%token TRANGA 
%token TOREANA 
%token FINISH 
%token LABRACKET 
%token RABRACKET 
%token DO 

%token SEMICOLON 
%token COMMA 

%token LPAREN 
%token RPAREN 
%token LBRACKET 
%token RBRACKET 
%token ASSIGN 

%token <i> AROP 
%token PINC 
%token PDEC
%token <i> RELOP 

%type <i> num_exp exp literal function_call arguments rel_exp 

%nonassoc ONLY_IF
%nonassoc ELSE

%%


program
    : function_list
        {
            print_tree(root);
        }
    ;

function_list
    : function 
    | function_list function 
    ;

function 
    :   TYPE ID 
            {   
				TREE_NODE *function = make_function(&root, $2, $1);
                if (!function) {
                    err("Greska, funckija sa imenom %s vec postoji\n\n", $2);
                }
                else {
                    current_function = function;
                }
            }
        LPAREN param_list RPAREN body
    |   V_TYPE ID
            {
                TREE_NODE *function = make_function(&root, $2, $1);
                if (!function) {
                    err("Greska, funckija sa imenom %s vec postoji\n\n", $2);
                }
                else {
                    current_function = function;
                }
            }
        LPAREN param_list RPAREN body 
    ;

param_list 
    :   /*  */ 
    |   parameters
    ;

parameters
    :   parameter
    |   parameters COMMA parameter 
    ;

parameter 
    :   TYPE ID
            {
                TREE_NODE *parameter = make_parameter(&current_function, $2, $1);
                if (!parameter) {
                    err("Parametar %s vec postoji kao parametar koji funckija %s prima\n\n", $2, current_function -> node_data -> name);
                }
            }
    ;

body 
    :   LBRACKET variable_list statement_list RBRACKET
    ;

variable_list
    :   /*  */
    |   variable_list variable
    ;

variable 
    :   TYPE 
            {
                variable_type = $1;
            }
        variables SEMICOLON
    ;

variables 
    :   ID 
            {
                TREE_NODE *variable = make_variable(&current_function, $1, variable_type);
                // TODO: ako uradim ovako onda nemam mogucnost za globalne za sad
                if (!variable) {
                    err("Greska, funckija %s vec ima deklarisan parametar/ variable sa imenom %s\n\n", current_function -> node_data -> name, $1);
                }
                else {
                    current_variable = variable;
                    // printf("%s\n\n", current_variable -> node_data -> name);
                }
            }
    |   variables COMMA ID
            {
                TREE_NODE *variable = make_variable(&current_function, $3, variable_type);
                if (!variable) {
                    err("Greska, funckija %s vec ima deklarisan parametar/ variable sa imenom %s\n\n", current_function -> node_data -> name, $3);
                }
                else {
                    current_variable = variable;
                }
            }
    ;

statement_list
    :   /*  */
    |   statements
    ;

statements
    :   statement 
    |   statements statement 
    ;

statement 
    :   compound_statement
    |   assignment_statement
    |   function_call SEMICOLON
    |   ID post_op 
            {
                if (post_operator) {
                    current_variable = update_node(&current_function, $1, post_operator);
                    if (!current_variable) {
                        err("Greska, unsigned vrednost ne moze biti manja od 0\n\n");
                    }
                }
            }
            SEMICOLON
    |   if_statement
    |   loop_statement
    |   jiro_statement
    |   return_statement
    ;

compound_statement
    :   LBRACKET statement_list RBRACKET
    ;

assignment_statement
    : ID ASSIGN num_exp SEMICOLON
        {   
            if (assign_exp != 1) {
                current_variable = find_node(&current_function, $1);
                set_value(&current_variable, $3);
            }
            else if (assign_exp == 1) {
                current_variable = find_node(&current_function, $1);
                update_value(&current_variable, $3, $3, literal_type);
            }
        }
    ;

num_exp
    :   exp 
            {
                assign_type = 1;
                $$ = $1;
            }
    |   num_exp 
            {
                // printf("aa");

            }
            AROP 
                {
                    printf("%d\n\n", AROP);
                    switch (AROP) {
                        case 0: printf("+\n\n"); break;
                        case 1: printf("-"); break;
                        case 2: printf("*"); break;
                        case 3: printf("/"); break;
                        case 4: printf("a"); break;

                        default : printf("kita");
                    }
                }
            exp 
                {   
                    assign_type = 2;
                    // TODO: 
                    // test(i);
                }
    ;

exp 
    :   literal 
    |   ID post_op_op
            {   
                if (post_op_op_var) {
                    current_variable = update_node(&current_function, $1, post_operator); 
                }
                else {
                    current_variable = find_node(&current_function, $1);
                }
                assign_exp = 1;
                if (current_variable -> node_data -> type == INT) {
                    $$ = current_variable -> node_data -> value -> i; 
                }
                else if (current_variable -> node_data -> type == UINT) {
                    $$ = current_variable -> node_data -> value -> u; 
                }
            }
    |   function_call
            {
                // TODO: 
            }
    |   LPAREN num_exp RPAREN
            {
                // TODO: 
            }
    ;

post_op
    :   PINC
            {
                post_operator = 1;
            }
    |   PDEC
            {
                post_operator = 2;
            }
    ;

post_op_op
    :   
        {
            post_op_op_var = 0;
        }
    |   post_op
        {
            post_op_op_var = post_operator;
        }
    ;

literal
    :   INT_NUMBER
            {
                current_literal = make_literal(&current_function, $1, 1);
                literal_type = 1;
                $$ = atoi(current_literal -> node_data -> name);
            }
    |   UINT_NUMBER
            {
                current_literal = make_literal(&current_function, $1, 2);
                literal_type = 2;
                $$ = atoi(current_literal -> node_data -> name);
            }
    ;

function_call
    :   ID
            {
                // TODO: 
                TREE_NODE *function = find_f(&root, $1);
                if (!function) {
                    err("Greska, funkcija %s nije pronadjena\n\n", $1);
                }
            }
        LPAREN argument_s RPAREN
            {
                // TODO: 
            }
    ;

argument_s
    :   /*  */
    |   arguments
    ;

arguments 
    :   num_exp
            {
                // TODO: 
            }
    |   arguments COMMA num_exp 
            {
                // TODO: 
            }
    ;

if_statement
    :   if_part %prec ONLY_IF
    |   if_part ELSE statement
    ;

if_part
    :   IF LPAREN rel_exp RPAREN statement
    ;

rel_exp
    :   num_exp RELOP num_exp
            {
                // TODO: 
            }
    ;

loop_statement
    :   LOOP LPAREN ID COMMA literal COMMA literal loop_opt RPAREN statement
            {
                // TODO: 
            }
    ;

loop_opt
    :   /* optional */
    |   COMMA literal
    ;

jiro_statement
    :   JIRO
            {
                // TODO: 
            }
        LABRACKET jiro_exp RABRACKET LBRACKET tranga_body tranga_opt toreana_opt 
            {
                // TODO: 

            }
        RBRACKET
    ;

jiro_exp
    :   ID
            {
                // TODO: 

            }
    ;

tranga_body
    :   TRANGA literal
            {
                // TODO: 

            }
        DO statement finish_opt
    ;

finish_opt
    :   /* optional */
    |   FINISH SEMICOLON
    ;

tranga_opt
    :   /* optional */
    |   tranga_body tranga_opt
    ;

toreana_opt
    :   /* optional */
    |   TOREANA DO statement
    ;

return_statement
    :   RETURN num_exp SEMICOLON
            {
                // TODO: 
                // if (current_function -> type != )
            }
    |   RETURN SEMICOLON
            {
                if (current_function -> node_data -> type != VOID) {
                    warn("Int/Uint function is without number expression in the return statement");
                }
            }
    ;

%%

int yyerror(char *s) {
  fprintf(stderr, "\nline %d: ERROR: %s", yylineno, s);
  error_count++;
  return 0;
}

void warning(char *s) {
  fprintf(stderr, "\nline %d: WARNING: %s", yylineno, s);
  warning_count++;
}

int main() {
  int synerr;
  init_symtab();

  synerr = yyparse();

  clear_symtab();
  
  if(warning_count)
    printf("\n%d warning(s).\n", warning_count);

  if(error_count)
    printf("\n%d error(s).\n", error_count);

  if(synerr)
    return -1; //syntax error
  else
    return error_count; //semantic errors
}

