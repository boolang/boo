use winnow::LocatingSlice;
use winnow::Parser;
use winnow::ascii::digit1;
use winnow::ascii::escaped;
use winnow::ascii::hex_digit1;
use winnow::ascii::multispace1;
use winnow::ascii::oct_digit1;
use winnow::ascii::till_line_ending;
use winnow::combinator::alt;
use winnow::combinator::cut_err;
use winnow::combinator::delimited;
use winnow::combinator::dispatch;
use winnow::combinator::empty;
use winnow::combinator::eof;
use winnow::combinator::fail;
use winnow::combinator::opt;
use winnow::combinator::preceded;
use winnow::combinator::repeat;
use winnow::combinator::repeat_till;
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

use crate::ast::Span;

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct Token {
    pub kind: TokenKind,
    pub value: String,
    pub span: Span,
}

impl PartialEq<TokenKind> for Token {
    fn eq(&self, other: &TokenKind) -> bool {
        self.kind == *other
    }
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub enum TokenKind {
    Id,
    Int,
    Char,
    String,
    KTrue,
    KFalse,
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
    Underscore,
    Equals,
    Bang,
    Less,
    Greater,
    Ampersand,
}

pub fn tokenise(input: &str) -> Result<Vec<Token>, ParseError<LocatingSlice<&str>, ContextError>> {
    preceded(
        anyspace,
        repeat_till(0.., terminated(token, anyspace), eof).map(|(tokens, _)| tokens),
    )
    .parse(LocatingSlice::new(input))
}

fn anyspace(input: &mut LocatingSlice<&str>) -> winnow::ModalResult<()> {
    repeat(
        0..,
        alt((multispace1.void(), seq!("//", till_line_ending).void())),
    )
    .parse_next(input)
}

fn token(input: &mut LocatingSlice<&str>) -> winnow::ModalResult<Token> {
    cut_err(alt((keyword, number, string, chr, sym))).parse_next(input)
}

fn ident<'i>(input: &mut LocatingSlice<&'i str>) -> winnow::ModalResult<&'i str> {
    (
        one_of(|c: char| c.is_alpha() || c == '_'),
        take_while(0.., |c: char| c.is_alphanum() || c == '_'),
    )
        .take()
        .parse_next(input)
}

fn keyword(input: &mut LocatingSlice<&str>) -> winnow::ModalResult<Token> {
    dispatch! {ident;
        "b" => empty.value(TokenKind::KBreak),
        "c" => empty.value(TokenKind::KContinue),
        "e" => empty.value(TokenKind::KElse),
        "f" => empty.value(TokenKind::KFunction),
        "i" => empty.value(TokenKind::KIf),
        "l" => empty.value(TokenKind::KLet),
        "m" => empty.value(TokenKind::KMatch),
        "n" => empty.value(TokenKind::KFalse),
        "r" => empty.value(TokenKind::KReturn),
        "s" => empty.value(TokenKind::KStruct),
        "t" => empty.value(TokenKind::KType),
        "v" => empty.value(TokenKind::KVar),
        "w" => empty.value(TokenKind::KWhile),
        "y" => empty.value(TokenKind::KTrue),
        _ => empty.value(TokenKind::Id),
    }
    .with_taken()
    .with_span()
    .map(|((kind, value), span)| Token {
        kind,
        value: value.to_owned(),
        span: span.into(),
    })
    .parse_next(input)
}

fn sym(input: &mut LocatingSlice<&str>) -> winnow::ModalResult<Token> {
    alt((
        dispatch! {take(2usize);
            "->" => empty.value(TokenKind::Arrow),
            "=>" => empty.value(TokenKind::DoubleArrow),
            "::" => empty.value(TokenKind::DoubleColon),
            _ => fail,
        },
        dispatch! {any;
            '(' => empty.value(TokenKind::OpenPar),
            ')' => empty.value(TokenKind::ClosePar),
            '[' => empty.value(TokenKind::OpenBracket),
            ']' => empty.value(TokenKind::CloseBracket),
            '{' => empty.value(TokenKind::OpenBrace),
            '}' => empty.value(TokenKind::CloseBrace),
            '=' => empty.value(TokenKind::Equals),
            '!' => empty.value(TokenKind::Bang),
            ':' => empty.value(TokenKind::Colon),
            ';' => empty.value(TokenKind::Semicolon),
            ',' => empty.value(TokenKind::Comma),
            '<' => empty.value(TokenKind::Less),
            '>' => empty.value(TokenKind::Greater),
            '&' => empty.value(TokenKind::Ampersand),
            '.' => empty.value(TokenKind::Dot),
            '_' => empty.value(TokenKind::Underscore),
            _ => fail,
        },
        cut_err(fail.context(winnow::error::StrContext::Label("unexpected character"))),
    ))
    .with_span()
    .map(|(kind, span)| Token {
        kind,
        value: String::new(),
        span: span.into(),
    })
    .parse_next(input)
}

fn number(input: &mut LocatingSlice<&str>) -> winnow::ModalResult<Token> {
    let sign = opt(one_of(('-', '+'))).parse_next(input)?;

    alt((prefixed_integer, dec_integer))
        .with_span()
        .map(|(i, span)| Token {
            kind: TokenKind::Int,
            value: {
                let mut s = if sign == Some('-') {
                    "-".to_owned()
                } else {
                    String::new()
                };
                s.push_str(&i.to_string());
                s
            },
            span: span.into(),
        })
        .parse_next(input)
}

fn prefixed_integer(input: &mut LocatingSlice<&str>) -> winnow::ModalResult<i128> {
    trace(
        "prefixed_integer",
        dispatch!(take(2usize);
            "0b" => cut_err(take_while(1.., '0'..='1').try_map(|s| i128::from_str_radix(s, 2))),
            "0o" => cut_err(oct_digit1.try_map(|s| i128::from_str_radix(s, 8))),
            "0x" => cut_err(hex_digit1.try_map(|s| i128::from_str_radix(s, 16))),
            _ => fail,
        ),
    )
    .parse_next(input)
}

fn dec_integer(input: &mut LocatingSlice<&str>) -> winnow::ModalResult<i128> {
    trace("dec_integer", digit1.parse_to::<i128>()).parse_next(input)
}

fn string(input: &mut LocatingSlice<&str>) -> winnow::ModalResult<Token> {
    trace(
        "string_literal",
        delimited(
            '"',
            cut_err(escaped(
                none_of(('\\', '"', '\u{80}'..)),
                '\\',
                alt((
                    "\\".value("\\"),
                    "\"".value("\""),
                    "n".value("\n"),
                    "t".value("\t"),
                    "r".value("\r"),
                )),
            )),
            '"',
        ),
    )
    .with_span()
    .map(|(s, span): (String, _)| Token {
        kind: TokenKind::String,
        value: s,
        span: span.into(),
    })
    .parse_next(input)
}

fn chr(input: &mut LocatingSlice<&str>) -> winnow::ModalResult<Token> {
    trace(
        "char_literal",
        delimited(
            '\'',
            dispatch! {any;
                '\\' => dispatch! {any;
                    '\'' => empty.value('\"'),
                    'n' => empty.value('\n'),
                    't' => empty.value('\t'),
                    'r' => empty.value('\r'),
                    c => empty.value(c),
                },
                c => empty.value(c),
            },
            '\'',
        ),
    )
    .with_span()
    .map(|(c, span)| Token {
        kind: TokenKind::Char,
        value: c.to_string(),
        span: span.into(),
    })
    .parse_next(input)
}
