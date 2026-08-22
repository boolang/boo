s Struct {
    ident: S,
}

s Case {
    name: Ident,
    ty: Type,
}

t Type {
    Simple(SimpleType)
}

s SimpleType {
    ident: Ident,
    // generic_parameters: Vec<Type>,
}

s Parse<T> {
    remainder: S,
    value: T,
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
    Eof,
}
