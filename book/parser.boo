f parse(input: S) {
    v acc = input;

    w (y) {
        l result = next_token(acc);
        // acc = result.remainder;

        m (result.value) {
            Token::KFunction => {
                l ast = parse_function(acc);
                acc = ast.remainder;
            }
            Token::KStruct => {
                l ast = parse_struct(acc);
                acc = ast.remainder;
            }
            Token::KType => {
                l ast = parse_enum(acc);
                acc = ast.remainder;
            }
            Token::Eof => {
                r;
            }
        }
    }
}

f parse_function(input: S) -> Parse<I> {
	dbg_print("> function");
    v acc = input;
    
	dbg_print("< function");
    r Parse<I> { remainder: acc, value: 0 };
}

f parse_struct(input: S) -> Parse<Struct> {
    v acc = input;
	dbg_print("> struct");
    
    v result = next_token(acc);
    acc = result.remainder;
    // KStruct

	v type = parse_type(acc);

    result = next_token(acc);
    acc = result.remainder;
    print_token(result.value);
    // OpenBrace

    v fields = parse_field_list(acc);
    acc = fields.remainder;

    result = next_token(acc);
    acc = result.remainder;
    print_token(result.value);
    // CloseBrace

	dbg_print("< function");
    r Parse<Struct> {
		remainder: acc,
		value: Struct { ident: type.value.ident, generic_params: type.generic_params, fields: fields }
	};
}

f parse_field_list(input: S) -> Parse<I> {
    v acc = input;
	dbg_print("> field_list");

    v result = next_token(acc);
    // Deliberately elided: acc = result.remainder;

    w (y) {
        result = next_token(acc);
        print_token(result.value);
        m (result.value) {
            Token::CloseBrace => {
                b;
            }
            Token::Comma => {
                acc = result.remainder;
                c;
            }
        }
        acc = result.remainder;
    }

	dbg_print("< field_list");
    r Parse<I> { remainder: acc, value: 0 };
}

f parse_enum(input: S) -> Parse<I> {
    v acc = input;
	dbg_print("> enum");
    
    v result = next_token(acc);
    acc = result.remainder;
    // KType

    result = next_token(acc);
    acc = result.remainder;
    v name = "TEMP";
    m (result.value) {
        Token::Id(ident) => {
            name = ident;
        }
    }

    result = next_token(acc);
    acc = result.remainder;
    // OpenBrace

    parse_case_list(acc);

    result = next_token(acc);
    acc = result.remainder;
    // CloseBrace

	dbg_print("< enum");
    r Parse<I> { remainder: acc, value: 0 };
}

f parse_case_list(input: S) -> Parse<I> {
    v acc = input;
	dbg_print("> case_list");

    v result = next_token(acc);
    // Deliberately elided: acc = result.remainder;

    w (y) {
        result = next_token(acc);
        print_token(result.value);
        m (result.value) {
            Token::CloseBrace => {
                b;
            }
            Token::Comma => {
                acc = result.remainder;
                c;
            }
        }
        parse_case(acc);
    }

	dbg_print("< case_list");
    r Parse<I> { remainder: acc, value: 0 };
}

f parse_case(input: S) -> Parse<I> {
    v acc = input;
	dbg_print("> case");

    v result = next_token(acc);
    acc = result.remainder;

    v name = "TEMP";
    m (result.value) {
        Token::Id(ident) => {
            name = ident;
        }
    }

    result = next_token(acc);
    m (result.value) {
        Token::OpenPar => {
		    acc = result.remainder;

			v type = parse_type(acc);
        }
    }

	dbg_print("< case");
    r Case { name: name, ty: name };
}

f parse_type(input: S) -> Parse<Type> {
    v acc = input;
	dbg_print("> type");
	
    v result = next_token(acc);
    acc = result.remainder;

    v name = "TEMP";
    m (result.value) {
        Token::Id(ident) => {
            name = ident;
        }
    }

	result = next_token(acc);
	m (result.value) {
		Token::Less => {
			acc = result.remainder;
			l params = parse_generic_params(acc);

			result = next_token(acc);
			acc = result.remainder;
			// Greater
		}
	}

	dbg_print("< type");
	r Type { ident: name, generic_parameters: V_new() };
}
