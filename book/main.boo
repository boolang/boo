f main() {
    // TODO: Get target file/files from argv
    v source_files = V_new<S>();
    V_push<S>(&source_files, "../book/ast.boo");
    V_push<S>(&source_files, "../book/helper.boo");

    v source = "";
    v idx = 0;
    w (not(I_eq(idx, V_len<S>(source_files)))) {
        source = S_concat(source, read(V_get<S>(source_files, idx)));
        idx = I_add(idx, 1);
    }

    parse(source);
}
