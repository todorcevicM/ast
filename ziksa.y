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
  char char_buffer[CHAR_BUFFER_LENGTH];
  int out_lin = 0;
  int error_count = 0;
  int warning_count = 0;
  int var_num = 0;
  int fun_idx = -1;
  int fcall_idx = -1;
  int returnflag=0;
	int typename=-1;
	int checkflag=0;
 	int brojac=0; // za case-ove
	int iniz[100]={0};
	unsigned uniz[100]={0};
	int tip_check=-1;
	int brojac_za_par=0;
	int brojac_za_arg=0;
	int brf_zaM=0;
	unsigned nizParam[30][30];
	int nizArg[30];
	int lab_num=-1;
	int arr_app_inc[100]; //niz pojavljivanja inkrementa u assign statement-u
	int cntr_inc=0;				// brojac pojavljivanja inkrementa u assign statement-u
	int const_flag=0;
	FILE *output;
	int for_labnum=-1;
	int check_labnum=-1;
	int for_dubina=-1; 	 // broj ugnjezdenih forova 
	int for_step_arr[10];// niz koraka koje cu pamtiti u slucaju ugnjezdenih forova
	int ternary_num=-1;
	int case_flag=0;
	int check_id=0;
%}

%union {
  int i;
  char *s;
}

%token <i> _TYPE
%token <i> _VTYPE
%token _IF
%token _ELSE
%token _RETURN
%token _FOR
%token _FINISH
%token _CHECK
%token _CASE
%token _OTHERWISE
%token _INC
%token _CONST
%token <s> _ID
%token <s> _INT_NUMBER
%token <s> _UINT_NUMBER
%token _LPAREN
%token _RPAREN
%token _QUESTIONMARK
%token _DOTDOT
%token _LBRACKET
%token _RBRACKET
%token _RBOX
%token _LBOX
%token _ARROW
%token _ASSIGN
%token _SEMICOLON
%token _COMMA
%token <i> _AROP
%token <i> _RELOP
%token <i>_MUL
%token <i>_DIV

%type <i> num_exp exp literal function_call argument rel_exp if_part inc mul_exp div_exp conditional ternary


%nonassoc ONLY_IF
%nonassoc _ELSE

%%

program
  : 
		global_list function_list
    {  
       if(lookup_symbol("main", FUN) == NO_INDEX)
          err("Mora postojati 'main' funkcija!");
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
        if(fun_idx == NO_INDEX)
				{
          fun_idx = insert_symbol($2, FUN, $1, NO_ATR, NO_ATR);
					nizParam[brf_zaM][0]=fun_idx;
					code("\n%s:",$2);
					code("\n\t\tPUSH\t%%14");
					code("\n\t\tMOV \t%%15,%%14");
				}
        else 
          err("redefinition of function '%s'", $2);
      }
    _LPAREN parameter_list
		{
			set_atr1(fun_idx, brojac_za_par);
		}
	 _RPAREN body
      {
		if(returnflag==0)
			warn("Funkcija mora imati return!");
        clear_symbols(fun_idx + 1);
        var_num = 0;
		brojac_za_par=0;			
		brf_zaM++;
		
		code("\n@%s_exit:", $2);
        code("\n\t\tMOV \t%%14,%%15");
        code("\n\t\tPOP \t%%14");
        code("\n\t\tRET");
      }
  | _VTYPE _ID
  {
		fun_idx = lookup_symbol($2, FUN);
		if(fun_idx == NO_INDEX)
		{
			fun_idx = insert_symbol($2, FUN, $1, NO_ATR, NO_ATR);
			nizParam[brf_zaM][0]=fun_idx;
			code("\n%s:",$2);
			code("\n\t\tPUSH\t%%14");
			code("\n\t\tMOV \t%%15,%%14");
		}
    else 
    	err("redefinition of function '%s'", $2);
  }
   _LPAREN parameter_list 
	{
		set_atr1(fun_idx, brojac_za_par);
	}			
	_RPAREN body
  {
		returnflag=0;
		clear_symbols(fun_idx + 1);
		var_num = 0;
		brojac_za_par=0;
		brf_zaM++;
		code("\n@%s_exit:", $2);
		code("\n\t\tMOV \t%%14,%%15");
		code("\n\t\tPOP \t%%14");
		code("\n\t\tRET");
  }
  ;
parameter_list
	: /* empty */
  {
	 	set_atr1(fun_idx, 0); 
	}
	| parameters
	;
parameters
	:	parameter
	| parameters _COMMA parameter
	;
parameter
  : _TYPE _ID
      {
				int idx = lookup_symbol($2, VAR|PAR);
				if(idx == NO_INDEX){
					brojac_za_par++;
					nizParam[brf_zaM][brojac_za_par]=$1;
					
        	insert_symbol($2, PAR, $1, brojac_za_par, 0);
				}
				else
					err("Promenljiva '%s' vec postoji!", $2);
        
      }
	| _CONST _TYPE _ID
  {
		int idx = lookup_symbol($3, VAR|PAR|CVAR|CPAR);
		if(idx == NO_INDEX){
			brojac_za_par++;
			nizParam[brf_zaM][brojac_za_par]=$2;
			
    	insert_symbol($3, CPAR, $2, brojac_za_par, 1);
		}
		else
			err("Promenljiva '%s' vec postoji!", $3);
    
  }
  ;

body
  : _LBRACKET variable_list 
	{
		if(var_num)
            code("\n\t\tSUBS\t%%15,$%d,%%15", 4 * var_num);
		
    code("\n@%s_body:", get_name(fun_idx));
	}
	statement_list _RBRACKET
  ;
variable_list
  : /* empty */
  | variable_list variable
  ;
variable
  : _TYPE	
	{
		typename=$1;
	} 
	name _SEMICOLON
	{
		typename=-1;
	}
	| _CONST 
	{
		const_flag=1;
	}
	_TYPE	
	{
		typename=$3;
	} 
	name _SEMICOLON
	{
		typename=-1;
		const_flag=0;
	}
	;
global_list
	: /*empty*/
	|	global_list global_var
	;
global_var
	: _TYPE _ID _SEMICOLON
	{
		if(lookup_symbol($2, CGVAR|GVAR|FUN) == NO_INDEX)
			{
				insert_symbol($2, GVAR, $1, ++var_num, 0);
				code("\n%s:\n\t\tWORD\t1",$2);
			}
		  else 
		  	err("Promenljiva '%s' vec postoji!", $2);
	}
	| _CONST _TYPE _ID _SEMICOLON
	{
		if(lookup_symbol($3, CGVAR|GVAR|FUN) == NO_INDEX)
			{
				insert_symbol($3, CGVAR, $2, ++var_num, 0);
				code("\n%s:\n\t\tWORD\t1",$3);
			}
		  else 
		  	err("Promenljiva '%s' vec postoji!", $3);
	}
	;
name
	: _ID
	{
			if(!const_flag)
			{
				if(lookup_symbol($1, VAR|PAR|CVAR|CPAR) == NO_INDEX)
					insert_symbol($1, VAR, typename, ++var_num, 0);
				else
					err("Promenljiva '%s' vec postoji!", $1);
			}
			else
			{
				if(lookup_symbol($1, VAR|PAR|CVAR|CPAR) == NO_INDEX)
					insert_symbol($1, CVAR, typename, ++var_num, 0);
				else
					err("Promenljiva '%s' vec postoji!", $1);
			}
  }
	| name _COMMA _ID
	{
		if(!const_flag)
		{
			if(lookup_symbol($3,VAR|PAR|CVAR|CPAR) == NO_INDEX)
		 		insert_symbol($3, CVAR, typename, ++var_num, 0);
			else 
				err("Promenljiva '%s' vec postoji!", $3);
		}
		else
		{
			if(lookup_symbol($3,VAR|PAR|CVAR|CPAR) == NO_INDEX)
		 		insert_symbol($3, VAR, typename, ++var_num, 0);
			else 
				err("Promenljiva '%s' vec postoji!", $3);
		}
  }
	| _ID _ASSIGN num_exp
  {
		if(!const_flag)
		{
    	if(lookup_symbol($1, VAR|PAR|CVAR|CPAR) == NO_INDEX)
			{
        int idx=insert_symbol($1, VAR, typename, ++var_num, 0);
				if(typename != get_type($3))
          err("Vrednost koja se dodeljuje mora biti istog tipa kao promenljiva!");
				else
					gen_mov($3, idx);
			}
      else 
      	err("Promenljiva '%s' vec postoji!", $1);
		}
		else
		{
			if(lookup_symbol($1, VAR|PAR|CVAR|CPAR) == NO_INDEX)
			{
        int idx=insert_symbol($1, CVAR, typename, ++var_num, 0);
				if(typename != get_type($3))
          err("Vrednost koja se dodeljuje mora biti istog tipa kao promenljiva!");
				else
				{
					gen_mov($3, idx);
					set_atr2(idx,1);
				}
			}
      else 
      	err("Promenljiva '%s' vec postoji!", $1);
		}
  }
	| name _COMMA _ID _ASSIGN num_exp
  {
		if(!const_flag)
		{
			if(lookup_symbol($3, VAR|PAR|CVAR|CPAR) == NO_INDEX){
				int idx=insert_symbol($3, VAR, typename, ++var_num, 0);
				if(typename != get_type($5))
					err("Vrednost koja se dodeljuje mora biti istog tipa kao promenljiva!");
				else
					gen_mov($5, idx);
			}
			else 
				err("Promenljiva '%s' vec postoji!", $3);
		}
		else
		{
			if(lookup_symbol($3, VAR|PAR|CVAR|CPAR) == NO_INDEX){
				int idx=insert_symbol($3, CVAR, typename, ++var_num, 0);
				if(typename != get_type($5))
					err("Vrednost koja se dodeljuje mora biti istog tipa kao promenljiva!");
				else
				{
					gen_mov($5, idx);
					set_atr2(idx,1);
				}
			}
			else 
				err("Promenljiva '%s' vec postoji!", $3);
		}
  }
  ;
statement_list
  : /* empty */
  | statements
  ;
statements
	:	statement
	|	statements statement
	;
statement
  : compound_statement
  | assignment_statement
  | if_statement
  | return_statement
	| for_statement
	| _ID _INC _SEMICOLON
		{
      if(lookup_symbol($1, VAR|PAR|GVAR) == NO_INDEX)
        err("'%s' nije deklarisan!", $1);
			else
			{
				int idx=lookup_symbol($1, VAR|PAR|GVAR);
				if(get_type(idx) == INT)
				{
					code("\n\t\tADDS\t");
				}
				else
				{
					code("\n\t\tADDU\t");
				}
				gen_sym_name(idx);
				code(",$1,");
				gen_sym_name(idx);
			}
  	}
  | check_statement
	;

check_statement
	:	_CHECK
	{
		if(!checkflag)
			checkflag=1;
		else
			err("Ne moze check statement da postoji u okviru drugog check statementa!");
		case_flag=take_reg();
	}
	 _LBOX _ID
	{
		int idx=lookup_symbol($4, VAR|PAR|GVAR|CVAR|CPAR|CGVAR);
		if( idx== NO_INDEX)
        err("'%s' nije deklarisan!", $4);
		check_id=idx;
		tip_check=get_type(idx);
		check_labnum++;
		code("\n@check_start%d:",check_labnum);
	}
	_RBOX _LBRACKET case_list otherwise _RBRACKET
	{
		code("\n@check%d_end:",check_labnum);
		free_if_reg(case_flag);
		checkflag=0;
		brojac=0;
	}
	;
otherwise
	:
	{
		code("\n@case%d_%d:",check_labnum,brojac);
	}
	|	_OTHERWISE 
	{
		code("\n@case%d_%d:",check_labnum,brojac);
	}		
	_ARROW statement
	;
case_list
	: case
	| case_list case
	;

case
	: _CASE _INT_NUMBER
	{
		if(tip_check==1)
		{
			int broj=atoi($2);
			int i;
			for(i=0;i<brojac;i++)
			{
				if(broj==iniz[i])
					err("Case sa brojem '%d' vec postoji!",broj);
			
			}
			iniz[brojac]=broj;
			code("\n@case%d_%d:",check_labnum,brojac);
			code("\n\t\tCMPS\t");
			gen_sym_name(case_flag);
			code(",$1");
			code("\n\t\tJEQ\t@case%d_%d_body",check_labnum,brojac);
			code("\n\t\tCMPS\t");
			gen_sym_name(check_id);
			code(",$%d",broj);
			code("\n\t\tJNE\t@case%d_%d",check_labnum,brojac+1);
			code("\n\t\tMOV\t");
			code("$1,");
			gen_sym_name(case_flag);
			code("\n@case%d_%d_body:",check_labnum,brojac);

			
		}
		else
			err("Tipovi moraju da se poklapaju!");
	}
	_ARROW statement
	{
		brojac++;		
	}
	 finish
	| _CASE _UINT_NUMBER
	{
		if(tip_check==2)
		{
			unsigned broj=(unsigned)atoi($2);
			int i;
			for(i=0;i<brojac;i++)
			{
				if(broj==uniz[i])
					err("Case sa brojem '%du' vec postoji!",broj);
			
			}
			uniz[brojac]=broj;
			code("\n@case%d_%d:",check_labnum,brojac);
			code("\n\t\tCMPS\t");
			gen_sym_name(case_flag);
			code(",$1");
			code("\n\t\tJEQ\t@case%d_%d_body",check_labnum,brojac);
			code("\n\t\tCMPS\t");
			gen_sym_name(check_id);
			code(",$%d",broj);
			code("\n\t\tJNE\t@case%d_%d",check_labnum,brojac+1);
			code("\n\t\tMOV\t");
			code("$1,");
			gen_sym_name(case_flag);
			code("\n@case%d_%d_body:",check_labnum,brojac);
		}
		else
			err("Tipovi moraju da se poklapaju!");
	}
	_ARROW statement
	{
		brojac++;		
	} 
	finish
	;
	
finish
	:	/* empty */
	|	_FINISH _SEMICOLON
	{
		code("\n\t\tJMP\t@check%d_end",check_labnum);
	}
	;

compound_statement
  : _LBRACKET statement_list _RBRACKET
  ;

assignment_statement
  : _ID _ASSIGN num_exp _SEMICOLON
  {
  	int idx = lookup_symbol($1, VAR|PAR|GVAR|CVAR|CPAR|CGVAR);
  	if(idx == NO_INDEX)
    	err("Ne postoji promenljiva '%s' kojoj biste mogli da dodelite vrednost!", $1);
  	else
    	if(get_type(idx) != get_type($3))
      	err("Vrednost koja se dodeljuje mora biti istog tipa kao promenljiva!");
		if((get_kind(idx)==CVAR||get_kind(idx)==CPAR||get_kind(idx)==CGVAR)&&(get_atr2(idx)))
			err("Ne mozete da dodelite vrednost konstanti kojoj je vrednost vec dodeljena!");
		else
		{
			gen_mov($3, idx);
			int i;
			for(i=0;i<cntr_inc;i++)
			{
				int atr2=get_atr2(arr_app_inc[i]);
				if(get_type(arr_app_inc[i]) == INT)
				{
				  code("\n\t\tADDS\t");
				}
				else
				{
				  code("\n\t\tADDU\t");
				}
				gen_sym_name(arr_app_inc[i]);
				if((!(idx==arr_app_inc[i]))&&(atr2>=1))
					code(",$1,");
				else
					code(",$0,");
				gen_sym_name(arr_app_inc[i]);
			}
			for(i=0;i<cntr_inc;i++)
			{
				int atr2=get_atr2(arr_app_inc[i]);
				if(get_type(arr_app_inc[i]) == INT)
				{
				  code("\n\t\tSUBS\t");
				}
				else
				{
				  code("\n\t\tSUBU\t");
				}
		
				gen_sym_name(idx);
				if(((idx==arr_app_inc[i]))&&(atr2>1))
					code(",$1,");
				else
					code(",$0,");
				gen_sym_name(idx);
			}
		
			cntr_inc=0;
		}
	}
  ;
  
for_statement
	:	_FOR _LPAREN _TYPE _ID
	{
		if(lookup_symbol($4, VAR|PAR|CVAR|CPAR) == NO_INDEX)
		{
    	int idx=insert_symbol($4, VAR, $3, ++var_num, NO_ATR);
			code("\n\t\tMOV \t$1,");
			gen_sym_name(idx);
			for_dubina++;
			$<i>$ = ++for_labnum;
			code("\n@forstart%d:",$<i>$);
		}
    else 
    	err("Promenljiva '%s' vec postoji!", $4);
	}		
 	_SEMICOLON rel_exp _SEMICOLON literal
	{
		int broj;
		broj=(int)atoi(get_name($9));
		if(broj==0)
			err("Korak iteratora ne sme da bude 0!");
		for_step_arr[for_dubina]=broj;
		
		if($3!= get_type($9))
			err("Tipovi moraju da se poklapaju unutar for statementa!");
		code("\n\t\t%s\t@forexit%d", opp_jumps[$7], $<i>5);
    
	}
	 _RPAREN statement
	{
		int idx=lookup_symbol($4, VAR|PAR|CVAR|CPAR);
		if(get_type(idx)==INT)
			code("\n\t\tADDS\t");
		else
			code("\n\t\tADDU\t");
		gen_sym_name(idx);
		code(",$%d,",for_step_arr[for_dubina]);
		gen_sym_name(idx);
			code("\n\t\tJMP\t@forstart%d",$<i>5);
			code("\n@forexit%d:", $<i>5);
			clear_symbols(lookup_symbol($4, VAR|PAR|CVAR|CPAR));
			for_dubina--;
			var_num--;
	}
	;
	
			
	
num_exp
  : div_exp
  | num_exp _AROP div_exp
      {
        if(get_type($1) != get_type($3))
          err("Vrednosti moraju biti istog tipa da bi se operacija izvrsila!");
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
      }
  ;
mul_exp
	:	exp
	|	mul_exp _MUL exp
	{
		if(get_type($1) != get_type($3))
          err("Vrednosti moraju biti istog tipa da bi se operacija izvrsila!");
		int t1 = get_type($1);
		if(t1==INT)    
    	code("\n\t\tMULS\t");
		else
			code("\n\t\tMULU\t");
    gen_sym_name($1);
    code(",");
    gen_sym_name($3);
    code(",");
    free_if_reg($3);
    free_if_reg($1);
    $$ = take_reg();
    gen_sym_name($$);
    set_type($$, t1);
	}
	;
div_exp
	: mul_exp
	| div_exp _DIV mul_exp
	{
		if(get_type($1) != get_type($3))
          err("Vrednosti moraju biti istog tipa da bi se operacija izvrsila!");
		int t1 = get_type($1);
		if(t1==INT)    
    	code("\n\t\tDIVS\t");
		else
			code("\n\t\tDIVU\t");
    gen_sym_name($1);
    code(",");
    gen_sym_name($3);
    code(",");
    free_if_reg($3);
    free_if_reg($1);
    $$ = take_reg();
    gen_sym_name($$);
    set_type($$, t1);
	}
	;
exp
  : literal
	| ternary
	| _ID inc
	{
    $$ = lookup_symbol($1, VAR|PAR|GVAR|CVAR|CGVAR|CPAR);
    if($$ == NO_INDEX)
      err("'%s' nije deklarisan!", $1);
		if($2)
		{
			unsigned atr2=get_atr2($$);
			if(atr2>=1)
			{
				set_atr2($$,atr2+1);
				if(get_type($$) == INT)
				{
			    code("\n\t\tADDS\t");
			  }
				else
				{
			    code("\n\t\tADDU\t");
			  }
				gen_sym_name($$);
				code(",$1,");
				gen_sym_name($$);
				int flag=0;
				int i;
				for(i=0;i<cntr_inc;i++)
				{
					if(arr_app_inc[i]==$$)
					{
						flag=1;
						break;
					}
				}
				if(!flag)
					arr_app_inc[cntr_inc++]=$$;
			}
			else
			{
				set_atr2($$,atr2+1);
				int flag=0;
				int i;
				for(i=0;i<cntr_inc;i++)
				{
					if(arr_app_inc[i]==$$)
					{
						flag=1;
						break;
					}
				}
				if(!flag)
					arr_app_inc[cntr_inc++]=$$;
			}
		}
  }
  | function_call
	{
		$$ = take_reg();
		gen_mov(FUN_REG, $$);
	}
  | _LPAREN num_exp _RPAREN
      { $$ = $2; }
  ;
ternary
	:	_LPAREN rel_exp _RPAREN _QUESTIONMARK conditional _DOTDOT conditional
	{
			if(get_type($5)!=get_type($7))
				err("Tipovi moraju da se poklapaju!");
			else
			{
				++ternary_num;
				$$ = take_reg();
				code("\n@ternary_start%d:",ternary_num);
				code("\n\t\t%s\t@ternary_false%d",opp_jumps[$2],ternary_num);
				gen_mov($5,$$);
				code("\n\t\tJMP\t@ternary_end%d", ternary_num);
				code("\n@ternary_false%d:",ternary_num);
				gen_mov($7,$$);
				code("\n@ternary_end%d:",ternary_num);
				free_if_reg($5);
				free_if_reg($7);
			}
				
	}
	;
conditional
	: _ID
	{
			int idx=lookup_symbol($1, VAR|PAR|CVAR|CPAR|CGVAR|GVAR);
			if(idx==NO_INDEX)
				err("Ne postoji promenljiva '%s'!", $1);
			$$=idx;
	}
	| literal
	;
inc 
	:	/* empty */{$$=0;}
	|	_INC {$$=1;}
	;
literal
  : _INT_NUMBER
      { $$ = insert_literal($1, INT); }

  | _UINT_NUMBER
      { $$ = insert_literal($1, UINT); }
  ;

function_call
  : _ID 
      {
        fcall_idx = lookup_symbol($1, FUN);
        if(fcall_idx == NO_INDEX)
          err("'%s' nije funkcija!", $1);
      }
    _LPAREN argument_list _RPAREN
      {
        if(get_atr1(fcall_idx) != brojac_za_arg)
          err("Uneli ste pogresan broj argumenata za funkciju '%s'!", get_name(fcall_idx));
        set_type(FUN_REG, get_type(fcall_idx));
				int i;
				for(i=1;i<=brojac_za_arg;i++)
				{
					free_if_reg(nizArg[brojac_za_arg-i]);
					code("\n\t\tPUSH\t");
					gen_sym_name(nizArg[brojac_za_arg-i]);
				}
				code("\n\t\t\tCALL\t%s",get_name(fcall_idx));
				code("\n\t\t\tADDS\t%%15,$%d,%%15",brojac_za_arg*4);
				set_type(FUN_REG,get_type(fcall_idx));
        $$ = FUN_REG;
				brojac_za_arg=0;
      }
  ;

argument_list
	: /*empty*/
	|arguments
	;
arguments
	: argument
	| arguments _COMMA argument
	;
argument
  : num_exp
    { 
			int broj_param;
			broj_param=get_atr1(fcall_idx);
			int i;
			int pozicija;
			for(i=0;i<brf_zaM;i++)
			{
				if(nizParam[i][0]==fcall_idx)
					pozicija=i;
			}
			if(nizParam[pozicija][brojac_za_arg+1]==get_type($1)&&brojac_za_arg<broj_param)
			{
				nizArg[brojac_za_arg]=$1;
				brojac_za_arg++;
			}
			else
			{
				err("Tip argumenta pri pozivu funkcije mora biti jednak sa tipom parametra funkcije!");
				brojac_za_arg++;
			}
    }
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
          err("Tipovi moraju da se poklapaju!");
				$$ = $2 + ((get_type($1) - 1) * RELOP_NUMBER);
        gen_cmp($1, $3);
      }
  ;

return_statement
  : _RETURN num_exp _SEMICOLON
      {
				returnflag=1;
        if(get_type(fun_idx) != get_type($2))
          err("Tip povratne vrednosti mora biti isti kao i tip  funkcije!");
		  
		gen_mov($2, FUN_REG);
        code("\n\t\tJMP \t@%s_exit", get_name(fun_idx));
      }
  | _RETURN _SEMICOLON
     {
			returnflag=1;
			if(get_type(fun_idx)!=VOID)
				warn("Funkcija mora imati povratnu vrednost!");
				
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

