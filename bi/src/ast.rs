use std::{fmt::Display, range::Range};

pub type Span = Range<usize>;

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct Rich<T> {
    pub value: T,
    pub span: Span,
}

impl<T> Rich<T> {
    pub fn new(value: T, span: Span) -> Self {
        Self { value, span }
    }
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
    pub ident: Ident,
    pub generic_parameters: Vec<Type>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub enum Type {
    // NOTE: May add more cases for types with explicit modules
    Simple(SimpleType),
}

impl Type {
    pub fn is_equiv(&self, other: &Type) -> bool {
        match (self, other) {
            (Type::Simple(a), Type::Simple(b)) => {
                a.ident.value == b.ident.value
                    && a.generic_parameters
                        .iter()
                        .zip(b.generic_parameters.iter())
                        .all(|(a, b)| a.is_equiv(b))
            }
        }
    }
}

impl Display for Type {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Type::Simple(ty) => f.write_str(&ty.ident.value.to_string()),
        }
    }
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct ArgumentType {
    pub ty: Type,
    pub mutable: bool,
}

impl ArgumentType {
    pub fn ty(&self) -> Type {
        self.ty.clone()
    }
}

impl Display for ArgumentType {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        if self.mutable {
            f.write_str("&")?;
        }
        self.ty.fmt(f)
    }
}

// MARK: Expressions

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub enum ArgumentValue {
    Immutable(Expr),
    Mutable(PlaceExpr),
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct FunctionCallExpr {
    pub ident: Ident,
    pub arguments: Vec<ArgumentValue>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct StructInitExpr {
    pub ident: Ident,
    pub arguments: Vec<StructInitArgument>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct StructInitArgument {
    pub label: Ident,
    pub value: Expr,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct MemberAccessExpr {
    pub base: Expr,
    pub member: Ident,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct SubscriptExpr {
    pub base: Expr,
    pub index: Expr,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub enum Expr {
    Ident(Ident),
    MemberAccess(Box<MemberAccessExpr>),
    Literal(LiteralExpr),
    FunctionCall(FunctionCallExpr),
    Paren(Box<Rich<Expr>>),
    StructInit(StructInitExpr),
    Subscript(Box<SubscriptExpr>),
}

// MARK: Place Expressions (assignment targets)

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub enum PlaceExpr {
    Ident(Ident),
    Member(Box<MemberPlaceExpr>),
}

impl Display for PlaceExpr {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::Ident(ident) => f.write_str(&ident.value),
            Self::Member(member) => {
                f.write_str(&format!("{}.{}", member.base, member.member.value))
            }
        }
    }
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct MemberPlaceExpr {
    pub base: PlaceExpr,
    pub member: Ident,
}

// MARK: Statements

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct IfBlock {
    pub condition: Expr,
    pub stmts: Vec<Stmt>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct ElseBlock {
    pub stmts: Vec<Stmt>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct IfStmt {
    pub if_blocks: Vec<IfBlock>,
    pub else_block: Option<ElseBlock>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct WhileStmt {
    pub condition: Expr,
    pub stmts: Vec<Stmt>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct VarDecl {
    pub mutable: bool,
    pub ident: Ident,
    pub ty: Option<Type>,
    pub value: Option<Expr>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct AssignmentStmt {
    pub place: PlaceExpr,
    pub value: Expr,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub enum Stmt {
    If(IfStmt),
    While(WhileStmt),
    VarDecl(VarDecl),
    Assignment(AssignmentStmt),
    Expr(Expr),
    Break,
    Continue,
    Return(Option<Expr>),
}

// MARK: Declarations

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct Field {
    pub ident: Ident,
    pub ty: Type,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct Struct {
    pub ident: Ident,
    pub fields: Vec<Field>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct Case {
    pub ident: Ident,
    pub ty: Option<Type>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct Enum {
    pub ident: Ident,
    pub cases: Vec<Case>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct Parameter {
    pub label: Ident,
    pub ty: ArgumentType,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct FunctionSignature {
    pub ident: Ident,
    pub parameters: Vec<Parameter>,
    pub ret: Option<Type>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct Function {
    pub signature: FunctionSignature,
    pub stmts: Vec<Stmt>,
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
    pub decls: Vec<Decl>,
}
