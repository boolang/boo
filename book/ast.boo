// t Option<T> {
// 	Some(T),
// 	None,
// }

s Type {
    ident: S,
    generic_parameters: V<Type>,
}

s ArgumentType {
    ty: Type,
    mutable: B,
}

t ArgumentValue {
    Immutable(Expr),
    Mutable(PlaceExpr),
}

s FunctionCallExpr {
    ident: S,
    generic_parameters: V<Type>,
    arguments: V<ArgumentValue>,
}

s StructInitExpr {
    ident: S,
    generic_parameters: V<Type>,
    arguments: V<StructInitArgument>,
}

s StructInitArgument {
    label: S,
    value: Expr,
}

s EnumInitExpr {
    ident: S,
    case: S,
    value: Option<Expr>,
}

s MemberAccessExpr {
    base: Expr,
    member: S,
}

s SubscriptExpr {
    base: Expr,
    index: Expr,
}

t Expr {
    Ident(S),
    MemberAccess(Box<MemberAccessExpr>),
    Literal(LiteralExpr),
    FunctionCall(FunctionCallExpr),
    Paren(Box<Expr>),
    StructInit(StructInitExpr),
    EnumInit(Box<EnumInitExpr>),
    Subscript(Box<SubscriptExpr>),
}

// MARK: Place Expressions (assignment targets)

t PlaceExpr {
    Ident(S),
    Member(Box<MemberPlaceExpr>),
}

s MemberPlaceExpr {
    base: PlaceExpr,
    member: S,
}

// MARK: Statements

s IfBlock {
    condition: Expr,
    stmts: V<Stmt>,
}

s ElseBlock {
    stmts: V<Stmt>,
}

s IfStmt {
    if_blocks: V<IfBlock>,
    else_block: Option<ElseBlock>,
}

s MatchStmt {
    value: Expr,
    case_blocks: V<CaseBlock>,
    default_block: Option<V<Stmt>>,
}

s CaseBlock {
    pattern: MatchPattern,
    stmts: V<Stmt>,
}

s MatchPattern {
    ident: S,
    case: S,
    binding: Option<Binding>,
}

t Binding {
    Underscore,
    Ident(S),
}

s WhileStmt {
    condition: Expr,
    stmts: V<Stmt>,
}

s VarDecl {
    mutable: bool,
    ident: S,
    ty: Option<Type>,
    value: Option<Expr>,
}

s AssignmentStmt {
    place: PlaceExpr,
    value: Expr,
}

t Stmt {
    If(IfStmt),
    Match(MatchStmt),
    While(WhileStmt),
    VarDecl(VarDecl),
    Assignment(AssignmentStmt),
    Expr(Expr),
    Break,
    Continue,
    Return(Option<Expr>),
}

// MARK: Declarations

s Field {
    ident: S,
    ty: Type,
}

s Struct {
    ident: S,
    generic_parameters: V<S>,
    fields: V<Field>,
}

s Case {
    ident: S,
    ty: Option<Type>,
}

s Enum {
    ident: S,
    cases: V<Case>,
}

s Parameter {
    label: S,
    ty: ArgumentType,
}

s FunctionSignature {
    ident: S,
    generic_parameters: V<S>,
    parameters: V<Parameter>,
    ret: Option<Type>,
}

s Function {
    signature: FunctionSignature,
    stmts: V<Stmt>,
}

t Decl {
    Struct(Struct),
    Enum(Enum),
    Function(Function),
}

// MARK: AST

s Ast {
    decls: V<Decl>,
}

// MARK: Lexer

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
