use winnow::LocatingSlice;
use winnow::Parser;
use winnow::ascii::digit1;
use winnow::ascii::escaped;
use winnow::ascii::hex_digit1;
use winnow::ascii::multispace1;
use winnow::ascii::oct_digit1;
use winnow::ascii::till_line_ending;
use winnow::combinator::alt;
use winnow::combinator::delimited;
use winnow::combinator::dispatch;
use winnow::combinator::empty;
use winnow::combinator::fail;
use winnow::combinator::opt;
use winnow::combinator::repeat;
use winnow::combinator::seq;
use winnow::combinator::terminated;
use winnow::combinator::trace;
use winnow::error::ContextError;
use winnow::error::ParseError;
use winnow::stream::AsChar;
use winnow::token::any;
use winnow::token::none_of;
use winnow::token::one_of;
use winnow::token::take;
use winnow::token::take_while;

use crate::ast::Rich;

pub type Token = Rich<TokenKind>;

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub enum TokenKind {
    Id(String),
    Int(i128),
    Char(char),
    String(String),
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
    repeat(0.., terminated(token, anyspace)).parse(LocatingSlice::new(input))
}

fn anyspace(input: &mut LocatingSlice<&str>) -> winnow::Result<()> {
    repeat(
        0..,
        alt((multispace1.void(), seq!("//", till_line_ending).void())),
    )
    .parse_next(input)
}

fn token(input: &mut LocatingSlice<&str>) -> winnow::Result<Token> {
    alt((keyword, number, string, chr, sym)).parse_next(input)
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
    .map(|(value, span)| Token {
        value,
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
    .map(|(value, span)| Token {
        value,
        span: span.into(),
    })
    .parse_next(input)
}

fn number(input: &mut LocatingSlice<&str>) -> winnow::Result<Token> {
    let sign = opt(one_of(('-', '+'))).parse_next(input)?;

    alt((prefixed_integer, dec_integer))
        .with_span()
        .map(|(i, span)| Token {
            value: TokenKind::Int(if sign == Some('-') { -i } else { i }),
            span: span.into(),
        })
        .parse_next(input)
}

fn prefixed_integer(input: &mut LocatingSlice<&str>) -> winnow::Result<i128> {
    trace(
        "prefixed_integer",
        dispatch!(take(2usize);
            "0b" => take_while(1.., '0'..='1').try_map(|s| i128::from_str_radix(s, 2)),
            "0o" => oct_digit1.try_map(|s| i128::from_str_radix(s, 8)),
            "0x" => hex_digit1.try_map(|s| i128::from_str_radix(s, 16)),
            _ => fail,
        ),
    )
    .parse_next(input)
}

fn dec_integer(input: &mut LocatingSlice<&str>) -> winnow::Result<i128> {
    trace("dec_integer", digit1.parse_to::<i128>()).parse_next(input)
}

fn string(input: &mut LocatingSlice<&str>) -> winnow::Result<Token> {
    trace(
        "string_literal",
        delimited(
            '"',
            escaped(
                none_of(('\\', '"', '\u{80}'..)),
                '\\',
                alt(("\\".value("\\"), "\"".value("\""), "n".value("\n"))),
            ),
            '"',
        ),
    )
    .with_span()
    .map(|(s, span): (String, _)| Token {
        value: TokenKind::String(s),
        span: span.into(),
    })
    .parse_next(input)
}

fn chr(input: &mut LocatingSlice<&str>) -> winnow::Result<Token> {
    trace(
        "char_literal",
        delimited(
            '\'',
            dispatch! {any;
                '\\' => any,
                c => empty.value(c),
            },
            '\'',
        ),
    )
    .with_span()
    .map(|(c, span)| Token {
        value: TokenKind::Char(c),
        span: span.into(),
    })
    .parse_next(input)
}
