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

    unsigned variable_type = NO_TYPE;

%}

%union {
  int i;
  char *s;
}

%token INIT

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
				// TODO: OVDE URADIM $ $ = make_function() ali moram izmeniti sta funkcija prima
				// MSM DA BI TO BIO NACIN DA SE OVO URADDI
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
        {
            // TODO: ovo pravilo je fucked int a, int b; moze sa ovim pravilom
        }
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
                // TODO: jedino sto vraca NULL u dva razlicita slucaja
                if (!variable) {
                    err("Greska, funckija %s vec ima deklarisan parametar/ variable sa imenom %s\n\n", current_function -> node_data -> name, $1);
                }
            }
    |   variables COMMA ID
            {
                TREE_NODE *variable = make_variable(&current_function, $3, variable_type);
                if (!variable) {
                    err("Greska, funckija %s vec ima deklarisan parametar/ variable sa imenom %s\n\n", current_function -> node_data -> name, $3);
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

        }
    ;

num_exp
    :   exp 
            {

            }
    |   num_exp AROP exp 
            {

            }
    ;

exp 
    :   literal 
    |   ID post_op
            {

            }
    |   function_call
            {

            }
    |   LPAREN num_exp RPAREN
            {

            }
    ;

post_op
    :   /*  */
    |   PINC
    |   PDEC
    ;

literal
    :   INT_NUMBER
            {

            }
    |   UINT_NUMBER
            {

            }
    ;

function_call
    :   ID
            {

            }
        LPAREN argument_s RPAREN
            {

            }
    ;

argument_s
    :   /*  */
    |   arguments
    ;

arguments 
    :   num_exp
            {

            }
    |   arguments COMMA num_exp 
            {

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

            }
    ;

loop_statement
    :   LOOP LPAREN ID COMMA literal COMMA literal loop_opt RPAREN statement
            {

            }
    ;

loop_opt
    :   /* optional */
    |   COMMA literal
    ;

jiro_statement
    :   JIRO
            {

            }
        LABRACKET jiro_exp RABRACKET LBRACKET tranga_body tranga_opt toreana_opt 
            {

            }
        RBRACKET
    ;

jiro_exp
    :   ID
            {

            }
    ;

tranga_body
    :   TRANGA literal
            {

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
                // if (current_function -> node_data -> type == )
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

