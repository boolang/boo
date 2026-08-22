f map_test() {
    v map = Map_new<S>();
    Map_insert<S>(&map, "a", "x");
    Map_insert<S>(&map, "b", "y");
    Map_insert<S>(&map, "a", "z");
    print("a is:");
    print(O_get<S>(Map_get<S>(map, "a")));
    print("b is:");
    print(O_get<S>(Map_get<S>(map, "b")));
    i (Map_contains<S>(map, "a")) {
        print("Map contains key 'a'");
    } e {
        print("Map doesn't contain key 'a'");
    }
    i (Map_contains<S>(map, "c")) {
        print("Map contains key 'c'");
    } e {
        print("Map doesn't contain key 'c'");
    }
}

f main() {
    // l one = Expr::Literal(LiteralExpr::Int(1));
    // v arguments = V_new<ArgumentValue>();
    // V_push<ArgumentValue>(
    //     &arguments,
    //     ArgumentValue::Immutable(one)
    // );
    // 
    // v stmts = V_new<Stmt>();
    // V_push<Stmt>(&stmts, Stmt::Expr(Expr::FunctionCall(FunctionCallExpr {
    //     ident: "exit",
    //     generic_parameters: V_new<Type>(),
    //     arguments: arguments
    // })));

    // v decls = V_new<Decl>();
    // V_push<Decl>(&decls, Decl::Function(Function {
    //     signature: FunctionSignature {
    //         ident: "main",
    //         generic_parameters: V_new<S>(),
    //         parameters: V_new<Parameter>(),
    //         ret: O_none<Type>()
    //     },
    //     stmts: stmts
    // }));
    l code = read("../ktest.boo");
    l ast = parse(code);
    kompile(ast);
}
