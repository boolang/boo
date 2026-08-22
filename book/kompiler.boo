s BuiltinFunction {
    params: V<Parameter>,
    asm: S
}

s Ctx {
    structs: Map<Struct>,
    enums: Map<Enum>,
    fns: Map<Function>,
    builtin_fns: Map<BuiltinFunction>
}

f Ctx_load_builtin(ctx: &Ctx, ident: S, params: V<Parameter>) {
    l asm = read(S_concat("builtins/", ident));
    l builtin = BuiltinFunction {
        params: params,
        asm: asm
    };
    Map_insert<BuiltinFunction>(&ctx.builtin_fns, ident, builtin);
}

f kompile(ast: Ast) {
    v ctx = Ctx {
        structs: Map_new<Struct>(),
        enums: Map_new<Enum>(),
        fns: Map_new<Function>(),
        builtin_fns: Map_new<BuiltinFunction>()
    };

    v exit_params = V_new<Parameter>();
    V_push<Parameter>(&exit_params, Parameter {
        label: "status",
        ty: ArgumentType {
            ty: Type {
                ident: "I",
                generic_parameters: V_new<Type>()
            },
            mutable: n
        }
    });
    Ctx_load_builtin(&ctx, "exit", exit_params);

    v idx = 0;
    w (I_lt(idx, V_len<Decl>(ast.decls))) {
        l decl = V_get<Decl>(ast.decls, idx);
        m (decl) {
            Decl::Struct(struct) => {
                Map_insert<Struct>(&ctx.structs, struct.ident, struct);
            }
            Decl::Enum(enum) => {
                Map_insert<Enum>(&ctx.enums, enum.ident, enum);
            }
            Decl::Function(function) => {
                Map_insert<Function>(&ctx.fns, function.signature.ident, function);
            }
        }
        idx = I_add(idx, 1);
    }

    print("# structs:");
    print(I_to_string(Map_count<Struct>(ctx.structs)));
    print("# enums:");
    print(I_to_string(Map_count<Enum>(ctx.enums)));
    print("# functions:");
    print(I_to_string(Map_count<Function>(ctx.fns)));

    l main_fn = Map_get<Function>(ctx.fns, "main");
    i (O_is_some<Function>(main_fn)) {
        kompile_fn(ctx, O_get<Function>(main_fn));
    }
}

f kompile_fn(ctx: Ctx, fn: Function) {
    v idx = 0;
    w (I_lt(idx, V_len<Stmt>(fn.stmts))) {
        l stmt = V_get<Stmt>(fn.stmts, idx);
        print("Kompiling stmt");
        kompile_stmt(ctx, stmt);
        idx = I_add(idx, 1);
    }
}

f kompile_stmt(ctx: Ctx, stmt: Stmt) {
    m (stmt) {
        Stmt::Expr(expr) => {
            kompile_expr(ctx, expr);
        }
        _ => {
            print("Unsupported stmt type");
        }
    }
}

f kompile_expr(ctx: Ctx, expr: Expr) {
    m (expr) {
        Expr::FunctionCall(call) => {
            kompile_fn_call(ctx, call);
        }
        _ => {
            print("Unsupported expr type");
        }
    }
}

f exit() {
    nonexistent();
}

f kompile_fn_call(ctx: Ctx, call: FunctionCallExpr) {
    l maybe_fn = Map_get<Function>(ctx.fns, call.ident);
    // l fn: Function;
    i (O_is_none<Function>(maybe_fn)) {
        print("No such function");
        print(call.ident);
        exit();
    } e {
        fn = O_get<Function>(maybe_fn);
    }
    print("Function has this many arguments");
    print(I_to_string(V_len<Parameter>(fn.parameters)));
}
