f main() {
    // TODO: Get target file/files from argv
    l ast = "../book/ast.boo";
    l ast_contents = read(ast);

    l lexer = "../book/lexer.boo";
    l lexer_contents = read(lexer);

    l contents = S_concat(ast_contents, lexer_contents);

    parse(contents);
}
