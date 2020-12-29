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
    : init_program function_list
        {   
            // printf("%s\t\t", root -> child -> node_data -> name);
            // ovde sad nece biti ovo lookup symbol 
            // ici ce provera za tree, i da li u njemu postoji 'main'
            // printf("aaa\n\n");
            print_tree(root);
        }
    ;

init_program
    : INIT SEMICOLON
        {
            root = init_tree();
			printf("%s\n\n", root -> node_data -> name);
            /* 
                postoji zato sto moram zapoceti stablo, a pravilo program bi ga kreiralo na samom kraju dok ga ovo pravilo kreira na samom pocetku
                e sad, ovo resava problem za funkije, drugi problem je sa onim tokenima koje same funkcije sadrze?
             
             */
        }
    ;

function_list
    : function 
		{
			
		}
    | function_list function 
    ;

function 
    :   TYPE ID 
            {
				TREE_NODE *function = make_function(&root, $2, $1);
				// printf("%s\n\n", function -> node_data -> name);
                // printf("%s\t\t\n", function -> parent -> node_data -> name);
                // print_tree(root);
				// TODO: OVDE URADIM $ $ = make_function() ali moram izmeniti sta funkcija prima
				// MSM DA BI TO BIO NACIN DA SE OVO URADDI
            }
        LPAREN param_list 
            {

            }
        RPAREN body
            {

            }
    |   V_TYPE ID
            {

            }
        LPAREN param_list
            {

            }
        RPAREN body 
            {

            }
    ;

param_list 
    :   /*  */
            {

            }
    |   parameters
            {

            }
    ;

parameters
    :   parameter
    |   parameters COMMA parameter
    ;

parameter 
    :   TYPE ID
            {

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

            }
        variables SEMICOLON
    ;

variables 
    :   ID 
            {

            }
    |   variables COMMA ID
            {

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

            }
    |   RETURN SEMICOLON
            {

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

