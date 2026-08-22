// Required built-ins:
// * read(S) (read the contents of a file)

f main() {
    // TODO: Get target file/files from argv
    // l src = "hello.boo";
    // l contents = read(src);
    l contents = "// thiaenstrahsieanthiea s tuokwtj
    -0x1023
     {}";
    print(next_token(next_token(contents).remainder).remainder);

    print(I_to_string(lex_number("1234 ").value));
    print(I_to_string(lex_number("-1234 ").value));
    print(I_to_string(lex_number("0x1234 ").value));
    print(I_to_string(lex_number("-0x1234 ").value));
    print(I_to_string(lex_number("+0b10110 ").value));
}

s TokenParse {
    remainder: S,
    value: Token,
}

s StringParse {
    remainder: S,
    value: S,
}

s NumberParse {
    remainder: S,
    value: I,
}

t Token {
    Id(S),
    Int(I),
    Char(C),
    String(S),
    KBreak,
    KContinue,
    KElse,
    KFunction,
    KIf,
    KLet,
    KMatch,
    KReturn,
    KStruct,
    KType,
    KVar,
    KWhile,
    OpenPar,
    ClosePar,
    OpenBracket,
    CloseBracket,
    OpenBrace,
    CloseBrace,
    Colon,
    DoubleColon,
    Semicolon,
    Arrow,
    DoubleArrow,
    Comma,
    Dot,
    Equals,
    Bang,
    Less,
    Greater,
    Ampersand,
}

f next_token(input: S) -> TokenParse {
    v acc = input;
    w (or(
        or(or(C_eq(acc[0], ' '), C_eq(acc[0], '\n')), or(C_eq(acc[0], '\t'), C_eq(acc[0], '\r'))),
        and(C_eq(acc[0], '/'), C_eq(acc[1], '/'))
    )) {
        i (and(C_eq(acc[0], '/'), C_eq(acc[1], '/'))) {
            w (not(C_eq(acc[0], '\n'))) {
                acc = S_advance(acc, 1);
            }
        }
        acc = S_advance(acc, 1);
    }

    i (or(or(and(C_ge(acc[0], 'A'), C_le(acc[0], 'Z')), and(C_ge(acc[0], 'a'), C_le(acc[0], 'z'))), C_eq(acc[0], '_'))) {
        l result = lex_ident(acc);
        l ident = result.value;

        i (S_eq(ident, "b")) {
            r TokenParse { remainder: result.remainder, value: Token::KBreak };
        } e i (S_eq(ident, "c")) {
            r TokenParse { remainder: result.remainder, value: Token::KContinue };
        } e i (S_eq(ident, "e")) {
            r TokenParse { remainder: result.remainder, value: Token::KElse };
        } e i (S_eq(ident, "f")) {
            r TokenParse { remainder: result.remainder, value: Token::KFunction };
        } e i (S_eq(ident, "i")) {
            r TokenParse { remainder: result.remainder, value: Token::KIf };
        } e i (S_eq(ident, "l")) {
            r TokenParse { remainder: result.remainder, value: Token::KLet };
        } e i (S_eq(ident, "m")) {
            r TokenParse { remainder: result.remainder, value: Token::KMatch };
        } e i (S_eq(ident, "r")) {
            r TokenParse { remainder: result.remainder, value: Token::KReturn };
        } e i (S_eq(ident, "s")) {
            r TokenParse { remainder: result.remainder, value: Token::KStruct };
        } e i (S_eq(ident, "t")) {
            r TokenParse { remainder: result.remainder, value: Token::KType };
        } e i (S_eq(ident, "v")) {
            r TokenParse { remainder: result.remainder, value: Token::KVar };
        } e i (S_eq(ident, "w")) {
            r TokenParse { remainder: result.remainder, value: Token::KWhile };
        } e {
            r TokenParse { remainder: result.remainder, value: Token::Id(ident) };
        }
    } e i (or(and(C_ge(acc[0], '0'), C_le(acc[0], '9')), or(C_eq(acc[0], '-'), C_eq(acc[0], '+')))) {
        l result = lex_number(acc);
        r TokenParse { remainder: result.remainder, value: Token::Int(result.value) };
    } e i (and(C_eq(acc[0], '-'), C_eq(acc[1], '>'))) {
        r TokenParse { remainder: S_advance(acc, 2), value: Token::Arrow };
    } e i (and(C_eq(acc[0], '='), C_eq(acc[1], '>'))) {
        r TokenParse { remainder: S_advance(acc, 2), value: Token::DoubleArrow };
    } e i (and(C_eq(acc[0], ':'), C_eq(acc[1], ':'))) {
        r TokenParse { remainder: S_advance(acc, 2), value: Token::DoubleColon };
    } e i (C_eq(acc[0], '(')) {
        r TokenParse { remainder: S_advance(acc, 1), value: Token::OpenPar };
    } e i (C_eq(acc[0], ')')) {
        r TokenParse { remainder: S_advance(acc, 1), value: Token::ClosePar };
    } e i (C_eq(acc[0], '[')) {
        r TokenParse { remainder: S_advance(acc, 1), value: Token::OpenBracket };
    } e i (C_eq(acc[0], ']')) {
        r TokenParse { remainder: S_advance(acc, 1), value: Token::CloseBracket };
    } e i (C_eq(acc[0], '{')) {
        r TokenParse { remainder: S_advance(acc, 1), value: Token::OpenBrace };
    } e i (C_eq(acc[0], '}')) {
        r TokenParse { remainder: S_advance(acc, 1), value: Token::CloseBrace };
    } e i (C_eq(acc[0], ':')) {
        r TokenParse { remainder: S_advance(acc, 1), value: Token::Colon };
    } e i (C_eq(acc[0], ';')) {
        r TokenParse { remainder: S_advance(acc, 1), value: Token::Semicolon };
    } e i (C_eq(acc[0], ',')) {
        r TokenParse { remainder: S_advance(acc, 1), value: Token::Comma };
    } e i (C_eq(acc[0], '.')) {
        r TokenParse { remainder: S_advance(acc, 1), value: Token::Dot };
    } e i (C_eq(acc[0], '=')) {
        r TokenParse { remainder: S_advance(acc, 1), value: Token::Equals };
    } e i (C_eq(acc[0], '!')) {
        r TokenParse { remainder: S_advance(acc, 1), value: Token::Bang };
    } e i (C_eq(acc[0], '<')) {
        r TokenParse { remainder: S_advance(acc, 1), value: Token::Less };
    } e i (C_eq(acc[0], '>')) {
        r TokenParse { remainder: S_advance(acc, 1), value: Token::Greater };
    } e i (C_eq(acc[0], '&')) {
        r TokenParse { remainder: S_advance(acc, 1), value: Token::Ampersand };
    }
}

f lex_ident(input: S) -> StringParse {
    v acc = S_advance(input, 1);
    v ident = S_new_from_char(input[0]);

    w (or(or(and(C_ge(acc[0], 'A'), C_le(acc[0], 'Z')), and(C_ge(acc[0], 'Z'), C_le(acc[0], 'z'))), or(and(C_ge(acc[0], '0'), C_le(acc[0], '9')), C_eq(acc[0], '_')))) {
        ident = S_push(ident, acc[0]);
        acc = S_advance(acc, 1);
    }

    r StringParse { remainder: acc, value: ident };
}

f lex_number(input: S) -> NumberParse {
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

f parse_bin(input: S) -> NumberParse {
    v acc = input;
    v num = 0;

    w (and(C_ge(acc[0], '0'), C_le(acc[0], '1'))) {
        num = I_add(I_mul(2, num), I_sub(C_ord(acc[0]), C_ord('0')));
        acc = S_advance(acc, 1);
    }

    r NumberParse { remainder: acc, value: num };
}

f parse_oct(input: S) -> NumberParse {
    v acc = input;
    v num = 0;

    w (and(C_ge(acc[0], '0'), C_le(acc[0], '7'))) {
        num = I_add(I_mul(8, num), I_sub(C_ord(acc[0]), C_ord('0')));
        acc = S_advance(acc, 1);
    }

    r NumberParse { remainder: acc, value: num };
}

f parse_hex(input: S) -> NumberParse {
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

    r NumberParse { remainder: acc, value: num };
}

f parse_dec(input: S) -> NumberParse {
    v acc = input;
    v num = 0;

    w (and(C_ge(acc[0], '0'), C_le(acc[0], '9'))) {
        num = I_add(I_mul(10, num), I_sub(C_ord(acc[0]), C_ord('0')));
        acc = S_advance(acc, 1);
    }

    r NumberParse { remainder: acc, value: num };
}
