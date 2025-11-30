%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser.tab.h"

int line = 1;
int column = 1;

Token* create_token(int type, const char *value) {
    Token* tok = malloc(sizeof(Token));
    tok->type = type;
    tok->value = strdup(value);
    tok->line = line;
    tok->column = column;
    return tok;
}

void update_position(const char *text) {
    for (int i = 0; text[i]; i++) {
        if (text[i] == '\n') {
            line++;
            column = 1;
        } else {
            column++;
        }
    }
}

#define RETURN_TOKEN(tok_type) do { \
    update_position(yytext); \
    yylval.token = create_token(tok_type, yytext); \
    return tok_type; \
} while(0)

%}

%option noyywrap
%option yylineno

DIGIT           [0-9]
LETTER          [a-zA-Z_]
IDENTIFIER      {LETTER}({LETTER}|{DIGIT})*
INT_LITERAL     {DIGIT}+
FLOAT_LITERAL   {DIGIT}+\.{DIGIT}+
STRING          \"([^\"\\]|\\.)*\"
WHITESPACE      [ \t\r]
NEWLINE         \n
COMMENT_SINGLE  \/\/[^\n]*
COMMENT_MULTI   \/\*([^*]|\*[^/])*\*\/

%%

{WHITESPACE}          { update_position(yytext); }
{NEWLINE}             { RETURN_TOKEN(TOKEN_NEWLINE); }
{COMMENT_SINGLE}      { RETURN_TOKEN(TOKEN_COMMENT); }
{COMMENT_MULTI}       { RETURN_TOKEN(TOKEN_COMMENT); }


">="                  { RETURN_TOKEN(TOKEN_GTE); }
"<="                  { RETURN_TOKEN(TOKEN_LTE); }
"=="                  { RETURN_TOKEN(TOKEN_EQ); }
"!="                  { RETURN_TOKEN(TOKEN_NEQ); }
"&&"                  { RETURN_TOKEN(TOKEN_AND); }
"||"                  { RETURN_TOKEN(TOKEN_OR); }

">"                   { RETURN_TOKEN(TOKEN_GT); }
"<"                   { RETURN_TOKEN(TOKEN_LT); }
"="                   { RETURN_TOKEN(TOKEN_ASSIGN); }
"+"                   { RETURN_TOKEN(TOKEN_PLUS); }
"-"                   { RETURN_TOKEN(TOKEN_MINUS); }
"*"                   { RETURN_TOKEN(TOKEN_MUL); }
"/"                   { RETURN_TOKEN(TOKEN_DIV); }
"%"                   { RETURN_TOKEN(TOKEN_MOD); }
"^"                   { RETURN_TOKEN(TOKEN_XOR); }
"!"                   { RETURN_TOKEN(TOKEN_NOT); }

"("                   { RETURN_TOKEN(TOKEN_LPAREN); }
")"                   { RETURN_TOKEN(TOKEN_RPAREN); }
"{"                   { RETURN_TOKEN(TOKEN_LBRACE); }
"}"                   { RETURN_TOKEN(TOKEN_RBRACE); }
"["                   { RETURN_TOKEN(TOKEN_LBRACKET); }
"]"                   { RETURN_TOKEN(TOKEN_RBRACKET); }
";"                   { RETURN_TOKEN(TOKEN_SEMICOLON); }
","                   { RETURN_TOKEN(TOKEN_COMMA); }
":"                   { RETURN_TOKEN(TOKEN_COLON); }
"."                   { RETURN_TOKEN(TOKEN_DOT); }

"continue"            { RETURN_TOKEN(TOKEN_CONTINUE); }
"return"              { RETURN_TOKEN(TOKEN_RETURN); }
"break"               { RETURN_TOKEN(TOKEN_BREAK); }
"while"               { RETURN_TOKEN(TOKEN_WHILE); }
"else"                { RETURN_TOKEN(TOKEN_ELSE); }
"for"                 { RETURN_TOKEN(TOKEN_FOR); }
"if"                  { RETURN_TOKEN(TOKEN_IF); }
"then"                { RETURN_TOKEN(TOKEN_THEN); }
"class"               { RETURN_TOKEN(TOKEN_CLASS); }
"funk"                { RETURN_TOKEN(TOKEN_FUNK); }
"var"                 { RETURN_TOKEN(TOKEN_VAR); }
"true"                { RETURN_TOKEN(TOKEN_TRUE); }
"false"               { RETURN_TOKEN(TOKEN_FALSE); }
"null"                { RETURN_TOKEN(TOKEN_NULL); }
"int"                 { RETURN_TOKEN(TOKEN_INT); }
"float"               { RETURN_TOKEN(TOKEN_FLOAT); }
"str"                 { RETURN_TOKEN(TOKEN_STR); }
"bool"                { RETURN_TOKEN(TOKEN_BOOL); }
"list"                { RETURN_TOKEN(TOKEN_LIST); }
"dict"                { RETURN_TOKEN(TOKEN_DICT); }
"this"                { RETURN_TOKEN(TOKEN_THIS); }
"new"                 { RETURN_TOKEN(TOKEN_NEW); }
"in"                  { RETURN_TOKEN(TOKEN_IN); }
"to"                  { RETURN_TOKEN(TOKEN_TO); }
"from"                { RETURN_TOKEN(TOKEN_FROM); }
"try"                 { RETURN_TOKEN(TOKEN_TRY); }
"catch"               { RETURN_TOKEN(TOKEN_CATCH); }
"finally"             { RETURN_TOKEN(TOKEN_FINALLY); }
"throw"               { RETURN_TOKEN(TOKEN_THROW); }
"demand"              { RETURN_TOKEN(TOKEN_DEMAND); }
"print"               { RETURN_TOKEN(TOKEN_PRINT); }


{IDENTIFIER}          { RETURN_TOKEN(TOKEN_IDENTIFIER); }
{FLOAT_LITERAL}       { RETURN_TOKEN(TOKEN_FLOAT_LITERAL); }
{INT_LITERAL}         { RETURN_TOKEN(TOKEN_INT_LITERAL); }
{STRING}              { RETURN_TOKEN(TOKEN_STR_LITERAL); }


<<EOF>>               { return 0; }

.                     { 
                        update_position(yytext);
                        fprintf(stderr, "Error: Unexpected character '%s' at line %d, column %d\n", 
                                yytext, line, column);
                        RETURN_TOKEN(TOKEN_ERROR);
                      }

%%
