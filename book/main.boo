f main() {
    // TODO: Get target file/files from argv
    l src = "../book/ast.boo";
    l contents = read(src);

    parse(contents);
}
