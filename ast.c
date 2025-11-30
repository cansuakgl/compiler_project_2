#include "ast.h"
#include <string.h>

ASTNode* ast_create(ASTNodeType type, Token* token) {
    ASTNode* node = malloc(sizeof(ASTNode));
    node->type = type;
    node->token = token;   
    node->children = NULL;
    node->child_count = 0;
    return node;
}

void ast_add_child(ASTNode* parent, ASTNode* child) {
    parent->child_count++;
    parent->children = realloc(parent->children, sizeof(ASTNode*) * parent->child_count);
    parent->children[parent->child_count - 1] = child;
}
 
static const char* ast_type_name(ASTNodeType type) {
    switch(type) {
        case AST_PROGRAM:           return "Program";
        case AST_BLOCK:             return "Block";
        case AST_LIT_INT:           return "Lit.Int";
        case AST_LIT_FLOAT:         return "Lit.Float";
        case AST_LIT_STRING:        return "Lit.String";
        case AST_LIT_BOOL:          return "Lit.Bool";
        case AST_LIT_NULL:          return "Lit.Null";
        case AST_LIT_LIST:          return "Lit.List";
        case AST_LIT_DICT:          return "Lit.Dict";
        case AST_LIT_DICT_ENTRY:    return "Lit.DictEntry";
        case AST_EXPR_IDENT:        return "Expr.Ident";
        case AST_EXPR_BINARY:       return "Expr.Binary";
        case AST_EXPR_UNARY:        return "Expr.Unary";
        case AST_EXPR_CALL:         return "Expr.Call";
        case AST_EXPR_INDEX:        return "Expr.Index";
        case AST_EXPR_MEMBER:       return "Expr.Member";
        case AST_EXPR_NEW:          return "Expr.New";
        case AST_EXPR_THIS:         return "Expr.This";
        case AST_EXPR_ASSIGN:       return "Expr.Assign";
        case AST_DECL_VAR:          return "Decl.Var";
        case AST_DECL_FUNC:         return "Decl.Func";
        case AST_DECL_CLASS:        return "Decl.Class";
        case AST_STMT_EXPR:         return "Stmt.Expr";
        case AST_STMT_RETURN:       return "Stmt.Return";
        case AST_STMT_BREAK:        return "Stmt.Break";
        case AST_STMT_CONTINUE:     return "Stmt.Continue";
        case AST_STMT_THROW:        return "Stmt.Throw";
        case AST_STMT_PRINT:        return "Stmt.Print";
        case AST_STMT_DEMAND:       return "Stmt.Demand";
        case AST_CTRL_IF:           return "Ctrl.If";
        case AST_CTRL_IF_ELSE:      return "Ctrl.IfElse";
        case AST_CTRL_ELIF:         return "Ctrl.Elif";
        case AST_CTRL_WHILE:        return "Ctrl.While";
        case AST_CTRL_FOR_RANGE:    return "Ctrl.ForRange";
        case AST_CTRL_FOR_IN:       return "Ctrl.ForIn";
        case AST_CTRL_TRY:          return "Ctrl.Try";
        case AST_CTRL_CATCH:        return "Ctrl.Catch";
        case AST_CTRL_FINALLY:      return "Ctrl.Finally";
        case AST_AUX_PARAM_LIST:    return "Aux.ParamList";
        case AST_AUX_ARG_LIST:      return "Aux.ArgList";
        case AST_AUX_CLASS_BODY:    return "Aux.ClassBody";
        default:                    return "Unknown";
    }
}

void ast_print(ASTNode* node, int indent) {
    if (!node) return;

    for (int i = 0; i < indent; i++) printf("  ");

    const char* name = ast_type_name(node->type);
    if (node->token && node->token->value) {
        printf("%s: %s\n", name, node->token->value);
    } else {
        printf("%s\n", name);
    }

    for (int i = 0; i < node->child_count; i++) {
        ast_print(node->children[i], indent + 1);
    }
}

void ast_free(ASTNode* node) {
    if (!node) return;
    for (int i = 0; i < node->child_count; i++) {
        ast_free(node->children[i]);
    }
    free(node->children);
    free(node);
}
