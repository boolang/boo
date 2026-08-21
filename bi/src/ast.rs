use std::range::Range;

pub type Span = Range<usize>;

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct Rich<T> {
    value: T,
    span: Span,
}

pub type Ident = Rich<String>;

// MARK: Literals

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub enum LiteralExpr {
    Int(IntLiteral),
    Bool(BoolLiteral),
    String(StringLiteral),
}

pub type IntLiteral = Rich<i128>;

pub type BoolLiteral = Rich<bool>;

pub type StringLiteral = Rich<String>;

// MARK: Types

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct SimpleType {
    ident: Ident,
    generic_parameters: Vec<Type>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub enum Type {
    // NOTE: May add more cases for types with explicit modules
    Simple(SimpleType),
}

// MARK: Expressions

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct FunctionCallExpr {
    ident: Ident,
    arguments: Vec<Expr>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub enum Expr {
    Ident(Ident),
    Literal(LiteralExpr),
    FunctionCall(FunctionCallExpr),
    Paren(Box<Rich<Expr>>),
}

// MARK: Statements

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct IfBlock {
    condition: Expr,
    stmts: Vec<Stmt>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct ElseBlock {
    stmts: Vec<Stmt>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct IfStmt {
    if_blocks: Vec<IfBlock>,
    else_block: ElseBlock,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct WhileStmt {
    condition: Expr,
    stmts: Vec<Stmt>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct VarDecl {
    mutable: bool,
    ident: Ident,
    ty: Option<Type>,
    value: Option<Expr>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct AssignmentStmt {
    ident: Ident,
    value: Expr,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub enum Stmt {
    If(IfStmt),
    While(WhileStmt),
    VarDecl(VarDecl),
    Assignment(AssignmentStmt),
}

// MARK: Declarations

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct Field {
    ident: Ident,
    ty: Type,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct Struct {
    ident: Ident,
    fields: Vec<Field>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct Case {
    ident: Ident,
    ty: Option<Type>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct Enum {
    ident: Ident,
    cases: Vec<Case>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct Parameter {
    label: Ident,
    ty: Type,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct FunctionSignature {
    ident: Ident,
    parameters: Vec<Parameter>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct Function {
    signature: FunctionSignature,
    stmts: Vec<Stmt>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub enum Decl {
    Struct(Struct),
    Enum(Enum),
    Function(Function),
}

// MARK: AST

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct Ast {
    decls: Vec<Decl>,
}
