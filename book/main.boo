// Required built-ins:
// * read(S) (read the contents of a file)

f main() {
    // TODO: Get target file/files from argv
    // l src = "hello.boo";
    // l contents = read(src);
    l contents = "f main() {}";
    print(contents);
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
    kind: Kind,
    content: S
}

f next_token(input: S) -> TokenResult {
    v acc = input;
    w (or(
        or(or(eq(acc[0], ' '), eq(acc[0], '\n')), or(eq(acc[0], '\t'), eq(acc[0], '\r'))),
        or(and(eq(acc[0], '/'), eq(acc[1], '/')))
    )) {
        i (or(and(eq(acc[0], '/'), eq(acc[1], '/')))) {
            w (not(eq(acc[0], '\n'))) {
                acc = advance(acc, 1);
            }
        }
        acc = advance(acc, 1);
    }

    r Token { kind: Ident, content: input };
}
