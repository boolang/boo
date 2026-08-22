// Required built-ins:
// * read(S) (read the contents of a file)

f main() {
    // TODO: Get target file/files from argv
    // l src = "hello.boo";
    // l contents = read(src);
    l contents = "// thiaenstrahsieanthiea s tuokwtj
      f main() {}";
    print(next_token(contents).remainder);
}

s TokenParse {
    remainder: S,
    value: Token,
}

s StringParse {
    remainder: S,
    value: S,
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
        l result = next_ident(acc);
        acc = result.remainder;
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
    }

    r TokenParse { remainder: acc };
}

f next_ident(input: S) -> StringParse {
    v acc = S_advance(input, 1);
    v ident = S_new_from_char(input[0]);

    w (or(or(and(C_ge(acc[0], 'A'), C_le(acc[0], 'Z')), and(C_ge(acc[0], 'Z'), C_le(acc[0], 'z'))), or(and(C_ge(acc[0], '0'), C_le(acc[0], '9')), C_eq(acc[0], '_')))) {
        ident = S_push(ident, acc[0]);
        acc = S_advance(acc, 1);
    }

    r StringParse { remainder: acc, value: ident };
}
