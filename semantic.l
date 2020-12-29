%option noyywrap yylineno

%{
   #include <string.h>
   #include "semantic.tab.h"
   #include "defs.h"
%}

%%

[ \t\n]+             { /* skip */ }

"init"               { return INIT; }

"int"                { yylval.i = INT;  return TYPE; }
"unsigned"           { yylval.i = UINT; return TYPE; }
"void"               { yylval.i = VOID; return V_TYPE; }

"if"                 { return IF; }
"else"               { return ELSE; }
"return"             { return RETURN; }

"loop"               { return LOOP; }

"jiro"               { return JIRO; }
"tranga"             { return TRANGA; }
"toreana"            { return TOREANA; }
"finish"             { return FINISH; }
"["                  { return LABRACKET; }
"]"                  { return RABRACKET; }
"->"                 { return DO; }

";"                  { return SEMICOLON; }
","                  { return COMMA; }

"("                  { return LPAREN; }
")"                  { return RPAREN; }
"{"                  { return LBRACKET; }
"}"                  { return RBRACKET; }
"="                  { return ASSIGN; }

"+"                  { yylval.i = ADD; return AROP; }
"-"                  { yylval.i = SUB; return AROP; }
"*"                  { yylval.i = MUL; return AROP; }
"/"                  { yylval.i = DIV; return AROP; }
"%"                  { yylval.i = MIV; return AROP; }

"++"                 { return PINC; }
"--"                 { return PDEC; }

"<"                  { yylval.i = LT; return RELOP; }
">"                  { yylval.i = GT; return RELOP; }
"<="                 { yylval.i = LE; return RELOP; }
">="                 { yylval.i = GE; return RELOP; }
"=="                 { yylval.i = EQ; return RELOP; }
"!="                 { yylval.i = NE; return RELOP; }

[a-zA-Z][a-zA-Z0-9]* { yylval.s = strdup(yytext); 
                       return ID; }
[+-]?[0-9]{1,10}     { yylval.s = strdup(yytext); 
                       return INT_NUMBER;}
[0-9]{1,10}[uU]      { yylval.s = strdup(yytext); 
                       yylval.s[yyleng-1] = 0;
                       return UINT_NUMBER;}

\/\/.*               { /* skip */ }
\/\*[\0-😀]*\*\/     { /* skip */ }
.                    { printf("line %d: LEXICAL ERROR on char %c\n", yylineno, *yytext);}
%%
