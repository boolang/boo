use winnow::Parser;
use winnow::combinator::{alt, delimited, opt, preceded, repeat, separated, seq, terminated};
use winnow::error::{ContextError, ParseError};
use winnow::stream::TokenSlice;
use winnow::token::literal;

use crate::ast::{
    Ast, Case, Decl, Enum, Expr, Field, Function, FunctionCallExpr, FunctionSignature, LiteralExpr,
    Parameter, Rich, SimpleType, Stmt, Struct, Type,
};
use crate::lexer::{Token, TokenKind};

pub fn parse(input: &[Token]) -> Result<Ast, ParseError<TokenSlice<'_, Token>, ContextError>> {
    Ok(Ast {
        decls: repeat(0.., decl).parse(TokenSlice::new(input))?,
    })
}

fn decl(input: &mut TokenSlice<Token>) -> winnow::Result<Decl> {
    alt((
        r#struct.map(Decl::Struct),
        r#enum.map(Decl::Enum),
        function.map(Decl::Function),
    ))
    .parse_next(input)
}

fn r#struct(input: &mut TokenSlice<Token>) -> winnow::Result<Struct> {
    seq!(
        _: literal(TokenKind::KStruct),
        ident,
        _: literal(TokenKind::OpenBrace),
        field_list,
        _: literal(TokenKind::CloseBrace),
    )
    .map(|(ident, fields)| Struct { ident, fields })
    .parse_next(input)
}

fn field_list(input: &mut TokenSlice<Token>) -> winnow::Result<Vec<Field>> {
    separated(0.., field, literal(TokenKind::Comma)).parse_next(input)
}

fn field(input: &mut TokenSlice<Token>) -> winnow::Result<Field> {
    seq!(ident, _: literal(TokenKind::Colon), r#type)
        .map(|(ident, ty)| Field { ident, ty })
        .parse_next(input)
}

fn r#enum(input: &mut TokenSlice<Token>) -> winnow::Result<Enum> {
    seq!(
        _: literal(TokenKind::KType),
        ident,
        _: literal(TokenKind::OpenBrace),
        case_list,
        _: literal(TokenKind::CloseBrace),
    )
    .map(|(ident, cases)| Enum { ident, cases })
    .parse_next(input)
}

fn case_list(input: &mut TokenSlice<Token>) -> winnow::Result<Vec<Case>> {
    separated(0.., case, literal(TokenKind::Comma)).parse_next(input)
}

fn case(input: &mut TokenSlice<Token>) -> winnow::Result<Case> {
    alt((
        seq!(
            ident,
            _: literal(TokenKind::OpenPar),
            r#type,
            _: literal(TokenKind::ClosePar)
        )
        .map(|(ident, ty)| Case {
            ident,
            ty: Some(ty),
        }),
        ident.map(|ident| Case { ident, ty: None }),
    ))
    .parse_next(input)
}

fn function(input: &mut TokenSlice<Token>) -> winnow::Result<Function> {
    seq!(
        _: literal(TokenKind::KFunction),
        ident,
        _: literal(TokenKind::OpenPar),
        arguments,
        _: literal(TokenKind::ClosePar),
        opt(preceded(literal(TokenKind::Arrow), r#type)),
        block,
    )
    .map(|(ident, parameters, ret, stmts)| Function {
        signature: FunctionSignature {
            ident,
            parameters,
            ret,
        },
        stmts,
    })
    .parse_next(input)
}

fn arguments(input: &mut TokenSlice<Token>) -> winnow::Result<Vec<Parameter>> {
    separated(0.., argument, literal(TokenKind::Comma)).parse_next(input)
}

fn argument(input: &mut TokenSlice<Token>) -> winnow::Result<Parameter> {
    seq!(ident, _: literal(TokenKind::Colon), r#type)
        .map(|(label, ty)| Parameter { label, ty })
        .parse_next(input)
}

fn block(input: &mut TokenSlice<Token>) -> winnow::Result<Vec<Stmt>> {
    delimited(
        literal(TokenKind::OpenBrace),
        repeat(0.., stmt),
        literal(TokenKind::CloseBrace),
    )
    .parse_next(input)
}

fn stmt(input: &mut TokenSlice<Token>) -> winnow::Result<Stmt> {
    alt((r#return.map(Stmt::Return), expr_stmt.map(Stmt::Expr))).parse_next(input)
}

fn r#return(input: &mut TokenSlice<Token>) -> winnow::Result<Option<Expr>> {
    delimited(
        literal(TokenKind::KReturn),
        opt(expr),
        literal(TokenKind::Semicolon),
    )
    .parse_next(input)
}

fn expr_stmt(input: &mut TokenSlice<Token>) -> winnow::Result<Expr> {
    terminated(expr, literal(TokenKind::Semicolon)).parse_next(input)
}

fn expr(input: &mut TokenSlice<Token>) -> winnow::Result<Expr> {
    alt((
        e_ident.map(Expr::Literal),
        function_call.map(Expr::FunctionCall),
    ))
    .parse_next(input)
}

fn e_ident(input: &mut TokenSlice<Token>) -> winnow::Result<LiteralExpr> {
    string_lit.map(LiteralExpr::String).parse_next(input)
}

fn function_call(input: &mut TokenSlice<Token>) -> winnow::Result<FunctionCallExpr> {
    seq!(
        ident,
        _: literal(TokenKind::OpenPar),
        separated(0.., expr, literal(TokenKind::Comma)),
        _: literal(TokenKind::ClosePar),
    )
    .map(|(ident, arguments)| FunctionCallExpr { ident, arguments })
    .parse_next(input)
}

fn r#type(input: &mut TokenSlice<Token>) -> winnow::Result<Type> {
    ident
        .map(|ident| {
            Type::Simple(SimpleType {
                ident,
                generic_parameters: vec![],
            })
        })
        .parse_next(input)
}

fn ident(input: &mut TokenSlice<Token>) -> winnow::Result<Rich<String>> {
    literal(TokenKind::Id)
        .map(|name: &[Token]| Rich {
            value: name[0].value.clone(),
            span: name[0].span,
        })
        .parse_next(input)
}

fn string_lit(input: &mut TokenSlice<Token>) -> winnow::Result<Rich<String>> {
    literal(TokenKind::String)
        .map(|name: &[Token]| Rich {
            value: name[0].value.clone(),
            span: name[0].span,
        })
        .parse_next(input)
}
