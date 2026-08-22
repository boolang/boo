f parse(input: S) {
    v acc = input;

    w (y) {
        l result = next_token(acc);
        // acc = result.remainder;

        print_token(result.value);
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
                l ast = parse_type(acc);
                acc = ast.remainder;
            }
            Token::Eof => {
                r;
            }
        }
    }
}

f parse_function(input: S) -> Parse<I> {
    v acc = input;
    
    r Parse<I> { remainder: acc, value: 0 };
}

f parse_struct(input: S) -> Parse<Struct> {
    v acc = input;
    
    v result = next_token(acc);
    acc = result.remainder;
    // KStruct

    result = next_token(acc);
    acc = result.remainder;
    v name = "FIXME";
    m (result.value) {
        Token::Id(ident) => {
            name = ident;
        }
    }

    result = next_token(acc);
    acc = result.remainder;
    print_token(result.value);
    // OpenBrace

    v ast = parse_field_list(acc);
    acc = ast.remainder;

    result = next_token(acc);
    acc = result.remainder;
    print_token(result.value);
    // CloseBrace

    r Parse<Struct> { remainder: acc, value: Struct { ident: name } };
}

f parse_field_list(input: S) -> Parse<I> {
    v acc = input;

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

    r Parse<I> { remainder: acc, value: 0 };
}

f parse_type(input: S) -> Parse<I> {
    v acc = input;
    
    v result = next_token(acc);
    acc = result.remainder;
    // KType

    result = next_token(acc);
    acc = result.remainder;
    v name = "FIXME";
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

    r Parse<I> { remainder: acc, value: 0 };
}

f parse_case_list(input: S) -> Parse<I> {
    v acc = input;

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

    r Parse<I> { remainder: acc, value: 0 };
}

f parse_case(input: S) -> Parse<I> {
    v acc = input;

    v result = next_token(acc);
    acc = result.remainder;

    v name = "FIXME";
    m (result.value) {
        Token::Id(ident) => {
            name = ident;
        }
    }

    v result = next_token(acc);
    m (result.value) {
        Token::OpenPar => {
            print("aa");
        }
    }

    r Case { name: name, ty: name };
}
