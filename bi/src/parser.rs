use winnow::Parser;
use winnow::combinator::{alt, empty, repeat, separated, seq};
use winnow::error::{ContextError, ParseError};
use winnow::stream::TokenSlice;
use winnow::token::literal;

use crate::ast::{Ast, Case, Decl, Enum, Field, Rich, SimpleType, Struct, Type};
use crate::lexer::{Token, TokenKind};

pub fn parse(input: &[Token]) -> Result<Ast, ParseError<TokenSlice<'_, Token>, ContextError>> {
    Ok(Ast {
        decls: repeat(0.., decl).parse(TokenSlice::new(input))?,
    })
}

fn decl(input: &mut TokenSlice<Token>) -> winnow::Result<Decl> {
    alt((r#struct.map(Decl::Struct), r#enum.map(Decl::Enum))).parse_next(input)
}

fn r#struct(input: &mut TokenSlice<Token>) -> winnow::Result<Struct> {
    seq!(
        _: literal(TokenKind::KStruct),
        literal(TokenKind::Id),
        _: literal(TokenKind::OpenBrace),
        field_list,
        _: literal(TokenKind::CloseBrace),
    )
    .map(|(name, fields): (&[Token], _)| Struct {
        ident: rich(name),
        fields,
    })
    .parse_next(input)
}

fn field_list(input: &mut TokenSlice<Token>) -> winnow::Result<Vec<Field>> {
    separated(0.., field, literal(TokenKind::Comma)).parse_next(input)
}

fn field(input: &mut TokenSlice<Token>) -> winnow::Result<Field> {
    seq!(literal(TokenKind::Id), _: literal(TokenKind::Colon), r#type)
        .map(|(name, ty)| Field {
            ident: rich(name),
            ty,
        })
        .parse_next(input)
}

fn r#enum(input: &mut TokenSlice<Token>) -> winnow::Result<Enum> {
    seq!(
        _: literal(TokenKind::KType),
        literal(TokenKind::Id),
        _: literal(TokenKind::OpenBrace),
        case_list,
        _: literal(TokenKind::CloseBrace),
    )
    .map(|(name, cases): (&[Token], _)| Enum {
        ident: rich(name),
        cases,
    })
    .parse_next(input)
}

fn case_list(input: &mut TokenSlice<Token>) -> winnow::Result<Vec<Case>> {
    todo!()
}

fn r#type(input: &mut TokenSlice<Token>) -> winnow::Result<Type> {
    literal(TokenKind::Id)
        .map(|name: &[Token]| {
            Type::Simple(SimpleType {
                ident: rich(name),
                generic_parameters: vec![],
            })
        })
        .parse_next(input)
}

fn rich(name: &[Token]) -> Rich<String> {
    Rich {
        value: name[0].value.clone(),
        span: name[0].span,
    }
}
