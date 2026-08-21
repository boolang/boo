use winnow::Parser;
use winnow::combinator::{alt, delimited, opt, preceded, repeat, separated, seq, terminated};
use winnow::error::{ContextError, ParseError};
use winnow::stream::TokenSlice;
use winnow::token::{literal, one_of};

use crate::ast::{
    AssignmentStmt, Ast, Case, Decl, ElseBlock, Enum, Expr, Field, Function, FunctionCallExpr,
    FunctionSignature, IfBlock, IfStmt, LiteralExpr, Parameter, PlaceExpr, Rich, SimpleType, Stmt,
    Struct, Type, VarDecl, WhileStmt,
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
    // TODO
    alt((
        r#if.map(Stmt::If),
        r#while.map(Stmt::While),
        var_decl.map(Stmt::VarDecl),
        assignment.map(Stmt::Assignment),
        expr_stmt.map(Stmt::Expr),
        r#break.map(|_| Stmt::Break),
        r#continue.map(|_| Stmt::Continue),
        r#return.map(Stmt::Return),
    ))
    .parse_next(input)
}

fn r#if(input: &mut TokenSlice<Token>) -> winnow::Result<IfStmt> {
    seq!(
        _: literal(TokenKind::KIf),
        separated(
            1..,
            (delimited(literal(TokenKind::OpenPar), expr, literal(TokenKind::ClosePar)), block)
                .map(|(condition, stmts)| IfBlock { condition, stmts }),
            (literal(TokenKind::KElse), literal(TokenKind::KIf)),
        ),
        opt(preceded(
            literal(TokenKind::KElse),
            block.map(|stmts| ElseBlock { stmts })
        ))
    )
    .map(|(if_blocks, else_block)| IfStmt {
        if_blocks,
        else_block,
    })
    .parse_next(input)
}

fn r#while(input: &mut TokenSlice<Token>) -> winnow::Result<WhileStmt> {
    preceded(
        literal(TokenKind::KWhile),
        (
            delimited(
                literal(TokenKind::OpenPar),
                expr,
                literal(TokenKind::ClosePar),
            ),
            block,
        ),
    )
    .map(|(condition, stmts)| WhileStmt { condition, stmts })
    .parse_next(input)
}

fn var_decl(input: &mut TokenSlice<Token>) -> winnow::Result<VarDecl> {
    seq!(
        one_of(|t: &Token| *t == TokenKind::KLet || *t == TokenKind::KVar),
        ident,
        opt(preceded(literal(TokenKind::Colon), r#type)),
        opt(preceded(literal(TokenKind::Equals), expr)),
        _: literal(TokenKind::Semicolon),
    )
    .map(|(mutable, ident, ty, value)| VarDecl {
        mutable: *mutable == TokenKind::KVar,
        ident,
        ty,
        value,
    })
    .parse_next(input)
}

fn assignment(input: &mut TokenSlice<Token>) -> winnow::Result<AssignmentStmt> {
    seq!(
        place_expr,
        _: literal(TokenKind::Equals),
        expr,
    )
    .map(|(place, value)| AssignmentStmt { place, value })
    .parse_next(input)
}

fn expr_stmt(input: &mut TokenSlice<Token>) -> winnow::Result<Expr> {
    terminated(expr, literal(TokenKind::Semicolon)).parse_next(input)
}

fn r#break(input: &mut TokenSlice<Token>) -> winnow::Result<()> {
    terminated(literal(TokenKind::KBreak), literal(TokenKind::Semicolon))
        .map(|_| ())
        .parse_next(input)
}

fn r#continue(input: &mut TokenSlice<Token>) -> winnow::Result<()> {
    terminated(literal(TokenKind::KContinue), literal(TokenKind::Semicolon))
        .map(|_| ())
        .parse_next(input)
}

fn r#return(input: &mut TokenSlice<Token>) -> winnow::Result<Option<Expr>> {
    delimited(
        literal(TokenKind::KReturn),
        opt(expr),
        literal(TokenKind::Semicolon),
    )
    .parse_next(input)
}

fn expr(input: &mut TokenSlice<Token>) -> winnow::Result<Expr> {
    // TODO
    alt((
        e_ident.map(Expr::Literal),
        function_call.map(Expr::FunctionCall),
    ))
    .parse_next(input)
}

fn place_expr(input: &mut TokenSlice<Token>) -> winnow::Result<PlaceExpr> {
    // TODO
    alt((ident.map(PlaceExpr::Ident),)).parse_next(input)
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
