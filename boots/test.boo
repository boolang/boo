f lex_char(input: S) -> CharParse {
    v acc = S_advance(input, 1);

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
        r CharParse { remainder: S_advance(acc, 1), value: string };
    }

    r CharParse { remainder: S_advance(acc, 1), value: string };
}
