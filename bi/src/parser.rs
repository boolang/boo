use winnow::Parser;
use winnow::combinator::{alt, empty, repeat, seq};
use winnow::error::{ContextError, ParseError};
use winnow::stream::TokenSlice;
use winnow::token::literal;

use crate::ast::{Ast, Decl, Field, Struct};
use crate::lexer::{Token, TokenKind};

pub fn parse(input: &[Token]) -> Result<Ast, ParseError<TokenSlice<'_, Token>, ContextError>> {
    Ok(Ast {
        decls: repeat(0.., decl).parse(TokenSlice::new(input))?,
    })
}

fn decl(input: &mut TokenSlice<Token>) -> winnow::Result<Decl> {
    alt((r#struct.map(Decl::Struct),)).parse_next(input)
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
        ident: crate::ast::Rich {
            value: name[0].value.clone(),
            span: name[0].span,
        },
        fields,
    })
    .parse_next(input)
}

fn field_list(input: &mut TokenSlice<Token>) -> winnow::Result<Vec<Field>> {
    empty.map(|()| vec![]).parse_next(input)
}
