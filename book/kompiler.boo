s BuiltinFunction {
    params: V<Parameter>,
    asm: S
}

s Ctx {
    structs: Map<Struct>,
    enums: Map<Enum>,
    fns: Map<Function>,
    builtin_fns: Map<BuiltinFunction>,
    constants: V<Constant>,
    wr: AsmWriter
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
        builtin_fns: Map_new<BuiltinFunction>(),
        constants: V_new<Constant>(),
        wr: AsmWriter {
            buf: "",
            jumps: Map_new<I>(),
            pending_jumps: Map_new<V<I>>(),
            locals: V_new<Local>()
        }
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
        kompile_fn(&ctx, O_get<Function>(main_fn));
    }
}

f kompile_fn(ctx: &Ctx, fn: Function) {
    v idx = 0;
    w (I_lt(idx, V_len<Stmt>(fn.stmts))) {
        l stmt = V_get<Stmt>(fn.stmts, idx);
        print("Kompiling stmt");
        kompile_stmt(&ctx, stmt);
        idx = I_add(idx, 1);
    }
}

f kompile_stmt(ctx: &Ctx, stmt: Stmt) {
    m (stmt) {
        Stmt::Expr(expr) => {
            kompile_expr(&ctx, expr);
        }
        _ => {
            print("Unsupported stmt type");
        }
    }
}

f kompile_expr(ctx: &Ctx, expr: Expr) {
    m (expr) {
        Expr::FunctionCall(call) => {
            kompile_fn_call(&ctx, call);
        }
        _ => {
            print("Unsupported expr type");
        }
    }
}

f exit() {
    nonexistent();
}

f kompile_fn_call(ctx: &Ctx, call: FunctionCallExpr) {
    l maybe_fn = Map_get<Function>(ctx.fns, call.ident);
    i (O_is_none<Function>(maybe_fn)) {
        kompile_builtin_fn_call(&ctx, call);
    } e {
        l fn = O_get<Function>(maybe_fn);
        print("Function has this many arguments");
        print(I_to_string(V_len<Parameter>(fn.parameters)));
    }
}

f resolve_type(ctx: Ctx, type: Type) -> Type {
    r type;
}

f resolve_types(ctx: Ctx, types: V<Type>) -> V<Type> {
    v resolved = V_new<Type>();
    l len = V_len<Type>(types);
    v idx = 0;
    w (I_lt(idx, len)) {
        l type = V_get<Type>(types, idx);
        V_push<Type>(resolved, resolve_type(ctx, type));
    }
    r resolved;
}

f V_Type_eq(self: V<Type>, other: V<Type>) -> B {
    l len = V_len<Type>(self);
    i (not(I_eq(len, V_len<Type>(other)))) {
        r n;
    }

    v idx = 0;
    w (I_lt(idx, len)) {
        l type1 = V_get<Type>(self, idx);
        l type2 = V_get<Type>(other, idx);
        i (not(Type_eq(type1, type2))) {
            r n;
        }
        idx = I_add(idx, 1);
    }

    r y;
}

f Type_eq(self: Type, other: Type) -> B {
    r and(
        S_eq(self.ident, other.ident),
        V_Type_eq(self.generic_parameters, other.generic_parameters)
    );
}

f kompile_builtin_fn_call(ctx: &Ctx, call: FunctionCallExpr) {
    l maybe_fn = Map_get<BuiltinFunction>(ctx.builtin_fns, call.ident);
    i (O_is_none<BuiltinFunction>(maybe_fn)) {
        print(S_concat("Function does not exist with name: ", call.ident));
        exit();
    } e {
        l fn = O_get<BuiltinFunction>(maybe_fn);
        print("Function has this many arguments");
        print(I_to_string(V_len<Parameter>(fn.params)));

        l nparams = V_len<Parameter>(fn.params);
        l nargs = V_len<ArgumentValue>(call.arguments);
        i (not(I_eq(nparams, nargs))) {
            print("Error in function:");
            print(call.ident);
            print("Invalid number of function params, expected:");
            print(I_to_string(nparams));
            print("But got");
            print(I_to_string(nargs));
            exit();
        }
    }
}
