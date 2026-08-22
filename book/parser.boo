f parse(input: S) -> Ast {
    v acc = input;

    v decls = V_new<Decl>();

    w (y) {
        l result = next_token(acc);
        // acc = result.rest;

        m (result.value) {
            Token::KFunction => {
                l func = parse_function(acc);
                acc = func.rest;
                V_push<Decl>(&decls, Decl::Function(func.value));
            }
            Token::KStruct => {
                l struct = parse_struct(acc);
                acc = struct.rest;
                V_push<Decl>(&decls, Decl::Struct(struct.value));
            }
            Token::KType => {
                l enum = parse_enum(acc);
                acc = enum.rest;
                V_push<Decl>(&decls, Decl::Enum(enum.value));
            }
            Token::Eof => {
                r Ast { decls: decls };
            }
        }
    }
}

// MARK: Functions

f parse_function(input: S) -> Parse<Function> {
	dbg_print("> function");
    v acc = input;

    v result = next_token(acc);
    acc = result.rest;
    // KFunction

    l name = parse_ident(acc);
    acc = name.rest;

    l generic_params = parse_generic_params(acc);
    acc = generic_params.rest;

    acc = next_token(acc).rest; // OpenPar

    l params = parse_param_list(acc);
    acc = params.rest;

    acc = next_token(acc).rest; // ClosePar
    
    v ret_ty = O_none<Type>();
    result = next_token(acc);
    m (result.value) {
        Token::Arrow => {
            acc = result.rest;
            v ty = parse_type(acc);
            acc = ty.rest;
            ret_ty = O_some<Type>(ty.value);
        }
    }

    l stmts = parse_block(acc);
    acc = stmts.rest;
    
	dbg_print("< function");
    r Parse<Function> {
        rest: acc,
        value: Function {
            signature: FunctionSignature {
                ident: name.value,
                generic_parameters: generic_params.value,
                parameters: params.value,
                ret: ret_ty
            },
            stmts: stmts.value
        }
    };
}

f parse_block(input: S) -> Parse<V<Stmt>> {
    v acc = input;
	dbg_print("> block");

    acc = next_token(acc).rest; // OpenBrace

    v stmts = V_new<Stmt>();

    w (y) {
        v result = next_token(acc);
        m (result.value) {
            Token::CloseBrace => {
                acc = result.rest;
                b;
            }
        }
        l stmt = parse_stmt(acc);
        acc = field.rest;
        V_push<Stmt>(&stmts, stmt.value);
    }

    acc = next_token(acc).rest; // CloseBrace

	dbg_print("< block");
    r Parse<V<Stmt>> { rest: acc, value: fields };
}

f parse_stmt(input: S) -> Parse<Stmt> {
    v acc = input;
	dbg_print("> stmt");

    v result = next_token(acc);

    m (result.value) {
        Token::KIf => {
            l if = parse_if(acc);
            acc = if.rest;
        	dbg_print("< stmt");
            r Parse<Stmt> { rest: acc, value: Stmt::If(if.value) };
        }
        Token::KWhile => {
            l while = parse_while(acc);
            acc = while.rest;
        	dbg_print("< stmt");
            r Parse<Stmt> { rest: acc, value: Stmt::While(while.value) };
        }
        Token::KMatch => {
            l match = parse_match(acc);
        	dbg_print("< stmt");
            r Parse<Stmt> { rest: acc, value: Stmt::Match(match.value) };
        }
        Token::KBreak => {
            acc = result.rest;
        	dbg_print("< stmt");
            r Parse<Stmt> { rest: acc, value: Stmt::Break };
        }
        Token::KContinue => {
            acc = result.rest;
        	dbg_print("< stmt");
            r Parse<Stmt> { rest: acc, value: Stmt::Continue };
        }
        Token::KReturn => {
            acc = result.rest;
            l expr = parse_expr(acc);
            acc = expr.rest;
        	dbg_print("< stmt");
            r Parse<Stmt> { rest: acc, value: Stmt::Return(expr.value) };
        }
        Token::KLet => {
            l decl = parse_var_decl(acc);
            acc = decl.rest;
        	dbg_print("< stmt");
            r Parse<Stmt> { rest: acc, value: Stmt::VarDecl(decl.value) };
        }
        Token::KVar => {
            l decl = parse_var_decl(acc);
            acc = decl.rest;
        	dbg_print("< stmt");
            r Parse<Stmt> { rest: acc, value: Stmt::VarDecl(decl.value) };
        }
        _ => {
            l expr = parse_expr(acc);
        	dbg_print("< stmt");
            r Parse<Stmt> { rest: acc, value: Stmt::Expr(expr) };
        }
    }
}

f parse_if(input: S) -> Parse<IfStmt> {
    v acc = input;
    dbg_print("> if");

    v if_bodies = V_new<IfBlock>();
    v else_block = O_none<ElseBlock>();

    w (y) {
        acc = next_token(acc).rest; // Kif;
        acc = next_token(acc).rest; // OpenPar;

        l cond = parse_expr(acc);
        acc = cond.rest;

        acc = next_token(acc).rest; // ClosePar;
    
        l body = parse_block(acc);
        acc = body.rest;

        V_push<IfBlock>(&if_bodies, IfBlock { condition: cond.value, stmts: body.value });

        v result = next_token(acc);
        m (result.value) {
            Token::KElse => {
                acc = result.rest;
                result = next_token(acc);
                m (result.value) {
                    Token::KIf => {
                        c;
                    }
                }
                l else_body = parse_block(acc);
                acc = else_body.rest;

                else_block = O_some<ElseBlock>(ElseBlock { stmts: else_body.value });
            }
        }
    }
    
    dbg_print("< if");
    r Parse<IfStmt> { rest: acc, value: IfStmt { if_blocks: if_bodies, else_block: else_block } };
}

f parse_while(input: S) -> Parse<WhileStmt> {
    v acc = input;
    dbg_print("> while");

    acc = next_token(acc).rest; // KWhile;
    acc = next_token(acc).rest; // OpenPar;

    l cond = parse_expr(acc);
    acc = cond.rest;

    acc = next_token(acc).rest; // ClosePar;
    
    l body = parse_block(acc);
    
    dbg_print("< while");
    r Parse<While> { rest: acc, value: WhileStmt { condition: cond.value, stmts: body.value } };
}

f parse_var_decl(input: S) -> Parse<VarDecl> {
    v acc = input;
    dbg_print("> var_decl");

    v mutable = n;
    v result = next_token(acc);
    m (result.value) {
        Token::KVar => {
            mutable = y;
        }
    }
    acc = result.rest;

    l ident = parse_ident(acc);
    acc = ident.rest;

    acc = next_token(acc).rest; // Equals

    l expr = parse_expr(acc);
    acc = expr.rest;
    
    acc = next_token(acc).rest; // Semicolon
    
    dbg_print("< var_decl");
    r Parse<VarDecl> { rest: acc, value: VarDecl { mutable: mutable, ident: ident.value, ty: O_none<Type>(), value: expr } };
}

f parse_expr(input: S) -> Parse<Expr> {
    v acc = input;
    dbg_print("> expr");

    v result = next_token(acc);
    
    dbg_print("< expr");
    r Parse<While> { rest: acc, value: WhileStmt { condition: cond.value, stmts: body.value } };
}

f parse_param_list(input: S) -> Parse<V<Parameter>> {
    v acc = input;
	dbg_print("> param_list");

    v result = next_token(acc);
    // Deliberately elided: acc = result.rest;

    v fields = V_new<Parameter>();

    w (y) {
        result = next_token(acc);
        m (result.value) {
            Token::ClosePar => {
                b;
            }
            Token::Comma => {
                acc = result.rest;
                c;
            }
        }
        l field = parse_param(acc);
        acc = field.rest;
        V_push<Parameter>(&fields, field.value);
    }

	dbg_print("< param_list");
    r Parse<V<Parameter>> { rest: acc, value: fields };
}

f parse_param(input: S) -> Parse<Parameter> {
    v acc = input;
	dbg_print("> param");

    v ident = parse_ident(acc);
    acc = ident.rest;

    acc = next_token(acc).rest; // Colon

    v mutable = n;
    v result = next_token(acc);
    m (result.value) {
        Token::Ampersand => {
            mutable = y;
            acc = result.rest;
        }
    }

    v type = parse_type(acc);
    acc = type.rest;

	dbg_print("< param");
    r Parse<Parameter> {
        rest: acc,
        value: Parameter { label: ident.value, ty: ArgumentType { ty: type.value, mutable: mutable } }
    };
}

// MARK: Types

f parse_struct(input: S) -> Parse<Struct> {
    v acc = input;
	dbg_print("> struct");
    
    v result = next_token(acc);
    acc = result.rest;
    // KStruct

    v ident = parse_ident(acc);
    acc = ident.rest;

    v params = V_new<S>();
	result = next_token(acc);
	m (result.value) {
		Token::Less => {
			acc = result.rest;
			l params_result = parse_generic_params(acc);
            acc = params_result.rest;
            params = params_result.value;

			result = next_token(acc);
			acc = result.rest;
			// Greater
		}
	}

    result = next_token(acc);
    acc = result.rest;
    // OpenBrace

    v fields = parse_field_list(acc);
    acc = fields.rest;

    result = next_token(acc);
    acc = result.rest;
    // CloseBrace

	dbg_print("< struct");
    r Parse<Struct> {
		rest: acc,
		value: Struct { ident: ident.value, generic_parameters: params, fields: fields.value }
	};
}

f parse_field_list(input: S) -> Parse<V<Field>> {
    v acc = input;
	dbg_print("> field_list");

    v result = next_token(acc);
    // Deliberately elided: acc = result.rest;

    v fields = V_new<Field>();

    w (y) {
        result = next_token(acc);
        m (result.value) {
            Token::CloseBrace => {
                b;
            }
            Token::Comma => {
                acc = result.rest;
                c;
            }
        }
        l field = parse_field(acc);
        acc = field.rest;
        V_push<Field>(&fields, field.value);
    }

	dbg_print("< field_list");
    r Parse<V<Field>> { rest: acc, value: fields };
}

f parse_field(input: S) -> Parse<Field> {
    v acc = input;
	dbg_print("> field");

    v ident = parse_ident(acc);
    acc = ident.rest;

    acc = next_token(acc).rest; // Colon

    v type = parse_type(acc);
    acc = type.rest;

	dbg_print("< field");
    r Parse<Field> { rest: acc, value: Field { ident: ident.value, ty: type.value } };
}

f parse_enum(input: S) -> Parse<Enum> {
    v acc = input;
	dbg_print("> enum");
    
    v result = next_token(acc);
    acc = result.rest;
    // KType

    l ident = parse_ident(acc);
    acc = ident.rest;

    result = next_token(acc);
    acc = result.rest;
    // OpenBrace

    l cases = parse_case_list(acc);
    acc = cases.rest;

    result = next_token(acc);
    acc = result.rest;
    // CloseBrace

	dbg_print("< enum");
    r Parse<Enum> { rest: acc, value: Enum { ident: ident.value, cases: cases.value } };
}

f parse_case_list(input: S) -> Parse<V<Case>> {
    v acc = input;
	dbg_print("> case_list");

    v result = next_token(acc);
    // Deliberately elided: acc = result.rest;

    v cases = V_new<Case>();
    w (y) {
        result = next_token(acc);
        m (result.value) {
            Token::CloseBrace => {
                b;
            }
            Token::Comma => {
                acc = result.rest;
                c;
            }
        }
        l case = parse_case(acc);
        acc = case.rest;
        V_push<Case>(&cases, case.value);
    }

	dbg_print("< case_list");
    r Parse<V<Case>> { rest: acc, value: cases };
}

f parse_case(input: S) -> Parse<Case> {
    v acc = input;
	dbg_print("> case");

    v ident = parse_ident(acc);
    acc = ident.rest;

    v type = O_none<Type>();
    v result = next_token(acc);
    m (result.value) {
        Token::OpenPar => {
		    acc = result.rest;

            v type_result = parse_type(acc);
            acc = type_result.rest;
            type = O_some<Type>(type_result.value);

            acc = next_token(acc).rest; // ClosePar;
        }
    }

	dbg_print("< case");
    r Parse<Case> { rest: acc, value: Case { ident: ident.value, ty: type } };
}

// MARK: Shared

f parse_type(input: S) -> Parse<Type> {
    v acc = input;
	dbg_print("> type");
	
    v ident = parse_ident(input);
    acc = ident.rest;

    v generic_params = V_new<Type>();
	v result = next_token(acc);
	m (result.value) {
		Token::Less => {
			acc = result.rest;
			l params = parse_generic_args(acc);
            generic_params = params.value;
            acc = params.rest;

			result = next_token(acc);
			acc = result.rest;
			// Greater
		}
	}

	dbg_print("< type");
	r Parse<Type> { rest: acc, value: Type { ident: ident.value, generic_parameters: generic_params } };
}

f parse_generic_args(input: S) -> Parse<V<Type>> {
    v acc = input;
	dbg_print("> generic_args");

    v types = V_new<Type>();
	
    w (y) {
        v result = next_token(acc);
        m (result.value) {
            Token::Id(ident) => {
                l type = parse_type(acc);
                acc = type.rest;
                V_push<Type>(&types, type.value);
                c;
            }
            Token::Comma => {
                acc = result.rest;
                c;
            }
        }
        b;
    }

	dbg_print("< generic_args");
	r Parse<V<Type>> { rest: acc, value: types };
}

f parse_generic_params(input: S) -> Parse<V<S>> {
    v acc = input;
	dbg_print("> generic_params");

    v idents = V_new<S>();
	
    w (y) {
        v result = next_token(acc);
        m (result.value) {
            Token::Id(ident) => {
                acc = result.rest;
                V_push<S>(&idents, ident);
                c;
            }
            Token::Comma => {
                acc = result.rest;
                c;
            }
        }
        b;
    }

	dbg_print("< generic_params");
	r Parse<V<S>> { rest: acc, value: idents };
}

f parse_ident(input: S) -> Parse<S> {
    v acc = input;
    dbg_print("> ident");

    v result = next_token(acc);
    acc = result.rest;
    m (result.value) {
        Token::Id(ident) => {
            dbg_print("< ident");
            r Parse<S> { rest: acc, value: ident };
        }
    }
}
