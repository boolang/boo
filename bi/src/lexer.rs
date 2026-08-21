use std::range::Range;

use winnow::LocatingSlice;
use winnow::Parser;
use winnow::ascii::alpha1;
use winnow::ascii::multispace0;
use winnow::combinator::alt;
use winnow::combinator::dispatch;
use winnow::combinator::empty;
use winnow::combinator::fail;
use winnow::combinator::repeat;
use winnow::combinator::terminated;
use winnow::error::ContextError;
use winnow::error::ParseError;
use winnow::stream::AsChar;
use winnow::token::any;
use winnow::token::one_of;
use winnow::token::take_while;

#[derive(Clone, Debug)]
pub struct Token {
    kind: TokenKind,
    span: Range<usize>,
}

#[derive(Clone, Debug)]
pub enum TokenKind {
    Id(String),
    KFunction,
    KStruct,
    KType,
    OpenPar,
    ClosePar,
    OpenBracket,
    CloseBracket,
    OpenBrace,
    CloseBrace,
    Equals,
    Bang,
}

pub fn tokenise(input: &str) -> Result<Vec<Token>, ParseError<LocatingSlice<&str>, ContextError>> {
    repeat(0.., terminated(token, multispace0)).parse(LocatingSlice::new(input))
}

fn token(input: &mut LocatingSlice<&str>) -> winnow::Result<Token> {
    alt((keyword, sym)).parse_next(input)
}

fn ident<'i>(input: &mut LocatingSlice<&'i str>) -> winnow::Result<&'i str> {
    (
        one_of(|c: char| c.is_alpha() || c == '_'),
        take_while(0.., |c: char| c.is_alphanum() || c == '_'),
    )
        .take()
        .parse_next(input)
}

fn keyword(input: &mut LocatingSlice<&str>) -> winnow::Result<Token> {
    dispatch! {ident;
        "f" => empty.value(TokenKind::KFunction),
        "s" => empty.value(TokenKind::KStruct),
        "t" => empty.value(TokenKind::KType),
        id => empty.value(TokenKind::Id(id.to_owned())),
    }
    .with_span()
    .map(|(kind, span)| Token {
        kind,
        span: span.into(),
    })
    .parse_next(input)
}

fn sym(input: &mut LocatingSlice<&str>) -> winnow::Result<Token> {
    dispatch! {any;
        '(' => empty.value(TokenKind::OpenPar),
        ')' => empty.value(TokenKind::ClosePar),
        '[' => empty.value(TokenKind::OpenBracket),
        ']' => empty.value(TokenKind::CloseBracket),
        '{' => empty.value(TokenKind::OpenBrace),
        '}' => empty.value(TokenKind::CloseBrace),
        '=' => empty.value(TokenKind::Equals),
        '!' => empty.value(TokenKind::Bang),
        _ => fail,
    }
    .with_span()
    .map(|(kind, span)| Token {
        kind,
        span: span.into(),
    })
    .parse_next(input)
}
