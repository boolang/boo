s BuiltinFunction {
    params: V<Parameter>,
    asm: S
}

s Structinstance {
    key: MMKey,
    fields: V<Field>,
}

s FunctionInstance {
    key: MMKey,
    parameters: V<Parameter>,
    ret: O<Type>,
    stmts: V<Stmt>,
}

s Ctx {
    structs: Map<Struct>,
    enums: Map<Enum>,
    fns: Map<Function>,
    fn_q: Q<S>,
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

f Ctx_load_stdlib_builtins(ctx: &Ctx) {
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

    v i_eq_params = V_new<Parameter>();
    V_push<Parameter>(&i_eq_params, Parameter {
        label: "first",
        ty: ArgumentType {
            ty: Type {
                ident: "I",
                generic_parameters: V_new<Type>()
            },
            mutable: n
        }
    });
    V_push<Parameter>(&i_eq_params, Parameter {
        label: "second",
        ty: ArgumentType {
            ty: Type {
                ident: "I",
                generic_parameters: V_new<Type>()
            },
            mutable: n
        }
    });
    Ctx_load_builtin(&ctx, "I_eq", i_eq_params);

    v malloc_params = V_new<Parameter>();
    V_push<Parameter>(&malloc_params, Parameter {
        label: "size",
        ty: ArgumentType {
            ty: Type {
                ident: "I",
                generic_parameters: V_new<Type>()
            },
            mutable: n
        }
    });
    Ctx_load_builtin(&ctx, "malloc", malloc_params);
}

f kompile(ast: Ast) {
    v ctx = Ctx {
        structs: Map_new<Struct>(),
        enums: Map_new<Enum>(),
        fns: Map_new<Function>(),
        fn_q: Q_new<MMKey>(),
        builtin_fns: Map_new<BuiltinFunction>(),
        constants: V_new<Constant>(),
        wr: AsmWriter {
            base_addr: 0x400000,
            buf: "",
            jumps: MMap_new<I>(),
            pending_jumps: MMap_new<V<I>>(),
            constant_loads: Map_new<V<PendingMov>>(),
            function_prelude_location: -1,
            locals: V_new<Local>()
        }
    };

    Ctx_load_stdlib_builtins(&ctx);

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

    emit_builtins(&ctx);
    l entry_point = I_add(ctx.wr.base_addr, AW_idx(ctx.wr));

    Q_push<MMKey>(&ctx.fn_q, MMKey { ident: "main", generic_args: V_new<Type>() });
    v fn = Q_pop<MMKey>(&ctx.fn_q);
    w (O_is_some<MMKey>(fn)) {
        l key = O_get<MMKey>(fn);
        l fn_ast = instantiate_fn(&ctx, key);
        i (O_is_some<FunctionInstance>(fn_ast)) {
            print(S_concat("Kompiling function ", key.ident));
            kompile_fn(&ctx, O_get<FunctionInstance>(fn_ast));
        } e {
            print(S_concat("Could not find function ", fn));
        }
        fn = Q_pop<MMKey>(&ctx.fn_q);
    }

    write_to_file("bin_raw", ctx.wr.buf);
    l elf = gen_elf(entry_point, 0x400000, S_len(ctx.wr.buf), ctx.wr.buf);
    write_to_file("bin", elf);
    print("boo!");
}

f emit_builtins(ctx: &Ctx) {
    v idx = 0;
    w (I_lt(idx, Map_count<BuiltinFunction>(ctx.builtin_fns))) {
        l entry = V_get<MapEntry<BuiltinFunction>>(ctx.builtin_fns.storage, idx);
        AW_emit_builtin_function(&ctx.wr, entry.key, entry.value);
        idx = I_add(idx, 1);
    }
}

f instantiate_fn(ctx: &Ctx, key: MMKey) -> O<FunctionInstance> {
    l fn_ast = Map_get<Function>(ctx.fns, key.ident);
    i (O_is_none<Function>(fn_ast)) {
        r O_none<FunctionInstance>();
    }

    l fn = O_get<Function>(fn_ast);

    v new_params = V_new<Parameter>();
    v idx = 0;
    w (I_lt(idx, V_len<Parameter>(fn.signature.parameters))) {
        v parameter = V_get<Parameter>(fn.signature.parameters, idx);
        parameter.ty.ty = instantiate_type(parameter.ty.ty, fn.signature.generic_parameters, key.generic_args);
        V_push<Parameter>(&new_params, parameter);
        idx = I_add(idx, 1);
    }

    r O_some<FunctionInstance>(FunctionInstance {
        key: key,
        parameters: new_params,
        ret: fn.signature.ret,
        stmts: fn.stmts
    });
}

f instantiate_type(type: Type, params: V<S>, args: V<Type>) -> Type {
    l param_idx = V_find_string(params, type.ident);
    i (not(I_eq(param_idx, -1))) {
        r V_get<Type>(args, param_idx);
    }

    v new_type = type;
    v idx = 0;
    w (I_lt(idx, V_len<Type>(type.generic_parameters))) {
        V_set<Type>(
            &type.generic_parameters,
            instantiate_type(V_get<Type>(type.generic_parameters, idx), params, args)
        );
        idx = I_add(idx, 1);
    }

    r new_type;
}

f kompile_fn(ctx: &Ctx, fn: FunctionInstance) {
    AW_emit_dummy_function_prelude(&ctx.wr, fn.key);
    kompile_block(&ctx, fn.stmts);
    AW_finalize_function(&ctx.wr);
}

f kompile_block(ctx: &Ctx, block: V<Stmt>) {
    v idx = 0;
    w (I_lt(idx, V_len<Stmt>(block))) {
        l stmt = V_get<Stmt>(block, idx);
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
        Stmt::If(if) => {
            // s IfBlock {
            //     condition: Expr,
            //     stmts: V<Stmt>,
            // }

            // s ElseBlock {
            //     stmts: V<Stmt>,
            // }

            // s IfStmt {
            //     if_blocks: V<IfBlock>,
            //     else_block: O<ElseBlock>,
            // }

            v next_cond_instr = O_none<I>();
            v leave_instrs = V_new<I>();

            v idx = 0;
            w (I_lt(idx, V_len<IfBlock>(if.if_blocks))) {
                l block = V_get<IfBlock>(if.if_blocks, idx);
                i (O_is_some<I>(next_cond_instr)) {
                    AW_overwrite_jump(&ctx.wr, O_get<I>(next_cond_instr), AW_idx(ctx.wr));
                }

                l expr = kompile_expr(&ctx, block.condition);

                next_cond_instr = O_some<I>(AW_create_overwritable_jz(&ctx.wr));

                kompile_block(&ctx, block.stmts);

                V_push<I>(&leave_instrs, AW_create_overwritable_jump(&ctx.wr));

                idx = I_add(idx, 1);
            }

            AW_overwrite_jump(&ctx.wr, O_get<I>(next_cond_instr), AW_idx(ctx.wr));

            i (O_is_some<ElseBlock>(if.else_block)) {
                kompile_block(&ctx, O_get<ElseBlock>(if.else_block).stmts);
            }

            idx = 0;
            w (I_lt(idx, V_len<I>(leave_instrs))) {
                AW_overwrite_jump(&ctx.wr, V_get<I>(leave_instrs, idx), AW_idx(ctx.wr));
                idx = I_add(idx, 1);
            }
        }
        _ => {
            print("Unsupported stmt type");
        }
    }
}

s ExprResult {
    // The index of the local that stores the result
    local: I,
    type: Type,
    size: I
}

f kompile_expr(ctx: &Ctx, expr: Expr) -> ExprResult {
    m (expr) {
        Expr::FunctionCall(call) => {
            kompile_fn_call(&ctx, call);
            r ExprResult {
                local: create_unit_local(&ctx),
                type: Type { ident: "U", generic_parameters: V_new<Type>() },
                size: 0
            };
        }
        Expr::Literal(literal) => {
            m (literal) {
                LiteralExpr::Int(int) => {
                    l idx = AW_create_local(&ctx.wr, "tmp_int_lit", 8);
                    AW_mov_constant_int_to_local(&ctx.wr, idx, 0, int);
                    l type = Type { ident: "I", generic_parameters: V_new<Type>() };
                    r ExprResult {
                        local: idx,
                        type: type,
                        size: 8
                    };
                }
                LiteralExpr::Bool(bool) => {
                    l idx = AW_create_local(&ctx.wr, "tmp_bool_lit", 8);
                    i (bool) {
                        AW_mov_constant_int_to_local(&ctx.wr, idx, 0, 1);
                    } e {
                        AW_mov_constant_int_to_local(&ctx.wr, idx, 0, 0);
                    }
                    l type = Type { ident: "B", generic_parameters: V_new<Type>() };
                    r ExprResult {
                        local: idx,
                        type: type,
                        size: 8
                    };
                }
                LiteralExpr::Char(char) => {
                    l idx = AW_create_local(&ctx.wr, "tmp_char_lit", 8);
                    AW_mov_constant_int_to_local(&ctx.wr, idx, 0, C_ord(char));
                    l type = Type { ident: "C", generic_parameters: V_new<Type>() };
                    r ExprResult {
                        local: idx,
                        type: type,
                        size: 8
                    };
                }
                _ => {
                    print("Non-integer literals not supported");
                    exit();
                }
            }
        }
        _ => {
            print("Unsupported expr type");
            exit();
        }
    }
}

f exit() {
    nonexistent();
}

// The value is a heap pointer
f Type_is_heap(type: Type) -> B {
    r S_eq(heap.ident, "H");
}

f prepare_fn_call_args(ctx: &Ctx, call: FunctionCallExpr) -> ExprResult {
    l ret = AW_create_local(&ctx.wr, "ret_val_addr", 8);

    v idx = I_sub(V_len<ArgumentValue>(call.arguments), 1);
    w (I_ge(idx, 0)) {
        l arg = V_get<ArgumentValue>(call.arguments, idx);
        m (arg) {
            ArgumentValue::Immutable(expr) => {
                l result = kompile_expr(&ctx, expr);
                AW_push_argument_ptr(&ctx.wr, result.local);
            }
            ArgumentValue::Mutable => {
                print("Mutable references not supported");
                exit();
            }
        }
        idx = I_sub(idx, 1);
    }
   
    r ExprResult {
        local: ret,
        type: Type { ident: "H", generic_parameters: V_new<Type>() },
        size: 8
    };
}

f create_unit_local(ctx: &Ctx) -> I {
    l idx = AW_create_local(&ctx.wr, "unit", 8);
    AW_mov_constant_int_to_local(&ctx.wr, idx, 0, 0);
    r idx;
}

f kompile_fn_call(ctx: &Ctx, call: FunctionCallExpr) -> ExprResult {
    l expr_result = prepare_fn_call_args(&ctx, call);

    l maybe_fn = Map_get<Function>(ctx.fns, call.ident);
    i (O_is_none<Function>(maybe_fn)) {
        kompile_builtin_fn_call(&ctx, call);
    } e {
        l fn = O_get<Function>(maybe_fn);
        l nparams = V_len<Parameter>(fn.signature.parameters);
        print("Function call");
        print(call.ident);
        print("Function has this many arguments");
        print(I_to_string(nparams));

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

        l key = MMKey { ident: call.ident, generic_args: call.generic_parameters };
        AW_call(&ctx.wr, key);
        queue_fn(&ctx, key);
    }

    l nargs = V_len<ArgumentValue>(call.arguments);
    AW_shrink_stack(&ctx.wr, I_mul(8, nargs));

    r expr_result;
}

f queue_fn(ctx: &Ctx, fn: MMKey) {
    i (Q_contains_mmkey(ctx.fn_q, fn)) {
        r;
    }
    Q_push<MMKey>(&ctx.fn_q, fn);
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

        AW_call(&ctx.wr, MMKey { ident: call.ident, generic_args: V_new<Type>() });
    }
}
