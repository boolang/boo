f main() {
    // TODO: Get target file/files from argv
    l ast = "../book/ast.boo";
    l ast_contents = read(ast);

    l lexer = "../book/lexer.boo";
    l lexer_contents = read(lexer);

    l contents = S_concat(ast_contents, lexer_contents);

    parse(contents);
}

f S_concat(first: S, second: S) -> S {
    v acc = first;
    v acc2 = second;

    w (not(S_is_empty(acc2))) {
        acc = S_push(acc, acc2[0]);
        acc2 = S_advance(acc2, 1);
    }

    r acc;
}
