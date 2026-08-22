// Built-ins (these will be built-ins in the interpreter, but the compiler will
// probably have lower level built-ins and these can be defined and implemented
// in a stdlib prelude)
//
//   f V_new<T>() -> V<T>; 
//   f V_append<T>(vec: &V<T>, element: T); 
//   f S_new_with_chars(chars: V<C>) -> S;
//   f S_concat(left: S, right: S) -> S;

f c_to_s(char: C) -> S {
    // At first (and maybe forever), we should always require explicitly
    // specifying generics (otherwise we have to write a whole inference thing).
    l chars = V_new<C>();
    V_append<C>(&chars, char);
    r S_new_with_chars(chars);
}

t Kind {
    Ident,
    Comment,
    LParen,
    RParen,
}

s Token {
    kind: Kind,
    content: S,
}

f Kind_description(kind: Kind) -> S {
    m (kind) {
        Ident => {
            r "ident";
        }
        Comment => {
            r "comment";
        }
        LParen => {
            r "left_paren";
        }
        RParen => {
            r "right_paren";
        }
    }
}

f Token_print(token: Token) {
    print(S_concat("Kind:    ", Kind_description(token.kind)));
    print(S_concat("Content: ", token.content));
}

f main() {
    l contents = read("feature_test.boo");
    print("My code is:");
    print(contents);

    print("The first char is:");
    print(c_to_s(contents[0]));

    l token = Token {
        kind: Kind::Comment,
        content: "// This is a comment",
    };
    Token_print(token);
}
