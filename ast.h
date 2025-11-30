#ifndef AST_H
#define AST_H
#include <stdio.h>
#include <stdlib.h>
#include "parser.tab.h"  

typedef enum {
    AST_PROGRAM,
    AST_BLOCK,
    
    AST_LIT_INT,
    AST_LIT_FLOAT,
    AST_LIT_STRING,
    AST_LIT_BOOL,
    AST_LIT_NULL,
    AST_LIT_LIST,
    AST_LIT_DICT,
    AST_LIT_DICT_ENTRY,
    
    AST_EXPR_IDENT,         
    AST_EXPR_BINARY,
    AST_EXPR_UNARY,
    AST_EXPR_CALL,
    AST_EXPR_INDEX,
    AST_EXPR_MEMBER,
    AST_EXPR_NEW,           
    AST_EXPR_THIS,        
    AST_EXPR_ASSIGN,      
    
    AST_DECL_VAR,         
    AST_DECL_FUNC,     
    AST_DECL_CLASS,       

    AST_STMT_EXPR,         
    AST_STMT_RETURN,        
    AST_STMT_BREAK,       
    AST_STMT_CONTINUE,      
    AST_STMT_THROW,       
    AST_STMT_PRINT,         
    AST_STMT_DEMAND,        
    
    AST_CTRL_IF,            
    AST_CTRL_IF_ELSE,       
    AST_CTRL_ELIF,          
    AST_CTRL_WHILE,         
    AST_CTRL_FOR_RANGE,     
    AST_CTRL_FOR_IN,        
    AST_CTRL_TRY,
    AST_CTRL_CATCH,
    AST_CTRL_FINALLY,

    AST_AUX_PARAM_LIST,
    AST_AUX_ARG_LIST,
    AST_AUX_CLASS_BODY,
} ASTNodeType;

typedef struct ASTNode {
    ASTNodeType type;
    Token* token;            
    struct ASTNode** children; 
    int child_count;
} ASTNode;


ASTNode* ast_create(ASTNodeType type, Token* token);
void ast_add_child(ASTNode* parent, ASTNode* child);
void ast_print(ASTNode* node, int indent);
void ast_free(ASTNode* node);

#endif
