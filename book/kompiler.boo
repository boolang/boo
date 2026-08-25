s BuiltinFunction {
    params: V<Parameter>,
    generic_parameters: V<S>,
    ret_type: Type,
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
    loop_breaks: V<I>,
    loop_continue: I,
    builtin_fns: Map<BuiltinFunction>,
    constants: V<Constant>,
    wr: AsmWriter,
    // Map from builtin type names sizes
    builtin_types: Map<BuiltinType>,
    // Maps idents to function locals (includes both locals and args)
    locals: Map<FunctionLocal>
}

s BuiltinType {
    size: I,
    n_type_parameters: I
}

f Ctx_load_builtin(ctx: &Ctx, ident: S, params: V<Parameter>, ret_type: Type) {
    Ctx_load_builtin_full(&ctx, ident, params, V_new<S>(), ret_type);
}

f Ctx_load_builtin_full(ctx: &Ctx, ident: S, params: V<Parameter>, generic_parameters: V<S>, ret_type: Type) {
    l asm = read(S_concat("builtins/", ident));
    l builtin = BuiltinFunction {
        params: params,
        generic_parameters: generic_parameters,
        ret_type: ret_type,
        asm: asm
    };
    Map_insert<BuiltinFunction>(&ctx.builtin_fns, ident, builtin);
}

f Ctx_load_stdlib_builtins(ctx: &Ctx) {
    l empty_params = V_new<Parameter>();
    l unit = Type_new("U");
    l string = Type_new("S");
    l int = Type_new("I");
    l char = Type_new("C");
    l bool = Type_new("B");
    v generic_params_t = V_new<S>();
    V_push<S>(&generic_params_t, "T");
    l v_t = Type_new_generic1("V", "T");

    // NOTE: These don't follow Boo ABI, they are compiler helpers
    // make_str is accessible at 0x400007 because emit_builtins will
    // place it immediately after the hardcoded malloc jump.
    Ctx_load_builtin(&ctx, "make_str", empty_params, unit);
    Ctx_load_builtin(&ctx, "copy_content", empty_params, unit);

    // Malloc is accessible at 0x400000 because emit_builtins places
    // a jump to malloc before emitting any builtins
    v malloc_params = V_new<Parameter>();
    V_push<Parameter>(&malloc_params, Parameter_new("size", "I", n));
    Ctx_load_builtin(&ctx, "malloc", malloc_params, unit);

    v exit_params = V_new<Parameter>();
    V_push<Parameter>(&exit_params, Parameter_new("status", "I", n));
    Ctx_load_builtin(&ctx, "exit", exit_params, unit);

    v print_params = V_new<Parameter>();
    V_push<Parameter>(&print_params, Parameter_new("msg", "S", n));
    Ctx_load_builtin(&ctx, "print", print_params, unit);

    v read_count_params = V_new<Parameter>();
    V_push<Parameter>(&read_count_params, Parameter_new("path", "S", n));
    V_push<Parameter>(&read_count_params, Parameter_new("count", "I", n));
    Ctx_load_builtin(&ctx, "read_count", read_count_params, string);

    v i_neg_params = V_new<Parameter>();
    V_push<Parameter>(&i_neg_params, Parameter_new("value", "I", n));
    Ctx_load_builtin(&ctx, "I_neg", i_neg_params, int);

    v s_new_from_char_params = V_new<Parameter>();
    V_push<Parameter>(&s_new_from_char_params, Parameter_new("value", "C", n));
    Ctx_load_builtin(&ctx, "S_new_from_char", s_new_from_char_params, string);

    v s_get_params = V_new<Parameter>();
    V_push<Parameter>(&s_get_params, Parameter_new("value", "S", n));
    V_push<Parameter>(&s_get_params, Parameter_new("idx", "I", n));
    Ctx_load_builtin(&ctx, "S_get", s_get_params, char);

    v ii_params = V_new<Parameter>();
    V_push<Parameter>(&ii_params, Parameter_new("first", "I", n));
    V_push<Parameter>(&ii_params, Parameter_new("second", "I", n));
    Ctx_load_builtin(&ctx, "I_add", ii_params, int);
    Ctx_load_builtin(&ctx, "I_mul", ii_params, int);
    Ctx_load_builtin(&ctx, "I_eq", ii_params, int);
    Ctx_load_builtin(&ctx, "I_lt", ii_params, int);
    Ctx_load_builtin(&ctx, "I_udiv", ii_params, int);

    v s_concat_params = V_new<Parameter>();
    V_push<Parameter>(&s_concat_params, Parameter_new("first", "S", n));
    V_push<Parameter>(&s_concat_params, Parameter_new("second", "S", n));
    Ctx_load_builtin(&ctx, "S_concat", s_concat_params, string);

    v s_len_params = V_new<Parameter>();
    V_push<Parameter>(&s_len_params, Parameter_new("first", "S", n));
    Ctx_load_builtin(&ctx, "S_len", s_len_params, int);

    // vec ops
    v v_new_params = V_new<Parameter>();
    Ctx_load_builtin_full(&ctx, "V_new", v_new_params, generic_params_t, v_t);

    v v_push_params = V_new<Parameter>();
    V_push<Parameter>(&v_push_params, Parameter_new_full("vec", v_t, y));
    V_push<Parameter>(&v_push_params, Parameter_new("element", "T", n));
    Ctx_load_builtin_full(&ctx, "V_push", v_push_params, generic_params_t, unit);

    v v_len_params = V_new<Parameter>();
    V_push<Parameter>(&v_len_params, Parameter_new_full("vec", v_t, n));
    Ctx_load_builtin_full(&ctx, "V_len", v_len_params, generic_params_t, int);

    v v_get_params = V_new<Parameter>();
    V_push<Parameter>(&v_get_params, Parameter_new_full("vec", v_t, n));
    V_push<Parameter>(&v_get_params, Parameter_new("idx", "I", n));
    Ctx_load_builtin_full(&ctx, "V_get", v_get_params, generic_params_t, Type_new("T"));

    v v_set_params = V_new<Parameter>();
    V_push<Parameter>(&v_set_params, Parameter_new_full("vec", v_t, y));
    V_push<Parameter>(&v_set_params, Parameter_new("idx", "I", n));
    V_push<Parameter>(&v_set_params, Parameter_new("new_value", "T", n));
    Ctx_load_builtin_full(&ctx, "V_set", v_set_params, generic_params_t, unit);
}

f ExprResult_new_builtin(simple_type: S, size: I) -> ExprResult {
    r ExprResult {
        type: TypeInfo_new_builtin(simple_type, size)
    };
}

f TypeInfo_new_builtin(ident: S, size: I) -> TypeInfo {
    r TypeInfo {
        ident: ident,
        size: size,
        kind: TypeKind::Builtin,
        members: Map_new<Type>()
    };
}

f TypeInfo_new_struct(ident: S, fields: Map<Type>) -> TypeInfo {
    r TypeInfo {
        ident: ident,
        size: I_mul(Map_count<Type>(fields), 8),
        kind: TypeKind::Struct,
        members: fields
    };
}

f TypeInfo_new_enum(ident: S, cases: Map<Type>) -> TypeInfo {
    r TypeInfo {
        ident: ident,
        size: 16, // tag + value pointer
        kind: TypeKind::Enum,
        members: cases
    };
}

t TypeKind {
    Builtin,
    Struct,
    Enum
}

s TypeInfo {
    ident: S,
    size: I,
    kind: TypeKind,
    // Either fields or members depending on kind
    members: Map<Type>,
}

f BuiltinType_new(size: I, n_type_parameters: I) -> BuiltinType {
    r BuiltinType {
        size: size,
        n_type_parameters: n_type_parameters
    };
}

f kompile(ast: Ast) {
    v builtin_types = Map_new<BuiltinType>();
    Map_insert<BuiltinType>(&builtin_types, "C", BuiltinType_new(8, 0));
    Map_insert<BuiltinType>(&builtin_types, "U", BuiltinType_new(8, 0));
    Map_insert<BuiltinType>(&builtin_types, "I", BuiltinType_new(8, 0));
    Map_insert<BuiltinType>(&builtin_types, "B", BuiltinType_new(8, 0));
    Map_insert<BuiltinType>(&builtin_types, "S", BuiltinType_new(16, 0));
    Map_insert<BuiltinType>(&builtin_types, "V", BuiltinType_new(16, 1));

    v ctx = Ctx {
        structs: Map_new<Struct>(),
        enums: Map_new<Enum>(),
        fns: Map_new<Function>(),
        fn_q: Q_new<MMKey>(),
        loop_breaks: V_new<I>(),
        loop_continue: 0,
        builtin_fns: Map_new<BuiltinFunction>(),
        constants: V_new<Constant>(),
        wr: AsmWriter {
            base_addr: 0x400000,
            buf: "",
            jumps: MMap_new<I>(),
            pending_jumps: MMap_new<V<I>>(),
            function_prelude_location: -1,
            locals: V_new<Local>()
        },
        builtin_types: builtin_types,
        locals: Map_new<FunctionLocal>()
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
        l fn_ast = instantiate_fn(ctx, key);
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
    // We want malloc at 0x400000 but we also want make_str to be predictable,
    // so we start with a jump to malloc, then emit make_str (it's registered
    // first), and then emit the rest of the builtins. This puts make_str
    // at 0x400007.
    l malloc_jump_idx = AW_create_overwritable_jump(&ctx.wr);

    v idx = 0;
    w (I_lt(idx, Map_count<BuiltinFunction>(ctx.builtin_fns))) {
        l entry = V_get<MapEntry<BuiltinFunction>>(ctx.builtin_fns.storage, idx);
        i (S_eq(entry.key, "malloc")) {
            AW_overwrite_jump(&ctx.wr, malloc_jump_idx, AW_idx(ctx.wr));
        }
        AW_emit_builtin_function(&ctx.wr, entry.key, entry.value);
        idx = I_add(idx, 1);
    }
}

f instantiate_fn(ctx: Ctx, key: MMKey) -> O<FunctionInstance> {
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

    v ret_type = O_none<Type>();
    i (O_is_some<Type>(fn.signature.ret)) {
        ret_type = O_some<Type>(instantiate_type(O_get<Type>(fn.signature.ret), fn.signature.generic_parameters, key.generic_args));
    }

    r O_some<FunctionInstance>(FunctionInstance {
        key: key,
        parameters: new_params,
        ret: ret_type,
        stmts: fn.stmts
    });
}

f get_fn_return_type(ctx: Ctx, key: MMKey) -> TypeInfo {
    l lookup = Map_get<Function>(ctx.fns, key.ident);
    i (O_is_none<Function>(lookup)) {
        print(S_concat("No such function: ", key.ident));
        exit();
    }
    l fn = O_get<Function>(lookup);
    v ret = Type_new("U");
    i (O_is_some<Type>(fn.signature.ret)) {
        ret = O_get<Type>(fn.signature.ret);
    }
    print(S_concat("Getting function return: ", ret.ident));
    l ret_type = instantiate_type(
        ret,
        fn.signature.generic_parameters,
        key.generic_args
    );
    print(S_concat("Instantiated function return: ", ret_type.ident));
    r lookup_type(ctx, ret_type);
}

f instantiate_type(type: Type, params: V<S>, args: V<Type>) -> Type {
    print(S_concat("Looking for type in params: ", type.ident));
    l param_idx = V_find_string(params, type.ident);
    i (not(I_eq(param_idx, -1))) {
        print("Found type in params");
        r V_get<Type>(args, param_idx);
    }
    print("Didn't find type in params");

    v new_type = type;
    v idx = 0;
    w (I_lt(idx, V_len<Type>(type.generic_parameters))) {
        V_set<Type>(
            &new_type.generic_parameters,
            idx,
            instantiate_type(V_get<Type>(type.generic_parameters, idx), params, args)
        );
        idx = I_add(idx, 1);
    }

    r new_type;
}

t FunctionLocalKind {
    Local,
    Argument
}

s FunctionLocal {
    kind: FunctionLocalKind,
    // The index of the argument index or local index
    index: I,
    type: TypeInfo
}

f resolve_local(ctx: Ctx, ident: S) -> FunctionLocal {
    l lookup = Map_get<FunctionLocal>(ctx.locals, ident);
    i (O_is_none<FunctionLocal>(lookup)) {
        print(S_concat("No such local: ", ident));
        exit();
    }
    r O_get<FunctionLocal>(lookup);
}

f kompile_fn(ctx: &Ctx, fn: FunctionInstance) {
    ctx.locals = Map_new<FunctionLocal>();

    AW_begin_function(&ctx.wr, fn.key);

    v idx = 0;
    w (I_lt(idx, V_len<Parameter>(fn.parameters))) {
        l parameter = V_get<Parameter>(fn.parameters, idx);
        Map_insert<FunctionLocal>(&ctx.locals, parameter.label, FunctionLocal {
            kind: FunctionLocalKind::Argument,
            index: idx,
            type: lookup_type(ctx, parameter.ty.ty)
        });
        idx = I_add(idx, 1);
    }

    kompile_block(&ctx, fn.stmts);
    l is_main = S_eq(fn.key.ident, "main");
    AW_finalize_function(&ctx.wr, is_main);
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
                next_cond_instr = O_some<I>(AW_create_overwritable_rax_jz_deref(&ctx.wr));

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

            V_push<I>(&ctx.loop_breaks, AW_create_overwritable_rax_jz_deref(&ctx.wr));

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

            kompile_expr(&ctx, assign.value);
            l place = kompile_place(&ctx, assign.place);

            AW_call(&ctx.wr, MMKey_new("copy_content"));
        }
        Stmt::VarDecl(var) => {
            i (O_is_none<Expr>(var.value)) {
                print(S_concat("Variable declarations must have an initial value: ", var.ident));
                exit();
                // TODO: If we ever add back var decls with no initial value, this is
                //   the implementation for that

                // i (O_is_none<Type>(var.ty)) {
                //     print("Variable decl type annotations are required when value not provided");
                //     exit();
                // }
            
                // l type = O_get<Type>(var.ty);
                // l size = get_size_of_type(ctx, type);
                // AW_malloc(&ctx.wr, size);
            }

            l idx = AW_create_local(&ctx.wr, var.ident, 8);
            l value = kompile_expr(&ctx, O_get<Expr>(var.value));
            AW_mov_rax_to_local(&ctx.wr, idx);

            Map_insert<FunctionLocal>(&ctx.locals, var.ident, FunctionLocal {
                kind: FunctionLocalKind::Local,
                index: idx,
                type: value.type
            });
        }
        Stmt::Match(match) => {
            l local = AW_create_local(&ctx.wr, "match_value_tmp", 8);
            l inner_local = AW_create_local(&ctx.wr, "match_value_tmp_inner", 8);
            l value = kompile_expr(&ctx, match.value);
            AW_mov_rax_to_local(&ctx.wr, local);

            // Place enum case associated value in separate local
            AW_deref_rax(&ctx.wr, 8);
            AW_mov_rax_to_local(&ctx.wr, inner_local);

            // Place enum tag in rax
            AW_mov_local_to_rax(&ctx.wr, local);
            AW_deref_rax(&ctx.wr, 0);

            m (value.type.kind) {
                TypeKind::Enum => {}
                _ => {
                    print(S_concat("Match expected enum, got: ", value.type.ident));
                    exit();
                }
            }

            // The following code has been copied from IfStmt and updated for matches.
            // There's a lot of duplicated code here...

            v next_cond_instr = O_none<I>();
            v leave_instrs = V_new<I>();

            v idx = 0;
            w (I_lt(idx, V_len<CaseBlock>(match.case_blocks))) {
                l block = V_get<CaseBlock>(match.case_blocks, idx);
                i (O_is_some<I>(next_cond_instr)) {
                    AW_overwrite_jump(&ctx.wr, O_get<I>(next_cond_instr), AW_idx(ctx.wr));
                }

                i (not(S_eq(block.pattern.ident, value.type.ident))) {
                    print("Match statement case type mismatch");
                    exit();
                }

                l case_idx = Map_find<Type>(value.type.members, block.pattern.case);
                i (I_eq(case_idx, -1)) {
                    print(S_concat("Unknown enum case: ", block.pattern.case));
                    exit();
                }

                AW_cmp_rax_to_uconst(&ctx.wr, case_idx);
                next_cond_instr = O_some<I>(AW_create_overwritable_jnz(&ctx.wr));

                v pop_local = n;
                i (O_is_some<Binding>(block.pattern.binding)) {
                    l binding = O_get<Binding>(block.pattern.binding);
                    m (binding) {
                        Binding::Underscore => {}
                        Binding::Ident(inner_ident) => {
                            pop_local = y;
                            l member_type = V_get<MapEntry<Type>>(value.type.members.storage, case_idx).value;
                            Map_insert<FunctionLocal>(&ctx.locals, inner_ident, FunctionLocal {
                                kind: FunctionLocalKind::Local,
                                index: inner_local,
                                type: lookup_type(ctx, member_type)
                            });
                        }
                    }
                }
                kompile_block(&ctx, block.stmts);

                i (pop_local) {
                    Map_pop<FunctionLocal>(&ctx.locals);
                }

                V_push<I>(&leave_instrs, AW_create_overwritable_jump(&ctx.wr));

                idx = I_add(idx, 1);
            }

            AW_overwrite_jump(&ctx.wr, O_get<I>(next_cond_instr), AW_idx(ctx.wr));

            i (O_is_some<V<Stmt>>(match.default_block)) {
                kompile_block(&ctx, O_get<V<Stmt>>(match.default_block));
            }

            idx = 0;
            w (I_lt(idx, V_len<I>(leave_instrs))) {
                AW_overwrite_jump(&ctx.wr, V_get<I>(leave_instrs, idx), AW_idx(ctx.wr));
                idx = I_add(idx, 1);
            }
        }
        _ => {
            print("Unsupported stmt type");
            exit();
        }
    }
}

f get_size_of_type(ctx: Ctx, type: Type) -> I {
    r lookup_type(ctx, type).size;
}

s ExprResult {
    type: TypeInfo
}

// Puts a place in rbx and doesn't clobber rax
f kompile_place(ctx: &Ctx, expr: PlaceExpr) -> ExprResult {
    m (expr) {
        PlaceExpr::Ident(ident) => {
            l local = resolve_local(ctx, ident);
            l rbp_offset = fn_local_to_rbp_offset(local);
            AW_mov_stack_to_rbx(&ctx.wr, rbp_offset);
            r ExprResult {
                type: local.type
            };
        }
        PlaceExpr::Member(member) => {
            l base = kompile_place(&ctx, member.base);
            m (base.type.kind) {
                TypeKind::Struct => {}
                _ => {
                    print(S_concat("Expected struct target for member assigment, got: ", base.type.ident));
                    exit();
                }
            }
            l member_idx = Map_find<Type>(base.type.members, member.member);
            i (I_eq(member_idx, -1)) {
                print(S_concat("No such member: ", member.member));
                exit();
            }

            AW_deref_rbx(&ctx.wr, I_mul(member_idx, 8));

            l member_type = V_get<MapEntry<Type>>(base.type.members.storage, member_idx).value;
            r ExprResult {
                type: lookup_type(ctx, member_type)
            };
        }
    }
}

f fn_local_to_rbp_offset(local: FunctionLocal) -> I {
    m (local.kind) {
        FunctionLocalKind::Local => {
            r I_neg(I_add(I_mul(local.index, 8), 8));
        }
        FunctionLocalKind::Argument => {
            r I_add(I_mul(local.index, 8), 16);
        }
    }
}

f kompile_expr(ctx: &Ctx, expr: Expr) -> ExprResult {
    m (expr) {
        Expr::Ident(ident) => {
            l local = resolve_local(ctx, ident);
            l offset = fn_local_to_rbp_offset(local);
            print(S_concat(S_concat(S_concat("Offset for ident ", ident), " is "), I_to_string(offset)));
            AW_mov_stack_to_rax(&ctx.wr, offset);
            r ExprResult {
                type: local.type
            };
        }
        Expr::FunctionCall(call) => {
            r kompile_fn_call(&ctx, call);
        }
        Expr::Literal(literal) => {
            m (literal) {
                LiteralExpr::Int(int) => {
                    l idx = AW_create_heap_local(&ctx.wr, "tmp_int_lit", 8);
                    AW_mov_constant_int_to_heap_local(&ctx.wr, idx, int);
                    AW_mov_local_to_rax(&ctx.wr, idx);
                    r ExprResult_new_builtin("I", 8);
                }
                LiteralExpr::Bool(bool) => {
                    l idx = AW_create_heap_local(&ctx.wr, "tmp_bool_lit", 8);
                    i (bool) {
                        AW_mov_constant_int_to_heap_local(&ctx.wr, idx, 1);
                    } e {
                        AW_mov_constant_int_to_heap_local(&ctx.wr, idx, 0);
                    }
                    AW_mov_local_to_rax(&ctx.wr, idx);
                    r ExprResult_new_builtin("B", 8);
                }
                LiteralExpr::Char(char) => {
                    l idx = AW_create_heap_local(&ctx.wr, "tmp_char_lit", 8);
                    AW_mov_constant_int_to_heap_local(&ctx.wr, idx, C_ord(char));
                    AW_mov_local_to_rax(&ctx.wr, idx);
                    r ExprResult_new_builtin("C", 8);
                }
                LiteralExpr::String(string) => {
                    AW_make_string(&ctx.wr, string);
                    l type = Type_new("S");
                    r ExprResult_new_builtin("S", 16);
                }
            }
        }
        Expr::Subscript(subscript) => {
            kompile_expr(&ctx, subscript.base);
            AW_push_argument_from_rax(&ctx.wr);
            kompile_expr(&ctx, subscript.index);
            AW_push_argument_from_rax(&ctx.wr);
            AW_call(&ctx.wr, MMKey_new("S_get"));
            r ExprResult {};
        }
        Expr::StructInit(struct_init) => {
            l lookup = Map_get<Struct>(ctx.structs, struct_init.ident);
            i (O_is_none<Struct>(lookup)) {
                print(S_concat("No such struct ", struct_init.ident));
                exit();
            }
            l struct = O_get<Struct>(lookup);
            l nfields = V_len<Field>(struct.fields);
            l nargs = V_len<StructInitArgument>(struct_init.arguments);
            i (not(I_eq(nfields, nargs))) {
                print(S_concat("Struct ", S_concat(struct.ident, S_concat(" has ", S_concat( I_to_string(nfields), S_concat(" arguments, got ", I_to_string(nargs)))))));
                exit();
            }

            l sz = I_mul(nfields, 8);
            l local = AW_create_heap_local(&ctx.wr, "struct_init_tmp", sz);

            v idx = 0;
            w (I_lt(idx, nargs)) {
                l arg = V_get<StructInitArgument>(struct_init.arguments, idx);
                l field = V_get<Field>(struct.fields, idx);
                i (not(S_eq(arg.label, field.ident))) {
                    print(S_concat("Struct ", S_concat(struct.ident, S_concat(" has a field called ", S_concat(field.ident, S_concat(", got ", arg.label))))));
                    exit();
                }
                kompile_expr(&ctx, arg.value);

                AW_mov_rax_to_heap_local(&ctx.wr, local, I_mul(idx, 8));
                
                idx = I_add(idx, 1);
            }

            AW_mov_local_to_rax(&ctx.wr, local);

            r ExprResult {
                type: lookup_type(ctx, Type {
                    ident: struct_init.ident,
                    generic_parameters: struct_init.generic_parameters
                })
            };
        }
        Expr::MemberAccess(member_access) => {
            l base = kompile_expr(&ctx, member_access.base);
            m (base.type.kind) {
                TypeKind::Struct => {}
                _ => {
                    print(S_concat("Attempted to access member of non-struct type: ", base.type.ident));
                    exit();
                }
            }

            l member_index = Map_find<Type>(base.type.members, member_access.member);
            i (I_eq(member_index, -1)) {
                print(S_concat("Struct '", S_concat(base.type.ident, S_concat("' has no such member: ", member_access.member))));
                exit();
            }

            AW_deref_rax(&ctx.wr, I_mul(member_index, 8));

            l member_type = V_get<MapEntry<Type>>(base.type.members.storage, member_index).value;
            r ExprResult {
                type: lookup_type(ctx, member_type)
            };
        }
        Expr::EnumInit(enum_init) => {
            l type_info = lookup_type(ctx, Type_new(enum_init.ident));
            m (type_info.kind) {
                TypeKind::Enum => {}
                _ => {
                    print(S_concat("Type is not an enum (in enum init expr): ", type_info.ident));
                    exit();
                }
            }

            l idx = Map_find<Type>(type_info.members, enum_init.case);
            i (I_eq(idx, -1)) {
                print(S_concat("Enum '", S_concat(type_info.ident, S_concat("' has no such case: ", enum_init.case))));
                exit();
            }

            l local = AW_create_heap_local(&ctx.wr, "enum_init_tmp", type_info.size);
            // Set enum tag
            AW_mov_constant_int_to_heap_local(&ctx.wr, local, idx);

            i (O_is_some<Expr>(enum_init.value)) {
                kompile_expr(&ctx, O_get<Expr>(enum_init.value));
                AW_mov_rax_to_heap_local(&ctx.wr, local, 8);
            }

            AW_mov_local_to_rax(&ctx.wr, local);
            r ExprResult {
                type: type_info
            };
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

f Type_new_generic1(ident: S, generic: S) -> Type {
    v generics = V_new<Type>();
    V_push<Type>(&generics, Type_new(generic));
    r Type { ident: ident, generic_parameters: generics };
}

f Parameter_new(label: S, type: S, mutable: B) -> Parameter {
    r Parameter {
        label: label,
        ty: ArgumentType {
            ty: Type_new(type),
            mutable: mutable
        }
    };
}

f Parameter_new_full(label: S, type: Type, mutable: B) -> Parameter {
    r Parameter {
        label: label,
        ty: ArgumentType {
            ty: type,
            mutable: mutable
        }
    };
}

f exit() {
    nonexistent();
}

// The value is a heap pointer
f Type_is_heap(type: Type) -> B {
    r S_eq(heap.ident, "H");
}

f place_expr_to_expr(place: PlaceExpr) -> Expr {
    m (place) {
        PlaceExpr::Ident(ident) => {
            r Expr::Ident(ident);
        }
        PlaceExpr::Member(access) => {
            r Expr::Member(MemberAccessExpr {
                base: place_expr_to_expr(access.base),
                member: access.member
            });
        }
    }
}

f prepare_fn_call_args(ctx: &Ctx, call: FunctionCallExpr) {
    v idx = I_sub(V_len<ArgumentValue>(call.arguments), 1);
    w (I_ge(idx, 0)) {
        l arg = V_get<ArgumentValue>(call.arguments, idx);
        m (arg) {
            ArgumentValue::Immutable(expr) => {
                kompile_expr(&ctx, expr);
                AW_push_argument_from_rax(&ctx.wr);
            }
            ArgumentValue::Mutable(place) => {
                // Everything is mutable the way we compile things, so just compile
                // it like any old expression
                l expr = place_expr_to_expr(place);
                kompile_expr(&ctx, expr);
                AW_push_argument_from_rax(&ctx.wr);
            }
        }
        idx = I_sub(idx, 1);
    }
}

f create_unit_local(ctx: &Ctx) -> I {
    l idx = AW_create_local(&ctx.wr, "unit", 8);
    AW_mov_constant_int_to_local(&ctx.wr, idx, 0);
    r idx;
}

f kompile_fn_call(ctx: &Ctx, call: FunctionCallExpr) -> ExprResult {
    print(S_concat("Preparing fn call args: ", call.ident));
    prepare_fn_call_args(&ctx, call);

    v expr_result = ExprResult {
        type: TypeInfo_new_builtin("U", 8) // dummy value
    };
    l maybe_fn = Map_get<Function>(ctx.fns, call.ident);
    i (O_is_none<Function>(maybe_fn)) {
        expr_result.type = kompile_builtin_fn_call(&ctx, call);
    } e {
        l fn = O_get<Function>(maybe_fn);
        l nparams = V_len<Parameter>(fn.signature.parameters);
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
        expr_result.type = get_fn_return_type(ctx, key);
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

f lookup_type(ctx: Ctx, type: Type) -> TypeInfo {
    l builtin_lookup = Map_get<BuiltinType>(ctx.builtin_types, type.ident);
    i (O_is_some<BuiltinType>(builtin_lookup)) {
        l builtin = O_get<BuiltinType>(builtin_lookup);
        r TypeInfo_new_builtin(type.ident, builtin.size);
    }

    l struct_lookup = Map_get<Struct>(ctx.structs, type.ident);
    i (O_is_some<Struct>(struct_lookup)) {
        l struct = O_get<Struct>(struct_lookup);
        l nfields = V_len<Field>(struct.fields);
        v idx = 0;
        v fields = Map_new<Type>();
        w (I_lt(idx, nfields)) {
            l field = V_get<Field>(struct.fields, idx);
            // TODO: Replace generic parameters present in the field's type with
            //   the generic parameters in struct.generic_parameters
            Map_insert<Type>(&fields, field.ident, field.ty);
            idx = I_add(idx, 1);
        }
        r TypeInfo_new_struct(type.ident, fields);
    }

    l enum_lookup = Map_get<Enum>(ctx.enums, type.ident);
    i (O_is_some<Enum>(enum_lookup)) {
        l enum = O_get<Enum>(enum_lookup);
        l ncases = V_len<Case>(enum.cases);
        v idx = 0;
        v cases = Map_new<Type>();
        w (I_lt(idx, ncases)) {
            l case = V_get<Case>(enum.cases, idx);
            v ty = Type_new("U");
            i (O_is_some<Type>(case.ty)) {
                ty = O_get<Type>(case.ty);
            }
            Map_insert<Type>(&cases, case.ident, ty);
            idx = I_add(idx, 1);
        }
        r TypeInfo_new_enum(type.ident, cases);
    }

    print(S_concat("No such type ", type.ident));
    exit();
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

f kompile_builtin_fn_call(ctx: &Ctx, call: FunctionCallExpr) -> TypeInfo {
    l maybe_fn = Map_get<BuiltinFunction>(ctx.builtin_fns, call.ident);
    i (O_is_none<BuiltinFunction>(maybe_fn)) {
        print(S_concat("Function does not exist with ident: ", call.ident));
        exit();
    }

    l fn = O_get<BuiltinFunction>(maybe_fn);
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

    l ret_type = instantiate_type(fn.ret_type, fn.generic_parameters, call.generic_parameters);
    r lookup_type(ctx, ret_type);
}
