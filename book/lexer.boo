f print_token(token: Token) {
    m (token) {
        Token::Id(ident) => {
            print("Ident:");
            print(ident);
        }
        Token::Int(int) => {
            print("Int:");
            print(I_to_string(int));
        }
        Token::Char(char) => {
            print("Char:");
            print(S_new_from_char(char));
        }
        Token::String(string) => {
            print("String:");
            print(string);
        }
        Token::KBreak => {
            print("KBreak");
        }
        Token::KContinue => {
            print("KContinue");
        }
        Token::KElse => {
            print("KElse");
        }
        Token::KFunction => {
            print("KFunction");
        }
        Token::KIf => {
            print("KIf");
        }
        Token::KLet => {
            print("KLet");
        }
        Token::KMatch => {
            print("KMatch");
        }
        Token::KReturn => {
            print("KReturn");
        }
        Token::KStruct => {
            print("KStruct");
        }
        Token::KType => {
            print("KType");
        }
        Token::KVar => {
            print("KVar");
        }
        Token::KWhile => {
            print("KWhile");
        }
        Token::OpenPar => {
            print("OpenPar");
        }
        Token::ClosePar => {
            print("ClosePar");
        }
        Token::OpenBracket => {
            print("OpenBracket");
        }
        Token::CloseBracket => {
            print("CloseBracket");
        }
        Token::OpenBrace => {
            print("OpenBrace");
        }
        Token::CloseBrace => {
            print("CloseBrace");
        }
        Token::Colon => {
            print("Colon");
        }
        Token::DoubleColon => {
            print("DoubleColon");
        }
        Token::Semicolon => {
            print("Semicolon");
        }
        Token::Arrow => {
            print("Arrow");
        }
        Token::DoubleArrow => {
            print("DoubleArrow");
        }
        Token::Comma => {
            print("Comma");
        }
        Token::Dot => {
            print("Dot");
        }
        Token::Equals => {
            print("Equals");
        }
        Token::Bang => {
            print("Bang");
        }
        Token::Less => {
            print("Less");
        }
        Token::Greater => {
            print("Greater");
        }
        Token::Ampersand => {
            print("Ampersand");
        }
        Token::Eof => {
            print("Eof");
        }
    }
}

f next_token(input: S) -> Parse<Token> {
    v acc = input;
    w (y) {
        i (S_is_empty(acc)) {
            r Parse<Token> { remainder: acc, value: Token::Eof };
        }
        i (not(or(
            or(or(C_eq(acc[0], ' '), C_eq(acc[0], '\n')), or(C_eq(acc[0], '\t'), C_eq(acc[0], '\r'))),
            C_eq(acc[0], '/')
        ))) {
            b;
        }
        i (C_eq(acc[0], '/')) {
            i (C_eq(acc[1], '/')) {
                w (not(C_eq(acc[0], '\n'))) {
                    acc = S_advance(acc, 1);
                }
            } e {
                b;
            }
        }
        acc = S_advance(acc, 1);
    }

    i (or(or(and(C_ge(acc[0], 'A'), C_le(acc[0], 'Z')), and(C_ge(acc[0], 'a'), C_le(acc[0], 'z'))), C_eq(acc[0], '_'))) {
        l result = lex_ident(acc);
        l ident = result.value;

        i (S_eq(ident, "b")) {
            r Parse<Token> { remainder: result.remainder, value: Token::KBreak };
        } e i (S_eq(ident, "c")) {
            r Parse<Token> { remainder: result.remainder, value: Token::KContinue };
        } e i (S_eq(ident, "e")) {
            r Parse<Token> { remainder: result.remainder, value: Token::KElse };
        } e i (S_eq(ident, "f")) {
            r Parse<Token> { remainder: result.remainder, value: Token::KFunction };
        } e i (S_eq(ident, "i")) {
            r Parse<Token> { remainder: result.remainder, value: Token::KIf };
        } e i (S_eq(ident, "l")) {
            r Parse<Token> { remainder: result.remainder, value: Token::KLet };
        } e i (S_eq(ident, "m")) {
            r Parse<Token> { remainder: result.remainder, value: Token::KMatch };
        } e i (S_eq(ident, "r")) {
            r Parse<Token> { remainder: result.remainder, value: Token::KReturn };
        } e i (S_eq(ident, "s")) {
            r Parse<Token> { remainder: result.remainder, value: Token::KStruct };
        } e i (S_eq(ident, "t")) {
            r Parse<Token> { remainder: result.remainder, value: Token::KType };
        } e i (S_eq(ident, "v")) {
            r Parse<Token> { remainder: result.remainder, value: Token::KVar };
        } e i (S_eq(ident, "w")) {
            r Parse<Token> { remainder: result.remainder, value: Token::KWhile };
        } e {
            r Parse<Token> { remainder: result.remainder, value: Token::Id(ident) };
        }
    } e i (or(and(C_ge(acc[0], '0'), C_le(acc[0], '9')), or(C_eq(acc[0], '-'), C_eq(acc[0], '+')))) {
        l result = lex_number(acc);
        r Parse<Token> { remainder: result.remainder, value: Token::Int(result.value) };
    } e i (C_eq(acc[0], '"')) {
        l result = lex_string(acc);
        r Parse<Token> { remainder: result.remainder, value: Token::String(result.value) };
    } e i (C_eq(acc[0], '\'')) {
        l result = lex_char(acc);
        r Parse<Token> { remainder: result.remainder, value: Token::Char(result.value) };
    } e i (and(C_eq(acc[0], '-'), C_eq(acc[1], '>'))) {
        r Parse<Token> { remainder: S_advance(acc, 2), value: Token::Arrow };
    } e i (and(C_eq(acc[0], '='), C_eq(acc[1], '>'))) {
        r Parse<Token> { remainder: S_advance(acc, 2), value: Token::DoubleArrow };
    } e i (and(C_eq(acc[0], ':'), C_eq(acc[1], ':'))) {
        r Parse<Token> { remainder: S_advance(acc, 2), value: Token::DoubleColon };
    } e i (C_eq(acc[0], '(')) {
        r Parse<Token> { remainder: S_advance(acc, 1), value: Token::OpenPar };
    } e i (C_eq(acc[0], ')')) {
        r Parse<Token> { remainder: S_advance(acc, 1), value: Token::ClosePar };
    } e i (C_eq(acc[0], '[')) {
        r Parse<Token> { remainder: S_advance(acc, 1), value: Token::OpenBracket };
    } e i (C_eq(acc[0], ']')) {
        r Parse<Token> { remainder: S_advance(acc, 1), value: Token::CloseBracket };
    } e i (C_eq(acc[0], '{')) {
        r Parse<Token> { remainder: S_advance(acc, 1), value: Token::OpenBrace };
    } e i (C_eq(acc[0], '}')) {
        r Parse<Token> { remainder: S_advance(acc, 1), value: Token::CloseBrace };
    } e i (C_eq(acc[0], ':')) {
        r Parse<Token> { remainder: S_advance(acc, 1), value: Token::Colon };
    } e i (C_eq(acc[0], ';')) {
        r Parse<Token> { remainder: S_advance(acc, 1), value: Token::Semicolon };
    } e i (C_eq(acc[0], ',')) {
        r Parse<Token> { remainder: S_advance(acc, 1), value: Token::Comma };
    } e i (C_eq(acc[0], '.')) {
        r Parse<Token> { remainder: S_advance(acc, 1), value: Token::Dot };
    } e i (C_eq(acc[0], '=')) {
        r Parse<Token> { remainder: S_advance(acc, 1), value: Token::Equals };
    } e i (C_eq(acc[0], '!')) {
        r Parse<Token> { remainder: S_advance(acc, 1), value: Token::Bang };
    } e i (C_eq(acc[0], '<')) {
        r Parse<Token> { remainder: S_advance(acc, 1), value: Token::Less };
    } e i (C_eq(acc[0], '>')) {
        r Parse<Token> { remainder: S_advance(acc, 1), value: Token::Greater };
    } e i (C_eq(acc[0], '&')) {
        r Parse<Token> { remainder: S_advance(acc, 1), value: Token::Ampersand };
    }

    print("oops");
    print(acc);
}

f lex_ident(input: S) -> Parse<S> {
    v acc = S_advance(input, 1);
    v ident = S_new_from_char(input[0]);

    w (or(or(and(C_ge(acc[0], 'A'), C_le(acc[0], 'Z')), and(C_ge(acc[0], 'Z'), C_le(acc[0], 'z'))), or(and(C_ge(acc[0], '0'), C_le(acc[0], '9')), C_eq(acc[0], '_')))) {
        ident = S_push(ident, acc[0]);
        acc = S_advance(acc, 1);
    }

    r Parse<S> { remainder: acc, value: ident };
}

f lex_number(input: S) -> Parse<I> {
    v acc = input;
    v negate = n;

    i (C_eq(acc[0], '-')) {
        acc = S_advance(acc, 1);
        negate = y;
    } e i (C_eq(acc[0], '+')) {
        acc = S_advance(acc, 1);
    }
    
    v result = parse_dec(acc);
    i (C_eq(acc[0], '0')) {
        i (C_eq(acc[1], 'b')) {
            result = parse_bin(S_advance(acc, 2));
        } e i (C_eq(acc[1], 'o')) {
            result = parse_oct(S_advance(acc, 2));
        } e i (C_eq(acc[1], 'x')) {
            result = parse_hex(S_advance(acc, 2));
        }
    }
    i (negate) {
        result.value = I_neg(result.value);
    }
    r result;
}

f parse_bin(input: S) -> Parse<I> {
    v acc = input;
    v num = 0;

    w (and(C_ge(acc[0], '0'), C_le(acc[0], '1'))) {
        num = I_add(I_mul(2, num), I_sub(C_ord(acc[0]), C_ord('0')));
        acc = S_advance(acc, 1);
    }

    r Parse<I> { remainder: acc, value: num };
}

f parse_oct(input: S) -> Parse<I> {
    v acc = input;
    v num = 0;

    w (and(C_ge(acc[0], '0'), C_le(acc[0], '7'))) {
        num = I_add(I_mul(8, num), I_sub(C_ord(acc[0]), C_ord('0')));
        acc = S_advance(acc, 1);
    }

    r Parse<I> { remainder: acc, value: num };
}

f parse_hex(input: S) -> Parse<I> {
    v acc = input;
    v num = 0;

    w (or(and(C_ge(acc[0], '0'), C_le(acc[0], '9')), or(and(C_ge(acc[0], 'A'), C_le(acc[0], 'F')), and(C_ge(acc[0], 'a'), C_le(acc[0], 'f'))))) {
        i (and(C_ge(acc[0], '0'), C_le(acc[0], '9'))) {
            num = I_add(I_mul(16, num), I_sub(C_ord(acc[0]), C_ord('0')));
        } e i (and(C_ge(acc[0], 'A'), C_le(acc[0], 'F'))) {
            num = I_add(I_mul(16, num), I_sub(C_ord(acc[0]), C_ord('A')));
        } e i (and(C_ge(acc[0], 'a'), C_le(acc[0], 'f'))) {
            num = I_add(I_mul(16, num), I_sub(C_ord(acc[0]), C_ord('a')));
        }
        acc = S_advance(acc, 1);
    }

    r Parse<I> { remainder: acc, value: num };
}

f parse_dec(input: S) -> Parse<I> {
    v acc = input;
    v num = 0;

    w (and(C_ge(acc[0], '0'), C_le(acc[0], '9'))) {
        num = I_add(I_mul(10, num), I_sub(C_ord(acc[0]), C_ord('0')));
        acc = S_advance(acc, 1);
    }

    r Parse<I> { remainder: acc, value: num };
}

f lex_char(input: S) -> Parse<C> {
    v acc = S_advance(input, 1);

    i (C_eq(acc[0], '\\')) {
        i (C_eq(acc[1], 'n')) {
            r Parse<C> { remainder: S_advance(acc, 3), value: '\n' };
        } e i (C_eq(acc[1], 't')) {
            r Parse<C> { remainder: S_advance(acc, 3), value: '\t' };
        } e i (C_eq(acc[1], 'r')) {
            r Parse<C> { remainder: S_advance(acc, 3), value: '\r' };
        } e {
            r Parse<C> { remainder: S_advance(acc, 3), value: acc[1] };
        }
    } e {
        r Parse<C> { remainder: S_advance(acc, 2), value: acc[0] };
    }

    r Parse<C> { remainder: S_advance(acc, 2), value: string };
}

f lex_string(input: S) -> Parse<S> {
    v acc = S_advance(input, 1);
    v string = "";

    w (not(C_eq(acc[0], '"'))) {
        i (C_eq(acc[0], '\\')) {
            i (C_eq(acc[1], 'n')) {
                string = S_push(string, '\n');
            } e i (C_eq(acc[1], 't')) {
                string = S_push(string, '\t');
            } e i (C_eq(acc[1], 'r')) {
                string = S_push(string, '\r');
            } e {
                string = S_push(string, acc[1]);
            }
            acc = S_advance(acc, 2);
        } e {
            string = S_push(string, acc[0]);
            acc = S_advance(acc, 1);
        }
    }

    r Parse<S> { remainder: S_advance(acc, 1), value: string };
}
