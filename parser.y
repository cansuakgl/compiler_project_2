%{
#include <stdio.h>
#include <stdlib.h>

extern int yylex();
extern int yylineno;
extern char* yytext;
extern FILE* yyin;

void yyerror(const char *s) {
    fprintf(stderr, "Parse error: %s at line %d\n", s, yylineno);
}
%}

%code requires {
    typedef struct Token {
        int type;
        char* value;
        int line;
        int column;
    } Token;

    typedef struct ASTNode ASTNode;
}

%{
#include "ast.h"
ASTNode* ast_root = NULL;
%}

%union {
    Token* token;
    ASTNode* node;
}


%token <token> TOKEN_VAR TOKEN_IF TOKEN_THEN TOKEN_ELSE TOKEN_WHILE TOKEN_FOR TOKEN_BREAK TOKEN_CONTINUE TOKEN_RETURN
%token <token> TOKEN_CLASS TOKEN_FUNK
%token <token> TOKEN_TRUE TOKEN_FALSE TOKEN_NULL
%token <token> TOKEN_AND TOKEN_OR TOKEN_NOT TOKEN_XOR
%token <token> TOKEN_PRINT
%token <token> TOKEN_IN TOKEN_TO TOKEN_FROM
%token <token> TOKEN_TRY TOKEN_CATCH TOKEN_FINALLY TOKEN_THROW
%token <token> TOKEN_DEMAND
%token <token> TOKEN_THIS TOKEN_NEW

%token <token> TOKEN_INT TOKEN_FLOAT TOKEN_STR TOKEN_BOOL TOKEN_LIST TOKEN_DICT
%token <token> TOKEN_IDENTIFIER TOKEN_INT_LITERAL TOKEN_FLOAT_LITERAL TOKEN_STR_LITERAL

%token <token> TOKEN_PLUS TOKEN_MINUS TOKEN_MUL TOKEN_DIV TOKEN_MOD
%token <token> TOKEN_GT TOKEN_LT TOKEN_GTE TOKEN_LTE TOKEN_EQ TOKEN_NEQ TOKEN_ASSIGN

%token <token> TOKEN_LPAREN TOKEN_RPAREN TOKEN_LBRACE TOKEN_RBRACE
%token <token> TOKEN_SEMICOLON TOKEN_COMMA TOKEN_LBRACKET TOKEN_RBRACKET TOKEN_COLON
%token <token> TOKEN_DOT TOKEN_DQUOTE

%token <token> TOKEN_EOF TOKEN_NEWLINE TOKEN_ERROR TOKEN_COMMENT


%type <node> program statement_list expression
%type <node> simple_stmt compound_stmt
%type <node> var_decl func_decl class_decl
%type <node> param_list param_list_opt
%type <node> arg_list arg_list_opt
%type <node> block statement_block
%type <node> if_then_stmt if_block_stmt while_stmt for_stmt
%type <node> try_stmt catch_clause finally_clause
%type <node> dict_literal dict_entries dict_entry
%type <node> list_literal list_items
%type <node> type_specifier
%type <node> else_if_chain else_clause
%type <node> class_body class_member_list

%left TOKEN_OR
%left TOKEN_XOR
%left TOKEN_AND
%left TOKEN_EQ TOKEN_NEQ
%left TOKEN_GT TOKEN_LT TOKEN_GTE TOKEN_LTE
%left TOKEN_PLUS TOKEN_MINUS
%left TOKEN_MUL TOKEN_DIV TOKEN_MOD
%right TOKEN_NOT
%left TOKEN_DOT
%left TOKEN_LBRACKET

%%

program:
    statement_list { 
        ast_root = ast_create(AST_PROGRAM, NULL);
        if ($1 != NULL) {
            for (int i = 0; i < $1->child_count; i++) {
                ast_add_child(ast_root, $1->children[i]);
            }
            free($1->children);
            free($1);
        }
        $$ = ast_root;
    }
    ;

terminator:
    TOKEN_NEWLINE
    ;

statement_list:
    { $$ = ast_create(AST_PROGRAM, NULL); }
    | statement_list simple_stmt terminator { 
        if ($2 != NULL) ast_add_child($1, $2);
        $$ = $1;
    }
    | statement_list compound_stmt { 
        if ($2 != NULL) ast_add_child($1, $2);
        $$ = $1;
    }
    | statement_list terminator { $$ = $1; }
    | statement_list TOKEN_COMMENT { $$ = $1; }
    ;

simple_stmt:
    var_decl { $$ = $1; }
    | if_then_stmt { $$ = $1; }
    | TOKEN_PRINT TOKEN_LPAREN arg_list_opt TOKEN_RPAREN {
        ASTNode* node = ast_create(AST_STMT_PRINT, $1);
        if ($3 != NULL) ast_add_child(node, $3);
        $$ = node;
    }
    | TOKEN_DEMAND expression {
        ASTNode* node = ast_create(AST_STMT_DEMAND, $1);
        ast_add_child(node, $2);
        $$ = node;
    }
    | TOKEN_RETURN expression {
        ASTNode* node = ast_create(AST_STMT_RETURN, $1);
        ast_add_child(node, $2);
        $$ = node;
    }
    | TOKEN_RETURN { $$ = ast_create(AST_STMT_RETURN, $1); }
    | TOKEN_BREAK { $$ = ast_create(AST_STMT_BREAK, $1); }
    | TOKEN_CONTINUE { $$ = ast_create(AST_STMT_CONTINUE, $1); }
    | TOKEN_THROW expression {
        ASTNode* node = ast_create(AST_STMT_THROW, $1);
        ast_add_child(node, $2);
        $$ = node;
    }
    | expression TOKEN_ASSIGN expression {
        ASTNode* node = ast_create(AST_EXPR_ASSIGN, NULL);
        ast_add_child(node, $1);
        ast_add_child(node, $3);
        $$ = node;
    }
    | expression {
        ASTNode* node = ast_create(AST_STMT_EXPR, NULL);
        ast_add_child(node, $1);
        $$ = node;
    }
    ;

compound_stmt:
    func_decl { $$ = $1; }
    | class_decl { $$ = $1; }
    | if_block_stmt { $$ = $1; }
    | while_stmt { $$ = $1; }
    | for_stmt { $$ = $1; }
    | try_stmt { $$ = $1; }
    ;

type_specifier:
    TOKEN_INT { $$ = ast_create(AST_EXPR_IDENT, $1); }
    | TOKEN_FLOAT { $$ = ast_create(AST_EXPR_IDENT, $1); }
    | TOKEN_STR { $$ = ast_create(AST_EXPR_IDENT, $1); }
    | TOKEN_BOOL { $$ = ast_create(AST_EXPR_IDENT, $1); }
    | TOKEN_LIST { $$ = ast_create(AST_EXPR_IDENT, $1); }
    | TOKEN_DICT { $$ = ast_create(AST_EXPR_IDENT, $1); }
    ;

var_decl:
    type_specifier TOKEN_IDENTIFIER TOKEN_ASSIGN expression {
        ASTNode* node = ast_create(AST_DECL_VAR, $2);
        ast_add_child(node, $1);
        ast_add_child(node, $4);
        $$ = node;
    }
    | TOKEN_VAR TOKEN_IDENTIFIER TOKEN_ASSIGN expression {
        ASTNode* node = ast_create(AST_DECL_VAR, $2);
        ast_add_child(node, $4);
        $$ = node;
    }
    ;

func_decl:
    type_specifier TOKEN_FUNK TOKEN_IDENTIFIER TOKEN_LPAREN param_list_opt TOKEN_RPAREN block {
        ASTNode* node = ast_create(AST_DECL_FUNC, $3);
        ast_add_child(node, $1);
        if ($5 != NULL) ast_add_child(node, $5);
        ast_add_child(node, $7);
        $$ = node;
    }
    | TOKEN_VAR TOKEN_FUNK TOKEN_IDENTIFIER TOKEN_LPAREN param_list_opt TOKEN_RPAREN block {
        ASTNode* node = ast_create(AST_DECL_FUNC, $3);
        ast_add_child(node, ast_create(AST_EXPR_IDENT, $1));
        if ($5 != NULL) ast_add_child(node, $5);
        ast_add_child(node, $7);
        $$ = node;
    }
    ;

param_list_opt:
    { $$ = NULL; }
    | param_list { $$ = $1; }
    ;

param_list:
    TOKEN_IDENTIFIER {
        ASTNode* params = ast_create(AST_AUX_PARAM_LIST, NULL);
        ast_add_child(params, ast_create(AST_EXPR_IDENT, $1));
        $$ = params;
    }
    | type_specifier TOKEN_IDENTIFIER {
        ASTNode* params = ast_create(AST_AUX_PARAM_LIST, NULL);
        ASTNode* param = ast_create(AST_DECL_VAR, $2);
        ast_add_child(param, $1);
        ast_add_child(params, param);
        $$ = params;
    }
    | param_list TOKEN_COMMA TOKEN_IDENTIFIER {
        ast_add_child($1, ast_create(AST_EXPR_IDENT, $3));
        $$ = $1;
    }
    | param_list TOKEN_COMMA type_specifier TOKEN_IDENTIFIER {
        ASTNode* param = ast_create(AST_DECL_VAR, $4);
        ast_add_child(param, $3);
        ast_add_child($1, param);
        $$ = $1;
    }
    ;

class_decl:
    TOKEN_CLASS TOKEN_IDENTIFIER TOKEN_LBRACE class_body TOKEN_RBRACE {
        ASTNode* node = ast_create(AST_DECL_CLASS, $2);
        ast_add_child(node, $4);
        $$ = node;
    }
    ;

class_body:
    class_member_list { $$ = $1; }
    ;

class_member_list:
    { $$ = ast_create(AST_AUX_CLASS_BODY, NULL); }
    | class_member_list func_decl {
        if ($2 != NULL) ast_add_child($1, $2);
        $$ = $1;
    }
    | class_member_list var_decl terminator {
        if ($2 != NULL) ast_add_child($1, $2);
        $$ = $1;
    }
    | class_member_list terminator { $$ = $1; }
    | class_member_list TOKEN_COMMENT { $$ = $1; }
    ;

block:
    TOKEN_LBRACE statement_block TOKEN_RBRACE { $$ = $2; }
    ;

statement_block:
    { $$ = ast_create(AST_BLOCK, NULL); }
    | statement_block simple_stmt terminator {
        if ($2 != NULL) ast_add_child($1, $2);
        $$ = $1;
    }
    | statement_block compound_stmt {
        if ($2 != NULL) ast_add_child($1, $2);
        $$ = $1;
    }
    | statement_block terminator { $$ = $1; }
    | statement_block TOKEN_COMMENT { $$ = $1; }
    ;

if_then_stmt:
    TOKEN_IF expression TOKEN_THEN expression {
        ASTNode* node = ast_create(AST_CTRL_IF, $1);
        ast_add_child(node, $2);
        ast_add_child(node, $4);
        $$ = node;
    }
    ;

if_block_stmt:
    TOKEN_IF TOKEN_LPAREN expression TOKEN_RPAREN block {
        ASTNode* node = ast_create(AST_CTRL_IF, $1);
        ast_add_child(node, $3);
        ast_add_child(node, $5);
        $$ = node;
    }
    | TOKEN_IF TOKEN_LPAREN expression TOKEN_RPAREN block TOKEN_ELSE block {
        ASTNode* node = ast_create(AST_CTRL_IF_ELSE, $1);
        ast_add_child(node, $3);
        ast_add_child(node, $5);
        ast_add_child(node, $7);
        $$ = node;
    }
    | TOKEN_IF TOKEN_LPAREN expression TOKEN_RPAREN block else_if_chain {
        ASTNode* node = ast_create(AST_CTRL_IF_ELSE, $1);
        ast_add_child(node, $3);
        ast_add_child(node, $5);
        ast_add_child(node, $6);
        $$ = node;
    }
    | TOKEN_IF TOKEN_LPAREN expression TOKEN_RPAREN block else_if_chain else_clause {
        ASTNode* node = ast_create(AST_CTRL_IF_ELSE, $1);
        ast_add_child(node, $3);
        ast_add_child(node, $5);
        ast_add_child(node, $6);
        ast_add_child(node, $7);
        $$ = node;
    }
    ;

else_if_chain:
    TOKEN_ELSE TOKEN_IF TOKEN_LPAREN expression TOKEN_RPAREN block {
        ASTNode* node = ast_create(AST_CTRL_ELIF, NULL);
        ast_add_child(node, $4);
        ast_add_child(node, $6);
        $$ = node;
    }
    | else_if_chain TOKEN_ELSE TOKEN_IF TOKEN_LPAREN expression TOKEN_RPAREN block {
        ASTNode* node = ast_create(AST_CTRL_ELIF, NULL);
        ast_add_child(node, $5);
        ast_add_child(node, $7);
        ast_add_child($1, node);
        $$ = $1;
    }
    ;

else_clause:
    TOKEN_ELSE block { $$ = $2; }
    ;

while_stmt:
    TOKEN_WHILE TOKEN_LPAREN expression TOKEN_RPAREN block {
        ASTNode* node = ast_create(AST_CTRL_WHILE, $1);
        ast_add_child(node, $3);
        ast_add_child(node, $5);
        $$ = node;
    }
    ;

for_stmt:
    TOKEN_FOR TOKEN_IDENTIFIER TOKEN_FROM expression TOKEN_TO expression block {
        ASTNode* node = ast_create(AST_CTRL_FOR_RANGE, $1);
        ast_add_child(node, ast_create(AST_EXPR_IDENT, $2));
        ast_add_child(node, $4);
        ast_add_child(node, $6);
        ast_add_child(node, $7);
        $$ = node;
    }
    | TOKEN_FOR TOKEN_IDENTIFIER TOKEN_IN expression block {
        ASTNode* node = ast_create(AST_CTRL_FOR_IN, $1);
        ast_add_child(node, ast_create(AST_EXPR_IDENT, $2));
        ast_add_child(node, $4);
        ast_add_child(node, $5);
        $$ = node;
    }
    ;

try_stmt:
    TOKEN_TRY block catch_clause {
        ASTNode* node = ast_create(AST_CTRL_TRY, $1);
        ast_add_child(node, $2);
        ast_add_child(node, $3);
        $$ = node;
    }
    | TOKEN_TRY block catch_clause finally_clause {
        ASTNode* node = ast_create(AST_CTRL_TRY, $1);
        ast_add_child(node, $2);
        ast_add_child(node, $3);
        ast_add_child(node, $4);
        $$ = node;
    }
    | TOKEN_TRY block finally_clause {
        ASTNode* node = ast_create(AST_CTRL_TRY, $1);
        ast_add_child(node, $2);
        ast_add_child(node, $3);
        $$ = node;
    }
    ;

catch_clause:
    TOKEN_CATCH TOKEN_LPAREN TOKEN_IDENTIFIER TOKEN_RPAREN block {
        ASTNode* node = ast_create(AST_CTRL_CATCH, $1);
        ast_add_child(node, ast_create(AST_EXPR_IDENT, $3));
        ast_add_child(node, $5);
        $$ = node;
    }
    | TOKEN_CATCH block {
        ASTNode* node = ast_create(AST_CTRL_CATCH, $1);
        ast_add_child(node, $2);
        $$ = node;
    }
    ;

finally_clause:
    TOKEN_FINALLY block {
        ASTNode* node = ast_create(AST_CTRL_FINALLY, $1);
        ast_add_child(node, $2);
        $$ = node;
    }
    ;

dict_literal:
    TOKEN_LBRACE dict_entries TOKEN_RBRACE { $$ = $2; }
    | TOKEN_LBRACE TOKEN_RBRACE { $$ = ast_create(AST_LIT_DICT, NULL); }
    ;

dict_entries:
    dict_entry {
        ASTNode* dict = ast_create(AST_LIT_DICT, NULL);
        ast_add_child(dict, $1);
        $$ = dict;
    }
    | dict_entries TOKEN_COMMA dict_entry {
        ast_add_child($1, $3);
        $$ = $1;
    }
    | dict_entries TOKEN_NEWLINE { $$ = $1; }
    ;

dict_entry:
    TOKEN_STR_LITERAL TOKEN_COLON expression {
        ASTNode* entry = ast_create(AST_LIT_DICT_ENTRY, NULL);
        ast_add_child(entry, ast_create(AST_LIT_STRING, $1));
        ast_add_child(entry, $3);
        $$ = entry;
    }
    | TOKEN_IDENTIFIER TOKEN_COLON expression {
        ASTNode* entry = ast_create(AST_LIT_DICT_ENTRY, NULL);
        ast_add_child(entry, ast_create(AST_EXPR_IDENT, $1));
        ast_add_child(entry, $3);
        $$ = entry;
    }
    ;

list_literal:
    TOKEN_LBRACKET list_items TOKEN_RBRACKET { $$ = $2; }
    | TOKEN_LBRACKET TOKEN_RBRACKET { $$ = ast_create(AST_LIT_LIST, NULL); }
    ;

list_items:
    expression {
        ASTNode* list = ast_create(AST_LIT_LIST, NULL);
        ast_add_child(list, $1);
        $$ = list;
    }
    | list_items TOKEN_COMMA expression {
        ast_add_child($1, $3);
        $$ = $1;
    }
    ;

arg_list_opt:
    { $$ = NULL; }
    | arg_list { $$ = $1; }
    ;

arg_list:
    expression {
        ASTNode* args = ast_create(AST_AUX_ARG_LIST, NULL);
        ast_add_child(args, $1);
        $$ = args;
    }
    | arg_list TOKEN_COMMA expression {
        ast_add_child($1, $3);
        $$ = $1;
    }
    ;

expression:
    TOKEN_INT_LITERAL { $$ = ast_create(AST_LIT_INT, $1); }
    | TOKEN_FLOAT_LITERAL { $$ = ast_create(AST_LIT_FLOAT, $1); }
    | TOKEN_STR_LITERAL { $$ = ast_create(AST_LIT_STRING, $1); }
    | TOKEN_TRUE { $$ = ast_create(AST_LIT_BOOL, $1); }
    | TOKEN_FALSE { $$ = ast_create(AST_LIT_BOOL, $1); }
    | TOKEN_NULL { $$ = ast_create(AST_LIT_NULL, $1); }
    | TOKEN_IDENTIFIER { $$ = ast_create(AST_EXPR_IDENT, $1); }
    | TOKEN_THIS { $$ = ast_create(AST_EXPR_THIS, $1); }
    
    | expression TOKEN_PLUS expression {
        ASTNode* op = ast_create(AST_EXPR_BINARY, $2);
        ast_add_child(op, $1);
        ast_add_child(op, $3);
        $$ = op;
    }
    | expression TOKEN_MINUS expression {
        ASTNode* op = ast_create(AST_EXPR_BINARY, $2);
        ast_add_child(op, $1);
        ast_add_child(op, $3);
        $$ = op;
    }
    | expression TOKEN_MUL expression {
        ASTNode* op = ast_create(AST_EXPR_BINARY, $2);
        ast_add_child(op, $1);
        ast_add_child(op, $3);
        $$ = op;
    }
    | expression TOKEN_DIV expression {
        ASTNode* op = ast_create(AST_EXPR_BINARY, $2);
        ast_add_child(op, $1);
        ast_add_child(op, $3);
        $$ = op;
    }
    | expression TOKEN_MOD expression {
        ASTNode* op = ast_create(AST_EXPR_BINARY, $2);
        ast_add_child(op, $1);
        ast_add_child(op, $3);
        $$ = op;
    }
    | expression TOKEN_GT expression {
        ASTNode* op = ast_create(AST_EXPR_BINARY, $2);
        ast_add_child(op, $1);
        ast_add_child(op, $3);
        $$ = op;
    }
    | expression TOKEN_LT expression {
        ASTNode* op = ast_create(AST_EXPR_BINARY, $2);
        ast_add_child(op, $1);
        ast_add_child(op, $3);
        $$ = op;
    }
    | expression TOKEN_GTE expression {
        ASTNode* op = ast_create(AST_EXPR_BINARY, $2);
        ast_add_child(op, $1);
        ast_add_child(op, $3);
        $$ = op;
    }
    | expression TOKEN_LTE expression {
        ASTNode* op = ast_create(AST_EXPR_BINARY, $2);
        ast_add_child(op, $1);
        ast_add_child(op, $3);
        $$ = op;
    }
    | expression TOKEN_EQ expression {
        ASTNode* op = ast_create(AST_EXPR_BINARY, $2);
        ast_add_child(op, $1);
        ast_add_child(op, $3);
        $$ = op;
    }
    | expression TOKEN_NEQ expression {
        ASTNode* op = ast_create(AST_EXPR_BINARY, $2);
        ast_add_child(op, $1);
        ast_add_child(op, $3);
        $$ = op;
    }
    | expression TOKEN_AND expression {
        ASTNode* op = ast_create(AST_EXPR_BINARY, $2);
        ast_add_child(op, $1);
        ast_add_child(op, $3);
        $$ = op;
    }
    | expression TOKEN_OR expression {
        ASTNode* op = ast_create(AST_EXPR_BINARY, $2);
        ast_add_child(op, $1);
        ast_add_child(op, $3);
        $$ = op;
    }
    | expression TOKEN_XOR expression {
        ASTNode* op = ast_create(AST_EXPR_BINARY, $2);
        ast_add_child(op, $1);
        ast_add_child(op, $3);
        $$ = op;
    }
    | TOKEN_NOT expression {
        ASTNode* op = ast_create(AST_EXPR_UNARY, $1);
        ast_add_child(op, $2);
        $$ = op;
    }
    | TOKEN_MINUS expression %prec TOKEN_NOT {
        ASTNode* op = ast_create(AST_EXPR_UNARY, $1);
        ast_add_child(op, $2);
        $$ = op;
    }
    | TOKEN_LPAREN expression TOKEN_RPAREN { $$ = $2; }
    
    | expression TOKEN_DOT TOKEN_IDENTIFIER {
        ASTNode* node = ast_create(AST_EXPR_MEMBER, $3);
        ast_add_child(node, $1);
        $$ = node;
    }
    | expression TOKEN_LBRACKET expression TOKEN_RBRACKET {
        ASTNode* node = ast_create(AST_EXPR_INDEX, NULL);
        ast_add_child(node, $1);
        ast_add_child(node, $3);
        $$ = node;
    }
    | TOKEN_IDENTIFIER TOKEN_LPAREN arg_list_opt TOKEN_RPAREN {
        ASTNode* node = ast_create(AST_EXPR_CALL, $1);
        if ($3 != NULL) ast_add_child(node, $3);
        $$ = node;
    }
    | expression TOKEN_DOT TOKEN_IDENTIFIER TOKEN_LPAREN arg_list_opt TOKEN_RPAREN {
        ASTNode* node = ast_create(AST_EXPR_CALL, $3);
        ast_add_child(node, $1);
        if ($5 != NULL) ast_add_child(node, $5);
        $$ = node;
    }
    | TOKEN_NEW TOKEN_IDENTIFIER TOKEN_LPAREN arg_list_opt TOKEN_RPAREN {
        ASTNode* node = ast_create(AST_EXPR_NEW, $2);
        if ($4 != NULL) ast_add_child(node, $4);
        $$ = node;
    }
    | list_literal { $$ = $1; }
    | dict_literal { $$ = $1; }
    ;

%%

int main(int argc, char *argv[]) {
    if (argc > 1) {
        FILE* file = fopen(argv[1], "r");
        if (!file) {
            perror("Error opening file");
            return 1;
        }
        yyin = file;
    }

    if (yyparse() == 0 && ast_root != NULL) {
        printf("Parsing completed successfully.\n\n");
        printf("=== Abstract Syntax Tree ===\n");
        ast_print(ast_root, 0);
        ast_free(ast_root);
    } else {
        printf("Parsing failed.\n");
        return 1;
    }

    return 0;
}
