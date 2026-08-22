// Required built-ins:
// * read(S) (read the contents of a file)

f main() {
    // TODO: Get target file/files from argv
    // l src = "hello.boo";
    // l contents = read(src);
    l contents = "// thiaenstrahsieanthiea s tuokwtj
      f main() {}";
    print(next_token(contents).content);
}

s TokenResult {
    remainder: S,
    token: Token
}

t Kind {
    Ident,
    Comment,
    LParen,
    RParen
}

s Token {
    content: S
}

f next_token(input: S) -> TokenResult {
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

    r Token { content: acc };
}
