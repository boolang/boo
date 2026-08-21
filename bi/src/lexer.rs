use std::range::Range;

use winnow::LocatingSlice;
use winnow::Parser;
use winnow::ascii::alpha1;
use winnow::ascii::digit1;
use winnow::ascii::hex_digit1;
use winnow::ascii::multispace0;
use winnow::ascii::oct_digit1;
use winnow::combinator::alt;
use winnow::combinator::dispatch;
use winnow::combinator::empty;
use winnow::combinator::fail;
use winnow::combinator::opt;
use winnow::combinator::preceded;
use winnow::combinator::repeat;
use winnow::combinator::terminated;
use winnow::error::ContextError;
use winnow::error::ParseError;
use winnow::stream::AsChar;
use winnow::token::any;
use winnow::token::one_of;
use winnow::token::take;
use winnow::token::take_while;

#[derive(Clone, Debug)]
pub struct Token {
    kind: TokenKind,
    span: Range<usize>,
}

#[derive(Clone, Debug)]
pub enum TokenKind {
    Id(String),
    Int(i128),
    KBreak,
    KContinue,
    KElse,
    KFunction,
    KIf,
    KLet,
    KMatch,
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
    Equals,
    Bang,
}

pub fn tokenise(input: &str) -> Result<Vec<Token>, ParseError<LocatingSlice<&str>, ContextError>> {
    repeat(0.., terminated(token, multispace0)).parse(LocatingSlice::new(input))
}

fn token(input: &mut LocatingSlice<&str>) -> winnow::Result<Token> {
    alt((keyword, number, sym)).parse_next(input)
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
        "b" => empty.value(TokenKind::KBreak),
        "c" => empty.value(TokenKind::KContinue),
        "e" => empty.value(TokenKind::KElse),
        "f" => empty.value(TokenKind::KFunction),
        "i" => empty.value(TokenKind::KIf),
        "l" => empty.value(TokenKind::KLet),
        "m" => empty.value(TokenKind::KMatch),
        "s" => empty.value(TokenKind::KStruct),
        "t" => empty.value(TokenKind::KType),
        "v" => empty.value(TokenKind::KVar),
        "w" => empty.value(TokenKind::KWhile),
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

fn number(input: &mut LocatingSlice<&str>) -> winnow::Result<Token> {
    let sign = opt(one_of(('-', '+'))).parse_next(input)?;

    alt((prefixed_integer, dec_integer))
        .with_span()
        .map(|(i, span)| Token {
            kind: TokenKind::Int(if sign == Some('-') { -i } else { i }),
            span: span.into(),
        })
        .parse_next(input)
}

fn prefixed_integer(input: &mut LocatingSlice<&str>) -> winnow::Result<i128> {
    dispatch!(take(2usize);
        "0b" => take_while(1.., '0'..='1').try_map(|s| i128::from_str_radix(s, 2)),
        "0o" => oct_digit1.try_map(|s| i128::from_str_radix(s, 8)),
        "0x" => hex_digit1.try_map(|s| i128::from_str_radix(s, 16)),
        _ => fail,
    )
    .parse_next(input)
}

fn dec_integer(input: &mut LocatingSlice<&str>) -> winnow::Result<i128> {
    digit1.parse_to::<i128>().parse_next(input)
}
