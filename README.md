# Custom Language Parser

This project implements a parser for a custom programming language. The parser reads source code, breaks it into tokens using a lexer, and builds an Abstract Syntax Tree (AST) that represents the structure of the program.

## Project Files

### Core Files

**lexer.l** - The lexer specification written for Flex. It defines how the source code is broken into tokens like keywords, identifiers, numbers, strings, and operators. The lexer tracks line and column numbers for error reporting.

**parser.y** - The parser specification written for Bison. It defines the grammar rules that describe how tokens can be combined to form valid programs. When the parser recognizes a pattern, it builds the corresponding AST node.

**ast.h** - Defines the AST node types and the ASTNode structure. Each node has a type (like AST_DECL_VAR or AST_EXPR_BINARY), an optional token for storing values, and a list of child nodes.

**ast.c** - Implements the AST functions: creating nodes, adding children, printing the tree for debugging, and freeing memory.


## Usage

Run bison to generate the parser, flex to generate the lexer, then compile everything together:

```
bison -d parser.y
flex lexer.l
gcc -o parser parser.tab.c lex.yy.c ast.c
```

Or use the Makefile if you have make installed:

```
make
```

## Running

Pass a source file as an argument:

```
./parser test.script
```

The parser will print whether parsing succeeded and display the AST.

## Language Grammar

The language uses newlines as statement terminators instead of semicolons. Blocks use curly braces.

### Types

The language supports these built-in types: `int`, `float`, `str`, `bool`, `list`, `dict`. You can also use `var` for untyped declarations.

### Variables

Variables are declared with a type followed by the name and initial value:

```
int x = 42
float pi = 3.14
str name = "hello"
var anything = 100
```

### Functions

Functions are declared with the `funk` keyword. The return type comes before `funk`:

```
int funk add(a, b) {
    return a + b
}

var funk greet(name) {
    print(name)
}
```

Parameters can optionally have types:

```
int funk multiply(int x, int y) {
    return x * y
}
```

### Classes

Classes are declared with the `class` keyword and can contain functions and variables:

```
class Person {
    str funk getName() {
        return this.name
    }
}
```

Use `new` to create instances:

```
var p = new Person()
```

### Control Flow

If statements come in two forms. The short form uses `then`:

```
if x > 0 then x
```

The block form uses parentheses and braces:

```
if (x > 10) {
    print("big")
} else if (x > 5) {
    print("medium")
} else {
    print("small")
}
```

While loops:

```
while (condition) {
    // body
    break
    continue
}
```

For loops support two styles. Range-based iteration:

```
for i from 0 to 10 {
    print(i)
}
```

Collection iteration:

```
for item in myList {
    print(item)
}
```

### Data Structures

Lists use square brackets:

```
list numbers = [1, 2, 3, 4, 5]
var first = numbers[0]
```

Dictionaries use curly braces with key-value pairs:

```
dict config = {"host": "localhost", "port": 8080}
var host = config["host"]
```

### Exception Handling

Use try-catch-finally for error handling:

```
try {
    throw "something went wrong"
} catch (e) {
    print(e)
} finally {
    print("cleanup")
}
```

### Other Features

Print outputs values:

```
print("hello", x, y)
```

Demand is an assertion that the condition must be true:

```
demand x > 0
```

### Operators

Arithmetic: `+`, `-`, `*`, `/`, `%`

Comparison: `>`, `<`, `>=`, `<=`, `==`, `!=`

Logical: `&&`, `||`, `!`, `^` (xor)

Assignment: `=`

Member access: `.` (e.g., `obj.field`)

Index access: `[]` (e.g., `arr[0]`)

## AST Node Types

The AST uses a naming convention where the prefix indicates the category:

- `AST_LIT_*` - Literal values (int, float, string, bool, null, list, dict)
- `AST_EXPR_*` - Expressions (binary operations, function calls, member access)
- `AST_DECL_*` - Declarations (variables, functions, classes)
- `AST_STMT_*` - Statements (return, break, continue, print)
- `AST_CTRL_*` - Control flow (if, while, for, try/catch)
- `AST_AUX_*` - Auxiliary nodes (parameter lists, argument lists)

This naming makes it easy to understand what each node represents when reading the code or debugging the AST output.
