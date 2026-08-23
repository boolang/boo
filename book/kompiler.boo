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

s LocalVar {
    local: I,
    type: Type,
}

s Ctx {
    structs: Map<Struct>,
    enums: Map<Enum>,
    fns: Map<Function>,
    fn_q: Q<S>,
    locals: Map<Local>,
    loop_breaks: V<I>,
    loop_continue: I,
    builtin_fns: Map<BuiltinFunction>,
    constants: V<Constant>,
    // Maps arg name to arg index
    fn_args: Map<I>,
    wr: AsmWriter,
    types: Map<TypeInfo>,
    // Map from builtin type names sizes
    builtin_types: Map<I>,
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

    // NOTE: These don't follow Boo ABI, they are compiler helpers
    l empty_params = V_new<Parameter>();
    Ctx_load_builtin(&ctx, "make_str", empty_params);
    Ctx_load_builtin(&ctx, "copy_content", empty_params);

    v exit_params = V_new<Parameter>();
    V_push<Parameter>(&exit_params, Parameter {
        label: "status",
        ty: ArgumentType {
            ty: Type_new("I"),
            mutable: n
        }
    });
    Ctx_load_builtin(&ctx, "exit", exit_params);

    v print_params = V_new<Parameter>();
    V_push<Parameter>(&print_params, Parameter {
        label: "msg",
        ty: ArgumentType {
            ty: Type_new("S"),
            mutable: n
        }
    });
    Ctx_load_builtin(&ctx, "print", print_params);

    v read_count_params = V_new<Parameter>();
    V_push<Parameter>(&read_count_params, Parameter {
        label: "path",
        ty: ArgumentType {
            ty: Type_new("S"),
            mutable: n
        }
    });
    V_push<Parameter>(&read_count_params, Parameter {
        label: "count",
        ty: ArgumentType {
            ty: Type_new("I"),
            mutable: n
        }
    });
    Ctx_load_builtin(&ctx, "read_count", read_count_params);

    v i_eq_params = V_new<Parameter>();
    V_push<Parameter>(&i_eq_params, Parameter {
        label: "first",
        ty: ArgumentType {
            ty: Type_new("I"),
            mutable: n
        }
    });
    V_push<Parameter>(&i_eq_params, Parameter {
        label: "second",
        ty: ArgumentType {
            ty: Type_new("I"),
            mutable: n
        }
    });
    Ctx_load_builtin(&ctx, "I_eq", i_eq_params);

    v i_add_params = V_new<Parameter>();
    V_push<Parameter>(&i_add_params, Parameter {
        label: "first",
        ty: ArgumentType {
            ty: Type {
                ident: "I",
                generic_parameters: V_new<Type>()
            },
            mutable: n
        }
    });
    V_push<Parameter>(&i_add_params, Parameter {
        label: "second",
        ty: ArgumentType {
            ty: Type {
                ident: "I",
                generic_parameters: V_new<Type>()
            },
            mutable: n
        }
    });
    Ctx_load_builtin(&ctx, "I_add", i_add_params);

    v i_udiv_params = V_new<Parameter>();
    V_push<Parameter>(&i_udiv_params, Parameter {
        label: "first",
        ty: ArgumentType {
            ty: Type {
                ident: "I",
                generic_parameters: V_new<Type>()
            },
            mutable: n
        }
    });
    V_push<Parameter>(&i_udiv_params, Parameter {
        label: "second",
        ty: ArgumentType {
            ty: Type {
                ident: "I",
                generic_parameters: V_new<Type>()
            },
            mutable: n
        }
    });
    Ctx_load_builtin(&ctx, "I_udiv", i_udiv_params);

    v s_concat_params = V_new<Parameter>();
    V_push<Parameter>(&s_concat_params, Parameter {
        label: "first",
        ty: ArgumentType {
            ty: Type {
                ident: "S",
                generic_parameters: V_new<Type>()
            },
            mutable: n
        }
    });
    V_push<Parameter>(&s_concat_params, Parameter {
        label: "second",
        ty: ArgumentType {
            ty: Type {
                ident: "S",
                generic_parameters: V_new<Type>()
            },
            mutable: n
        }
    });
    Ctx_load_builtin(&ctx, "S_concat", s_concat_params);

    v s_len_params = V_new<Parameter>();
    V_push<Parameter>(&s_len_params, Parameter {
        label: "first",
        ty: ArgumentType {
            ty: Type {
                ident: "S",
                generic_parameters: V_new<Type>()
            },
            mutable: n
        }
    });
    Ctx_load_builtin(&ctx, "S_len", s_len_params);

    // vec ops
    v v_new_params = V_new<Parameter>();
    Ctx_load_builtin(&ctx, "V_new", v_new_params);

    v v_push_params = V_new<Parameter>();
    V_push<Parameter>(&v_push_params, Parameter {
        label: "vec",
        ty: ArgumentType {
            ty: Type {
                ident: "V",
                generic_parameters: V_new<Type>()
            },
            mutable: y
        }
    });
    V_push<Parameter>(&v_push_params, Parameter {
        label: "element",
        ty: ArgumentType {
            ty: Type {
                ident: "I", // TODO should be T but oh well
                generic_parameters: V_new<Type>()
            },
            mutable: n
        }
    });
    Ctx_load_builtin(&ctx, "V_push", v_push_params);

    v v_len_params = V_new<Parameter>();
    V_push<Parameter>(&v_len_params, Parameter {
        label: "vec",
        ty: ArgumentType {
            ty: Type {
                ident: "V",
                generic_parameters: V_new<Type>()
            },
            mutable: y
        }
    });
    Ctx_load_builtin(&ctx, "V_len", v_len_params);

    v v_get_params = V_new<Parameter>();
    V_push<Parameter>(&v_get_params, Parameter {
        label: "vec",
        ty: ArgumentType {
            ty: Type {
                ident: "V",
                generic_parameters: V_new<Type>()
            },
            mutable: y
        }
    });
    V_push<Parameter>(&v_get_params, Parameter {
        label: "idx",
        ty: ArgumentType {
            ty: Type {
                ident: "I",
                generic_parameters: V_new<Type>()
            },
            mutable: n
        }
    });
    Ctx_load_builtin(&ctx, "V_get", v_get_params);

    v v_set_params = V_new<Parameter>();
    V_push<Parameter>(&v_set_params, Parameter {
        label: "vec",
        ty: ArgumentType {
            ty: Type {
                ident: "V",
                generic_parameters: V_new<Type>()
            },
            mutable: y
        }
    });
    V_push<Parameter>(&v_set_params, Parameter {
        label: "idx",
        ty: ArgumentType {
            ty: Type {
                ident: "I",
                generic_parameters: V_new<Type>()
            },
            mutable: n
        }
    });
    V_push<Parameter>(&v_set_params, Parameter {
        label: "new_value",
        ty: ArgumentType {
            ty: Type {
                ident: "I", // TODO should be T but oh well
                generic_parameters: V_new<Type>()
            },
            mutable: n
        }
    });
    Ctx_load_builtin(&ctx, "V_set", v_set_params);
}

s TypeInfo {
    size: I
}

f kompile(ast: Ast) {
    v builtin_types = Map_new<I>();
    Map_insert<I>(&builtin_types, "C", 8);
    Map_insert<I>(&builtin_types, "U", 8);
    Map_insert<I>(&builtin_types, "I", 8);
    Map_insert<I>(&builtin_types, "B", 8);
    Map_insert<I>(&builtin_types, "S", 16);
    Map_insert<I>(&builtin_types, "V", 16);

    v ctx = Ctx {
        structs: Map_new<Struct>(),
        enums: Map_new<Enum>(),
        fns: Map_new<Function>(),
        fn_q: Q_new<MMKey>(),
        locals: Map_new<LocalVar>(),
        loop_breaks: V_new<I>(),
        loop_continue: 0,
        builtin_fns: Map_new<BuiltinFunction>(),
        constants: V_new<Constant>(),
        fn_args: Map_new<I>(),
        wr: AsmWriter {
            base_addr: 0x400000,
            buf: "",
            jumps: MMap_new<I>(),
            pending_jumps: MMap_new<V<I>>(),
            function_prelude_location: -1,
            locals: V_new<Local>(),
            local_map: Map_new<I>()
        },
        types: Map_new<TypeInfo>(),
        builtin_types: builtin_types
    };

    Ctx_load_stdlib_builtins(&ctx);

    v idx = 0;
    w (I_lt(idx, V_len<Decl>(ast.decls))) {
        l decl = V_get<Decl>(ast.decls, idx);
        m (decl) {
            Decl::Struct(struct) => {
                Map_insert<Struct>(&ctx.structs, struct.ident, struct);
                l info = TypeInfo { size: I_mul(V_len<Field>(struct.fields), 8) };
                Map_insert<TypeInfo>(&ctx.types, struct.ident, info);
            }
            Decl::Enum(enum) => {
                Map_insert<Enum>(&ctx.enums, enum.ident, enum);
                // TODO: Register type info in ctx.types
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

t FunctionLocal {
    Local(I),
    Argument(I)
}

f resolve_ident(ctx: Ctx, ident: S) -> FunctionLocal {
    l local_lookup = Map_get<I>(ctx.wr.local_map, ident);
    i (O_is_some<I>(local_lookup)) {
        r FunctionLocal::Local(O_get<I>(local_lookup));
    }

    l arg_lookup = Map_get<I>(ctx.fn_args, ident);
    i (O_is_some<I>(arg_lookup)) {
        r FunctionLocal::Argument(O_get<I>(arg_lookup));
    }

    print(S_concat("No such local/arg: ", ident));
    exit();
}

f kompile_fn(ctx: &Ctx, fn: FunctionInstance) {
    l prev_locals = ctx.locals;
    ctx.fn_args = Map_new<I>();

    AW_emit_dummy_function_prelude(&ctx.wr, fn.key);

    v idx = 0;
    w (I_lt(idx, V_len<Parameter>(fn.parameters))) {
        l parameter = V_get<Parameter>(fn.parameters, idx);
        Map_insert<I>(&ctx.fn_args, parameter.label, idx);
        idx = I_add(idx, 1);
    }

    kompile_block(&ctx, fn.stmts);
    AW_finalize_function(&ctx.wr);
    ctx.locals = prev_locals;
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
        Stmt::Return(return) => {
            i (O_is_some<Expr>(return)) {
                print("Compiling ret expr");
                kompile_expr(&ctx, O_get<Expr>(return));
            }
            print("Emitting ret instr");
            AW_ret(&ctx.wr);
        }
        Stmt::If(if) => {
            v next_cond_instr = O_none<I>();
            v leave_instrs = V_new<I>();

            v idx = 0;
            w (I_lt(idx, V_len<IfBlock>(if.if_blocks))) {
                l block = V_get<IfBlock>(if.if_blocks, idx);
                i (O_is_some<I>(next_cond_instr)) {
                    AW_overwrite_jump(&ctx.wr, O_get<I>(next_cond_instr), AW_idx(ctx.wr));
                }

                l expr = kompile_expr(&ctx, block.condition);

                // TODO: expr.local doesn't exist anymore, result is pointer to by rax
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
        Stmt::While(while) => {
            l prev_breaks = ctx.loop_breaks;
            ctx.loop_breaks = V_new<I>();
            l prev_continue = ctx.loop_continue;
            ctx.loop_continue = AW_idx(ctx.wr);

            l expr = kompile_expr(&ctx, while.condition);

            V_push<I>(&ctx.loop_breaks, AW_create_overwritable_jz(&ctx.wr));

            kompile_block(&ctx, while.stmts);

            AW_create_jump(&ctx.wr, ctx.loop_continue);

            v idx = 0;
            w (I_lt(idx, V_len<I>(ctx.loop_breaks))) {
                AW_overwrite_jump(&ctx.wr, V_get<I>(ctx.loop_breaks, idx), AW_idx(ctx.wr));
                idx = I_add(idx, 1);
            }

            ctx.loop_breaks = prev_breaks;
            ctx.loop_continue = prev_continue;
        }
        Stmt::Break => {
            V_push<I>(&ctx.loop_breaks, AW_create_overwritable_jump(&ctx.wr));
        }
        Stmt::Continue => {
            AW_create_jump(&ctx.wr, ctx.loop_continue);
        }
        Stmt::Assignment(assign) => {
            // s AssignmentStmt {
            //     place: PlaceExpr,
            //     value: Expr,
            // }

            // TODO: Move expr to rbx
            kompile_expr(&ctx, assign.value);
            l place = kompile_place(&ctx, assign.place);

            AW_call(&ctx.wr, MMKey_new("copy_content"));
        }
        Stmt::VarDecl(var) => {
            i (O_is_none<Type>(var.ty)) {
                print("Variable decl type annotations are required");
                exit();
            }
            
            l type = O_get<Type>(var.ty);
            l sz = get_size_of_type(ctx, type);
            l idx = AW_create_heap_local(&ctx.wr, var.ident, sz, y);

            v value = O_none<ExprResult>();
            i (O_is_some<Expr>(var.value)) {
                value = O_some<ExprResult>(kompile_expr(&ctx, O_get<Expr>(var.value)));
            }

            AW_mov_rax_to_local(&ctx.wr, idx);
        }
        _ => {
            print("Unsupported stmt type");
        }
    }
}

f get_size_of_type(ctx: Ctx, type: Type) -> I {
    l builtin_lookup = Map_get<I>(ctx.builtin_types, type.ident);
    i (O_is_some<I>(builtin_lookup)) {
        r O_get<I>(builtin_lookup);
    }

    l lookup = Map_get<TypeInfo>(ctx.types, type.ident);
    i (O_is_none<TypeInfo>(lookup)) {
        print(S_concat(S_concat("Assuming that ", type.ident), " is a type parameter"));
        r 8;
    }

    l info = O_get<TypeInfo>(lookup);
    r info.size;
}

// Used to be used, but emptied it to find all of the now incorrect
// usages of it. Expr results are now stored in rax.
s ExprResult {
}

// Puts a place in rbx and doesn't clobber rax
f kompile_place(ctx: &Ctx, expr: PlaceExpr) -> ExprResult {
    m (expr) {
        PlaceExpr::Ident(ident) => {
            l local = resolve_ident(ctx, ident);
            l rbp_offset = fn_local_to_rbp_offset(local);
            AW_mov_stack_to_rbx(&ctx.wr, rbp_offset);
            r ExprResult {};
        }
        _ => {
            print("Unsupported expr type");
            exit();
        }
    }
}

f fn_local_to_rbp_offset(local: FunctionLocal) -> I {
    m (local) {
        FunctionLocal::Local(idx) => {
            r I_neg(I_add(I_mul(idx, 8), 8));
        }
        FunctionLocal::Argument(idx) => {
            r I_add(I_mul(idx, 8), 16);
        }
    }
}

f kompile_expr(ctx: &Ctx, expr: Expr) -> ExprResult {
    m (expr) {
        Expr::Ident(ident) => {
            l local = resolve_ident(ctx, ident);
            l offset = fn_local_to_rbp_offset(local);
            AW_mov_stack_to_rax(&ctx.wr, offset);
            r ExprResult {};
        }
        Expr::FunctionCall(call) => {
            l result = AW_create_heap_local(&ctx.wr, "result_tmp", 8, n);
            kompile_fn_call(&ctx, call);
            r ExprResult {};
        }
        Expr::Literal(literal) => {
            m (literal) {
                LiteralExpr::Int(int) => {
                    l idx = AW_create_heap_local(&ctx.wr, "tmp_int_lit", 8, n);
                    AW_mov_constant_int_to_heap_local(&ctx.wr, idx, int);
                    AW_mov_local_to_rax(&ctx.wr, idx);
                    l type = Type_new("I");
                    r ExprResult {};
                }
                LiteralExpr::Bool(bool) => {
                    l idx = AW_create_heap_local(&ctx.wr, "tmp_bool_lit", 8, n);
                    i (bool) {
                        AW_mov_constant_int_to_heap_local(&ctx.wr, idx, 1);
                    } e {
                        AW_mov_constant_int_to_heap_local(&ctx.wr, idx, 0);
                    }
                    AW_mov_local_to_rax(&ctx.wr, idx);
                    l type = Type_new("B");
                    r ExprResult {};
                }
                LiteralExpr::Char(char) => {
                    l idx = AW_create_heap_local(&ctx.wr, "tmp_char_lit", 8, n);
                    AW_mov_constant_int_to_heap_local(&ctx.wr, idx, C_ord(char));
                    AW_mov_local_to_rax(&ctx.wr, idx);
                    l type = Type_new("C");
                    r ExprResult {};
                }
                LiteralExpr::String(string) => {
                    AW_make_string(&ctx.wr, string);
                    l type = Type_new("S");
                    r ExprResult {};
                }
            }
        }
        _ => {
            print("Unsupported expr type");
            exit();
        }
    }
}

f Type_new(ident: S) -> Type {
    r Type { ident: ident, generic_parameters: V_new<Type>() };
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
                AW_push_argument_from_rax(&ctx.wr);
            }
            ArgumentValue::Mutable => {
                print("Mutable references not supported");
                exit();
            }
        }
        idx = I_sub(idx, 1);
    }
   
    r ExprResult {};
}

f create_unit_local(ctx: &Ctx) -> I {
    l idx = AW_create_local(&ctx.wr, "unit", 8);
    AW_mov_constant_int_to_local(&ctx.wr, idx, 0);
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
        print(S_concat("Function does not exist with ident: ", call.ident));
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
