f parse(input: S) -> Ast {
    v acc = input;

    w (y) {
        l result = next_token(acc);
        // acc = result.rest;

        v decls = V_new<Decl>();

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

f parse_function(input: S) -> Parse<I> {
	dbg_print("> function");
    v acc = input;

    v result = next_token(acc);
    acc = result.rest;
    // KFunction

    l name = parse_ident(acc);
    acc = name.rest;
    
	dbg_print("< function");
    r Parse<I> { rest: acc, value: 0 };
}

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
			params = parse_generic_params(acc);

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
            acc = type.rest;
            type = O_some<Type>(type_result.value);

            acc = next_token(acc).rest; // ClosePar;
        }
    }

	dbg_print("< case");
    r Parse<Case> { rest: acc, value: Case { ident: ident.value, ty: type } };
}

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
