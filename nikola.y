%{
  #include <stdio.h>
  #include <stdlib.h>
  #include "defs.h"
  #include "symtab.h"
  #include "codegen.h"

  int yyparse(void);
  int yylex(void);
  int yyerror(char *s);
  void warning(char *s);

  extern int yylineno;
  int out_lin = 0;
  char char_buffer[CHAR_BUFFER_LENGTH];
  int error_count = 0;
  int warning_count = 0;
  int var_num = 0;
  int fun_idx = -1;
  int lab_num = -1;
  FILE *output;

  int rf = 0; //return fleg
  int vartype = 0; //kod variabli
  int brojP = 0;
  int trnFun = 0;
  int jiro_counter = 0;
  int jiro_type = -1;
  int para_counter = 0;
  int jiro_id_idx = -1;
  int tranga_counter = 0;
  int conditional_counter = 0;
  //pozivanje funkcije
  int param_na_redu = 0;
  int pozvana_funkcija = 0;

  //inkrement promenljive
  int postInc[20] = {-1};
  int post_inc_count = 0;
  int isAssignIncl = 0;
  int isAssignIdx = -1;

  //FIR sistem pomocne
  int inputs[20] = {-1};
  int inputs_pointer = 0;
  int outputs[20] = {-1};
  int outputs_pointer = 0; 
  int isSystem = 0;
  int system_counter = 0;

  //parametri dorada, "obrnuti redosled"
  int func_param[20] = {-1};
  int param_pointer = 0;
  //dodavanje propadanja
  int toeranas_extra = -1;
  //dodavanje konstanti
  int buduce_konstante[20] = {-1};
  int buduce_konstante_pointer = 0;
  int konstante[20] = {-1};
  int konstante_pointer = 0;
  int odVarijable = 0;
%}

%union {
  int i;
  char *s;
}

%token <i> _TYPE
%token _IF
%token _ELSE
%token _RETURN
%token <s> _ID
%token <s> _INT_NUMBER
%token <s> _UINT_NUMBER
%token _LPAREN
%token _RPAREN
%token _LBRACKET
%token _RBRACKET
%token _ASSIGN
%token _SEMICOLON
%token <i> _AROP
%token <i> _AROP2
%token <i> _RELOP

%token <i> _FTYPE
%token _COMMA
%token _INC
%token _PARA
%token _A
%token _TWODOTS
%token _QUESTIONMARK

%token _JIRO
%token _TRANGA
%token _TOERANA
%token _END_JIRO
%token _FINISH

%token _SYSTEM
%token _STIMULUS
%token _GATE
%token _RESPONSE

%token _CONST

%type <i> fun_call arg_for_fun arg_exist cond_exp conditional
%type <i> num_exp num_exp2  exp literal post_inc finish potential_const
%type <i> rel_exp if_part

%nonassoc ONLY_IF
%nonassoc _ELSE

%%

program
  : global_list function_list
      {  
        if(lookup_symbol("main", FUN) == NO_INDEX)
          err("undefined reference to 'main'");
      }
  ;


global_list
  : /**/
  | global_list glob
	;

glob
  : global_var
  | system 
  ;
//FIR sistem dodatak
system
  : _SYSTEM
    { 
      isSystem = 1; 
      system_counter++;
    }
  _LBRACKET input_list output_list gate_list _RBRACKET
    { isSystem = 0; }
  ;

//globalni inputi
input_list
  : 
  | input_list input
  ;
input
  : _STIMULUS _ID
      {
        if(system_counter > 1)
          err("stimuli and responses can only be def in 1st system call!");
        int idx = lookup_symbol($2, GVAR);
        if(idx == NO_INDEX){
          inputs[inputs_pointer] = insert_symbol($2, GVAR, 1, ++var_num, -1); 
          inputs_pointer++;
          code("\n%s:\n\t\tWORD\t1", $2);

        }else{
          err("Redef of global %s \n", get_name(idx));
        }
      }
   _SEMICOLON
  ;
//globalni outputi
output_list 
  : 
  | output_list output
  ;

output
  : _RESPONSE _ID
      {
        if(system_counter > 1)
          err("io var can only be def in 1st system call!");
        int idx = lookup_symbol($2, GVAR);
        if(idx == NO_INDEX){
          outputs[outputs_pointer] = insert_symbol($2, GVAR, 1, ++var_num, -1); 
          outputs_pointer++;
          code("\n%s:\n\t\tWORD\t1", $2);
        }else{
          err("Redef of global %s \n", get_name(idx));
        }
      }
   _SEMICOLON
  ;
//globalne kapije
gate_list
  : 
  | gate_list gate
  ;

gate
  : _GATE _ID 
    {
      int gate_idx = lookup_symbol($2, FUN);
      if(gate_idx == NO_INDEX){ 
        gate_idx = insert_symbol($2, FUN, NO_ATR, NO_ATR, NO_ATR);
        fun_idx = gate_idx;
      }
      else 
          err("redefinition of gate! '%s'", $2);
      code("\n%s:", $2);
      code("\n\t\tPUSH\t%%14");
      code("\n\t\tMOV \t%%15,%%14");
    }
  _LBRACKET gate_rules _RBRACKET
    {
        clear_symbols(fun_idx +1);
        code("\n@%s_exit:", $2);
        code("\n\t\tMOV \t%%14,%%15");
        code("\n\t\tPOP \t%%14");
        code("\n\t\tRET");
    }
  ;

gate_rules
  : 
  | gate_rules gate_rule;
  ;

gate_rule
  : assignment_statement
  ;
/////////////////////////////////
global_var
	: _TYPE _ID _SEMICOLON
	{
		int idx = lookup_symbol($2, GVAR); 
		if (idx != NO_INDEX) 
		{
				err("redefinition of '%s'", $2);
		} else {
			insert_symbol($2, GVAR, $1, NO_ATR, NO_ATR);
			code("\n%s:\n\t\tWORD\t1", $2);
		}
	}
  ;


function_list
  : function
  | function_list function
  ;

function
  : _TYPE _ID
      {
        
        fun_idx = lookup_symbol($2, FUN);
        if(fun_idx == NO_INDEX){
          fun_idx = insert_symbol($2, FUN, $1, NO_ATR, NO_ATR);
          trnFun = fun_idx;
        }
        else 
          err("redefinition of function '%s'", $2);

        code("\n%s:", $2);
        code("\n\t\tPUSH\t%%14");
        code("\n\t\tMOV \t%%15,%%14");
      }
    _LPAREN param_list
    {
      set_atr1(fun_idx, brojP);
    }
     _RPAREN body
      {
        
        clear_symbols(fun_idx + brojP +1);
        var_num = 0;
        if(!rf)
          warn("no ret");
        rf = 0;
         brojP = 0;

        code("\n@%s_exit:", $2);
        code("\n\t\tMOV \t%%14,%%15");
        code("\n\t\tPOP \t%%14");
        code("\n\t\tRET");

      }
  | _FTYPE _ID
      {
        fun_idx = lookup_symbol($2, FUN);
        if(fun_idx == NO_INDEX){
          fun_idx = insert_symbol($2, FUN, $1, NO_ATR, NO_ATR);
          trnFun = fun_idx;
        } 
        else 
          err("redefinition of function! '%s'", $2);
        code("\n%s:", $2);
        code("\n\t\tPUSH\t%%14");
        code("\n\t\tMOV \t%%15,%%14");
      }
    _LPAREN param_list 
    {
      set_atr1(fun_idx, brojP);
    }
    _RPAREN body
      {
        //cuvanje parametara u tabeli simbola
        clear_symbols(fun_idx + brojP +1);
        var_num = 0;
        rf = 0;
        brojP = 0;
        code("\n@%s_exit:", $2);
        code("\n\t\tMOV \t%%14,%%15");
        code("\n\t\tPOP \t%%14");
        code("\n\t\tRET");
      }
  ;
  

param_list
  : /* empty */
      { set_atr1(fun_idx, 0); }
  | param_multi
  ;

param_multi
  : parameter
  | param_multi _COMMA parameter
  ;

parameter
  : _TYPE _ID
      {
         brojP++;
        if((lookup_symbol($2,PAR)!=NO_INDEX) && (lookup_symbol($2,PAR)>trnFun)){
          err("redefinition of param '%s'", $2);
        }
        if((lookup_symbol($2,GVAR)!=NO_INDEX)){
          err("reuse of global id '%s'", $2);
        }
        insert_symbol($2, PAR, $1, brojP, fun_idx);
      }
  |_FTYPE _ID
  { err("Ne moze void za parametre"); }    
  ;

body
  : _LBRACKET variable_list
      {
        if(var_num)
          code("\n\t\tSUBS\t%%15,$%d,%%15", 4*var_num);
        code("\n@%s_body:", get_name(fun_idx));
      }
    statement_list _RBRACKET
  ;

variable_list
  : /* empty */
  | variable_list variable
  ;

variable
  : potential_const _TYPE 
  { vartype = $2; }
  ids _SEMICOLON
  {
    if($1){
      for(int i = trnFun + odVarijable ; i < trnFun + var_num + 1; i++){
        printf("\n%s", get_name(i));
        buduce_konstante[buduce_konstante_pointer++] = i;
      } 
    }
  }
  | _FTYPE ids _SEMICOLON
  { err("Ne moze void za varijable"); }
  ;

potential_const
  : { $$ = 0; }
  | _CONST
    { $$ = 1;
      odVarijable = var_num + 1;
    }
  ;

ids
  : _ID
    {
        
        int idx = lookup_symbol($1, FUN);
        if(idx != NO_INDEX)
          err("Name '%s' taken by FUN", $1);
        idx = lookup_symbol($1, VAR|PAR|GVAR);
        if(idx == NO_INDEX)
           insert_symbol($1, VAR, vartype, ++var_num, trnFun);
        else if(trnFun == get_atr2(idx))
           err("redefinition of '%s' ", $1);
        else 
           insert_symbol($1, VAR, vartype, ++var_num, trnFun);
        

    }
  | ids _COMMA _ID
    {

      int idx = lookup_symbol($3, FUN);
      if(idx != NO_INDEX)
        err("Name '%s' taken by FUN", $3);
      idx = lookup_symbol($3, VAR|GVAR);
      if(idx == NO_INDEX)
           insert_symbol($3, VAR, vartype, ++var_num, trnFun);
        else 
           err("redefinition of '%s' ", $3);
           
    }
  ;

statement_list
  : /* empty */
  | statement_list statement
  ;

statement
  : fun_call _SEMICOLON
  | jiro_statement
  | para_statement
  | compound_statement
  | assignment_statement
  | if_statement
  | return_statement
  | _ID _INC _SEMICOLON
  {
    int idx = lookup_symbol($1, VAR|PAR|GVAR);
    if(idx == NO_INDEX)
      err("invalid lvalue '%s' in assignment", $1);
    //provera konstanti
    int error = 0;
    for(int i = 0; i < buduce_konstante_pointer; i++)
      if(idx == buduce_konstante[i])
        error = 1;
    for(int i = 0; i < konstante_pointer; i++)
      if(idx == konstante[i])
        error = 1;
    if(error)
      err("Const can not be ++ed");


    int t1 = get_type(idx);
    code("\n\t\t%s\t", ar_instructions[(t1 - 1) * AROP_NUMBER]);
    gen_sym_name(idx);
    code(",$1,");
    gen_sym_name(idx);
    set_type(idx, t1);
  } 
  ;

jiro_statement
  : _JIRO _ID 
  {
    jiro_counter++;
    code("\n@jiro_%d_start:", jiro_counter);
    jiro_id_idx = lookup_symbol($2, VAR|PAR|GVAR);
    if(jiro_id_idx == NO_INDEX) //da li je var def
      err("not def'%s'", $2);
    jiro_type = get_type(jiro_id_idx);
    tranga_counter = 0;
  }
  trangas 
  {
    code("\n\t\tJMP\t@toerana_%d_start", jiro_counter);

    code("\n@tranga_%d_%d_start:", jiro_counter, toeranas_extra);
    code("\n\t\tJMP\t@jiro_%d_exit", jiro_counter);
    code("\n@toerana_%d_start:", jiro_counter);

  } 
  toerana_opt _END_JIRO
  {
    code("\n@jiro_%d_exit:", jiro_counter);
  }
  ;

toerana_opt
  : {/*prazno*/}
  | _TOERANA 
  {

  }
  statement
  ;
 
trangas
  : _TRANGA literal
  {
    int i = lookup_symbol(get_name($2), LIT);
           if (i != NO_INDEX) {
               if (get_atr2(i) == jiro_counter)
                   err("literal already inside of jiro expression");
               else 
                   set_atr2(i, jiro_counter);
           }
    if(get_type(i)!= jiro_type)
        err("not a good jito type, type<ID> != type<literal>");
    $<i>$ = tranga_counter++;
    gen_cmp(jiro_id_idx, i);
    //jump not eq
    code("\n\t\t%s\t@tranga_%d_%d_exit", jumps[5], jiro_counter ,$<i>$);
    code("\n@tranga_%d_%d_start:", jiro_counter, $<i>$);
  }
  statement finish
  {
    if($5){
      code("\n\t\tJMP\t@jiro_%d_exit", jiro_counter);
    } else {
      code("\n\t\tJMP\t@tranga_%d_%d_start", jiro_counter ,$<i>3+1);
      toeranas_extra = $<i>3+1;
    }
    code("\n@tranga_%d_%d_exit:", jiro_counter, $<i>3);
  }
  | trangas _TRANGA literal
  {
    int i = lookup_symbol(get_name($3), LIT);
         if (i != NO_INDEX) {
             if (get_atr2(i) == jiro_counter)
                 err("literal already inside of jiro expression");
             else 
                 set_atr2(i, jiro_counter);
              }  
    if(get_type(i)!= jiro_type)
        err("not a good jito type, type<ID> != type<literal>");
    $<i>$ = tranga_counter++;
    gen_cmp(jiro_id_idx, i);
    //jump not eq
    code("\n\t\t%s\t@tranga_%d_%d_exit", jumps[5], jiro_counter ,$<i>$);
    code("\n@tranga_%d_%d_start:", jiro_counter, $<i>$);
  }
  statement finish
  {
    if($6){
      code("\n\t\tJMP\t@jiro_%d_exit", jiro_counter);
    }else {
      code("\n\t\tJMP\t@tranga_%d_%d_start", jiro_counter ,$<i>4+1);
      toeranas_extra = $<i>4+1;
    }
    code("\n@tranga_%d_%d_exit:", jiro_counter, $<i>4);

  }
  ;

finish
  : { $$ = 0; }
  | _FINISH _SEMICOLON
    {
      $$ = 1;
    }
  ;

para_statement
  : _PARA _LPAREN _ID  
    {
      int idx = lookup_symbol($3, VAR|PAR|GVAR);
      if(idx == NO_INDEX) //da li je var def
        err("not def'%s'", $3);
    } 
    _ASSIGN literal _A literal 
    {
      int idx = lookup_symbol($3, VAR|PAR|GVAR);
      int t = get_type($6);
      if(t != get_type(idx))
        err("bad PARA types");
      gen_mov($6,idx);
      $<i>$ = para_counter;
      para_counter++;
      code("\n@para%d:", $<i>$);
      gen_cmp(idx, $8);
      code("\n\t\t%s\t@para%d_exit", jumps[4], $<i>$); 
      if(get_type($8) != get_type(lookup_symbol($3, VAR|PAR|GVAR)))
        err("bad PARA types");
      if(atoi(get_name($6)) >= atoi(get_name($8)))
        err("[literal %s >= literal %s]",get_name($6),get_name($8));
    }
    _RPAREN statement
    {
      int idx = lookup_symbol($3, VAR|PAR|GVAR);
      int t1 = get_type(idx);
      code("\n\t\t%s\t", ar_instructions[(t1 - 1) * AROP_NUMBER]);
      gen_sym_name(idx);
      code(",$1,");
      gen_sym_name(idx);
      set_type(idx, t1);
      code("\n\t\tJMP \t@para%d", $<i>9);
      code("\n@para%d_exit:", $<i>9);
    }
  ;

compound_statement
  : _LBRACKET statement_list _RBRACKET
  ;

assignment_statement
  : _ID _ASSIGN num_exp _SEMICOLON
      {

        int idx = lookup_symbol($1, VAR|PAR|GVAR);
        if(idx == NO_INDEX)
          err("invalid lvalue '%s' in assignment", $1);
        else
          if(get_type(idx) != get_type($3)){
            err("incompatible types in assignment");
          }
        //konstanta dopuna
        int buduca = 0;
        for(int i = 0; i < buduce_konstante_pointer; i++)
          if(idx == buduce_konstante[i])
            buduca = 1;
        for(int i = 0; i < konstante_pointer; i++)
          if(idx == konstante[i])
            err("After first assigment, const can not be moded!");
        if(buduca)
          konstante[konstante_pointer++] = idx;
        

        gen_mov($3, idx);

        if(isSystem){
          for(int i = 0; i < inputs_pointer; i++)
            if(idx == inputs[i])
              err("\"stimulus\" {%s} can not be moded from gates!\n",get_name(inputs[i]));
        }
          

        if(!isSystem){
        ////////////
          for(int i = 0; i < outputs_pointer; i++)
            if(idx == outputs[i])
              err("\"response\" {%s} can not be moded from functions!\n",get_name(outputs[i]));
          while(post_inc_count){
            post_inc_count--;
            idx = postInc[post_inc_count];
            int t1 = get_type(idx);
            code("\n\t\t%s\t", ar_instructions[(t1 - 1) * AROP_NUMBER]);
            gen_sym_name(idx);
            code(",$1,");
            gen_sym_name(idx);
            set_type(idx, t1);
            }
          while(isAssignIncl){
            isAssignIncl--;
            int t1 = get_type(isAssignIdx);
            code("\n\t\t%s\t", ar_instructions[(t1 - 1) * AROP_NUMBER]);
            gen_sym_name(isAssignIdx);
            code(",$1,");
            gen_sym_name(isAssignIdx);
            set_type(isAssignIdx, t1);
        /////////
            }

            isAssignIdx = -1;
        }
      }
  ;

//////////////////////////////
arg_exist
  : 
  {
    //prazan poziv
    if(param_na_redu != 0)
        err("too many arg for %s ", get_name(pozvana_funkcija));
    $$ = 0;
  }
  | arg_for_fun
  ;

arg_for_fun
  : num_exp 
    {
      param_na_redu++;
      if(param_na_redu > get_atr1(pozvana_funkcija))//da li br arg premasen
        err("too many arg for %s ", get_name(pozvana_funkcija));
      else if(get_type($1) != get_type(pozvana_funkcija + param_na_redu))//provera tipa
        err("bad type'%d'-- ", $1);
      free_if_reg($1);
      func_param[param_pointer] = $1;
      param_pointer++;
      //code("\n\t\t\tPUSH\t");
      //gen_sym_name($1);
      $$ = param_na_redu;
    }
  | arg_for_fun _COMMA num_exp
    {
      param_na_redu++;
      if(param_na_redu > get_atr1(pozvana_funkcija))
        err("too many arg for %s ", get_name(pozvana_funkcija));
      else if(get_type($3) != get_type(pozvana_funkcija + param_na_redu))
        err("bad type'%d'-- ", $3);
      free_if_reg($3);
      //code("\n\t\t\tPUSH\t");
      //gen_sym_name($3);
      func_param[param_pointer] = $3;
      param_pointer++;
      $$ = param_na_redu;
    }
  ;

fun_call
  : _ID 
  {
    pozvana_funkcija = lookup_symbol($1, FUN);
    if(pozvana_funkcija == NO_INDEX)
      err("no function named  '%s' ", $1);
  }
  _LPAREN arg_exist _RPAREN
  {
    while(param_pointer){
      param_pointer--;
      code("\n\t\t\tPUSH\t");
      gen_sym_name(func_param[param_pointer]);
    }

    if(param_na_redu != get_atr1(pozvana_funkcija))
      err("nedovoljno argumenata");
    param_na_redu = 0;
    code("\n\t\t\tCALL\t%s", get_name(pozvana_funkcija));
    $$ = lookup_symbol($1,FUN);
    //code("\n\t\t\tCALL\t%s", get_name(pozvana_funkcija));
    if($4 > 0)
        code("\n\t\t\tADDS\t%%15,$%d,%%15", $4 * 4);
    set_type(FUN_REG, get_type(pozvana_funkcija));

    $$ = FUN_REG;
  } 
  ;
///////////////////////////////////////


num_exp
  : num_exp2
  | num_exp _AROP num_exp2
  {
    if(get_type($1) != get_type($3))
      err("invalid operands: arithmetic operation");
    int t1 = get_type($1);    
    code("\n\t\t%s\t", ar_instructions[$2 + (t1 - 1) * AROP_NUMBER]);
    gen_sym_name($1);
    code(",");
    gen_sym_name($3);
    code(",");
    free_if_reg($3);
    free_if_reg($1);
    $$ = take_reg();
    gen_sym_name($$);
    set_type($$, t1);
    //print_symtab();
  }
  ;

num_exp2
  : exp
  | num_exp2 _AROP2 exp
  {
    if(get_type($1) != get_type($3))
      err("invalid operands: arithmetic operation");
    int t1 = get_type($1);    
    code("\n\t\t%s\t", ar_instructions[$2 + (t1 - 1) * AROP_NUMBER]);
    gen_sym_name($1);
    code(",");
    gen_sym_name($3);
    code(",");
    free_if_reg($3);
    free_if_reg($1);
    $$ = take_reg();
    gen_sym_name($$);
    set_type($$, t1);
    //print_symtab();
  }
  ;

post_inc
  : { $$ = 0; }
  | _INC
  {
    $$ = 1;
  }
  ;

exp
  : literal

  | _ID post_inc
      {
        //ako je u pitanju rad sa sistemom proveri da li moze
        int idx = lookup_symbol($1, VAR|PAR|GVAR);
        if(idx == NO_INDEX)
          err("'%s' undeclared", $1);
        if($2 == 1){
          //provera da li su konstante
          int error = 0;
          for(int i = 0; i < buduce_konstante_pointer; i++)
            if(idx == buduce_konstante[i])
              error = 1;
          for(int i = 0; i < konstante_pointer; i++)
            if(idx == konstante[i])
              error = 1;
          if(error)
            err("Const can not be ++ed");
          if(idx == isAssignIdx){
            isAssignIncl = 1;
          }else{
            postInc[post_inc_count] = idx;
            post_inc_count++;
          }
          $2 = 0;
        }
        $$ = idx;
      }

  | fun_call
      {
        $$ = take_reg();
        gen_mov(FUN_REG, $$);
      }
  
  | _LPAREN num_exp _RPAREN
      { $$ = $2; }
  | conditional
  ;

literal
  : _INT_NUMBER
      { $$ = insert_literal($1, INT); }

  | _UINT_NUMBER
      { $$ = insert_literal($1, UINT); }
  ;

conditional
  : _LPAREN rel_exp _RPAREN _QUESTIONMARK cond_exp _TWODOTS cond_exp
    {
      if(get_type($5) != get_type($7))
          err("invalid operands relational operator");
      conditional_counter++;
      $$ = take_reg();
      code("\n@condition_start_%d:",conditional_counter);
      code("\n\t\t%s\t@condition_false_%d",opp_jumps[$2],conditional_counter);
      gen_mov($5,$$);
      code("\n\t\tJMP\t@condition_end_%d", conditional_counter);
      code("\n@condition_false_%d:",conditional_counter);
      gen_mov($7,$$);
      code("\n@condition_end_%d:",conditional_counter);
      free_if_reg($5);
      free_if_reg($7);
    }
  ;
  
cond_exp
  : _ID
    {
      int idx = lookup_symbol($1, VAR|PAR|GVAR);
      if(idx == NO_INDEX)
        err("invalid lvalue '%s' in assignment", $1);
      $$ = idx;
    }
  | literal
  ;

if_statement
  : if_part %prec ONLY_IF
      { code("\n@exit%d:", $1); }

  | if_part _ELSE statement
      { code("\n@exit%d:", $1); }
  ;

if_part
  : _IF _LPAREN
      {
        $<i>$ = ++lab_num;
        code("\n@if%d:", lab_num);
      }
    rel_exp
      {
        code("\n\t\t%s\t@false%d", opp_jumps[$4], $<i>3); 
        code("\n@true%d:", $<i>3);
      }
    _RPAREN statement
      {
        code("\n\t\tJMP \t@exit%d", $<i>3);
        code("\n@false%d:", $<i>3);
        $$ = $<i>3;
      }
  ;

rel_exp
  : num_exp _RELOP num_exp
      {
        if(get_type($1) != get_type($3))
          err("invalid operands: relational operator");
        $$ = $2 + ((get_type($1) - 1) * RELOP_NUMBER);
        gen_cmp($1, $3);
      }
  ;



return_statement
  : _RETURN num_exp _SEMICOLON
      {
        rf++;
        if(get_type(fun_idx) != get_type($2)){
          err("incompatible types in return");
        }
        gen_mov($2, FUN_REG);
        code("\n\t\tJMP \t@%s_exit", get_name(fun_idx));        
      }
  | _RETURN _SEMICOLON
      {
        rf++;
        if(get_type(fun_idx) != VOID)
          warn("no ret exp");
        code("\n\t\tJMP \t@%s_exit", get_name(fun_idx));        
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
  output = fopen("output.asm", "w+");

  synerr = yyparse();

  clear_symtab();
  fclose(output);
  
  if(warning_count)
    printf("\n%d warning(s).\n", warning_count);
  if(error_count) {
    remove("output.asm");
    printf("\n%d error(s).\n", error_count);
  }

  if(synerr)
    return -1;  //syntax error
  else if(error_count)
    return error_count & 127; //semantic errors
  else if(warning_count)
    return (warning_count & 127) + 127; //warnings
  else
    return 0; //OK
}

