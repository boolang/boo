use winnow::Parser;
use winnow::combinator::{
    Postfix, alt, cut_err, delimited, expression, opt, preceded, repeat, separated, seq,
    terminated, trace,
};
use winnow::error::{ContextError, ParseError};
use winnow::stream::TokenSlice;
use winnow::token::{literal, one_of};

use crate::ast::{
    ArgumentType, ArgumentValue, AssignmentStmt, Ast, Case, Decl, ElseBlock, Enum, Expr, Field,
    Function, FunctionCallExpr, FunctionSignature, IfBlock, IfStmt, LiteralExpr, MemberAccessExpr,
    Parameter, PlaceExpr, Rich, SimpleType, Stmt, Struct, StructInitArgument, StructInitExpr,
    SubscriptExpr, Type, VarDecl, WhileStmt,
};
use crate::lexer::{Token, TokenKind};

pub fn parse(input: &[Token]) -> Result<Ast, ParseError<TokenSlice<'_, Token>, ContextError>> {
    Ok(Ast {
        decls: repeat(0.., decl).parse(TokenSlice::new(input))?,
    })
}

fn decl(input: &mut TokenSlice<Token>) -> winnow::ModalResult<Decl> {
    alt((
        r#struct.map(Decl::Struct),
        r#enum.map(Decl::Enum),
        function.map(Decl::Function),
    ))
    .parse_next(input)
}

fn r#struct(input: &mut TokenSlice<Token>) -> winnow::ModalResult<Struct> {
    preceded(
        literal(TokenKind::KStruct),
        cut_err(seq!(
            ident,
            _: literal(TokenKind::OpenBrace),
            field_list,
            _: literal(TokenKind::CloseBrace),
        )),
    )
    .map(|(ident, fields)| Struct { ident, fields })
    .parse_next(input)
}

fn field_list(input: &mut TokenSlice<Token>) -> winnow::ModalResult<Vec<Field>> {
    terminated(
        separated(0.., field, literal(TokenKind::Comma)),
        opt(literal(TokenKind::Comma)),
    )
    .parse_next(input)
}

fn field(input: &mut TokenSlice<Token>) -> winnow::ModalResult<Field> {
    seq!(ident, _: literal(TokenKind::Colon), r#type)
        .map(|(ident, ty)| Field { ident, ty })
        .parse_next(input)
}

fn r#enum(input: &mut TokenSlice<Token>) -> winnow::ModalResult<Enum> {
    preceded(
        literal(TokenKind::KType),
        cut_err(seq!(
            ident,
            _: literal(TokenKind::OpenBrace),
            cut_err(case_list),
            _: literal(TokenKind::CloseBrace),
        )),
    )
    .map(|(ident, cases)| Enum { ident, cases })
    .parse_next(input)
}

fn case_list(input: &mut TokenSlice<Token>) -> winnow::ModalResult<Vec<Case>> {
    terminated(
        separated(0.., case, literal(TokenKind::Comma)),
        opt(literal(TokenKind::Comma)),
    )
    .parse_next(input)
}

fn case(input: &mut TokenSlice<Token>) -> winnow::ModalResult<Case> {
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

fn function(input: &mut TokenSlice<Token>) -> winnow::ModalResult<Function> {
    preceded(
        literal(TokenKind::KFunction),
        cut_err(seq!(
            ident,
            _: literal(TokenKind::OpenPar),
            arguments,
            _: literal(TokenKind::ClosePar),
            opt(preceded(literal(TokenKind::Arrow), cut_err(r#type))),
            block,
        )),
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

fn arguments(input: &mut TokenSlice<Token>) -> winnow::ModalResult<Vec<Parameter>> {
    separated(0.., argument, literal(TokenKind::Comma)).parse_next(input)
}

fn argument(input: &mut TokenSlice<Token>) -> winnow::ModalResult<Parameter> {
    seq!(ident, _: literal(TokenKind::Colon), r#type)
        .map(|(label, ty)| Parameter {
            label,
            ty: ArgumentType { ty, mutable: false },
        })
        .parse_next(input)
}

fn block(input: &mut TokenSlice<Token>) -> winnow::ModalResult<Vec<Stmt>> {
    delimited(
        literal(TokenKind::OpenBrace),
        cut_err(repeat(0.., stmt)),
        literal(TokenKind::CloseBrace),
    )
    .parse_next(input)
}

fn stmt(input: &mut TokenSlice<Token>) -> winnow::ModalResult<Stmt> {
    // TODO
    trace(
        "stmt",
        alt((
            r#if.map(Stmt::If),
            r#while.map(Stmt::While),
            var_decl.map(Stmt::VarDecl),
            assignment.map(Stmt::Assignment),
            expr_stmt.map(Stmt::Expr),
            r#break.map(|_| Stmt::Break),
            r#continue.map(|_| Stmt::Continue),
            r#return.map(Stmt::Return),
        )),
    )
    .parse_next(input)
}

fn r#if(input: &mut TokenSlice<Token>) -> winnow::ModalResult<IfStmt> {
    preceded(
        literal(TokenKind::KIf),
        cut_err(seq!(
            separated(
                1..,
                (
                    delimited(
                        literal(TokenKind::OpenPar),
                        expr,
                        literal(TokenKind::ClosePar)
                    ),
                    block
                )
                    .map(|(condition, stmts)| IfBlock { condition, stmts }),
                (literal(TokenKind::KElse), literal(TokenKind::KIf)),
            ),
            opt(preceded(
                literal(TokenKind::KElse),
                block.map(|stmts| ElseBlock { stmts })
            ))
        )),
    )
    .map(|(if_blocks, else_block)| IfStmt {
        if_blocks,
        else_block,
    })
    .parse_next(input)
}

fn r#while(input: &mut TokenSlice<Token>) -> winnow::ModalResult<WhileStmt> {
    preceded(
        literal(TokenKind::KWhile),
        cut_err((
            delimited(
                literal(TokenKind::OpenPar),
                expr,
                literal(TokenKind::ClosePar),
            ),
            block,
        )),
    )
    .map(|(condition, stmts)| WhileStmt { condition, stmts })
    .parse_next(input)
}

fn var_decl(input: &mut TokenSlice<Token>) -> winnow::ModalResult<VarDecl> {
    seq!(
        one_of(|t: &Token| *t == TokenKind::KLet || *t == TokenKind::KVar),
        cut_err(seq!(
            ident,
            opt(preceded(literal(TokenKind::Colon), r#type)),
            opt(preceded(literal(TokenKind::Equals), expr)),
            _: literal(TokenKind::Semicolon),
        ))
    )
    .map(|(mutable, (ident, ty, value))| VarDecl {
        mutable: *mutable == TokenKind::KVar,
        ident,
        ty,
        value,
    })
    .parse_next(input)
}

fn assignment(input: &mut TokenSlice<Token>) -> winnow::ModalResult<AssignmentStmt> {
    seq!(
        place_expr,
        _: literal(TokenKind::Equals),
        expr,
    )
    .map(|(place, value)| AssignmentStmt { place, value })
    .parse_next(input)
}

fn expr_stmt(input: &mut TokenSlice<Token>) -> winnow::ModalResult<Expr> {
    terminated(expr, cut_err(literal(TokenKind::Semicolon))).parse_next(input)
}

fn r#break(input: &mut TokenSlice<Token>) -> winnow::ModalResult<()> {
    terminated(
        literal(TokenKind::KBreak),
        cut_err(literal(TokenKind::Semicolon)),
    )
    .map(|_| ())
    .parse_next(input)
}

fn r#continue(input: &mut TokenSlice<Token>) -> winnow::ModalResult<()> {
    terminated(
        literal(TokenKind::KContinue),
        cut_err(literal(TokenKind::Semicolon)),
    )
    .map(|_| ())
    .parse_next(input)
}

fn r#return(input: &mut TokenSlice<Token>) -> winnow::ModalResult<Option<Expr>> {
    delimited(
        literal(TokenKind::KReturn),
        cut_err(opt(expr)),
        cut_err(literal(TokenKind::Semicolon)),
    )
    .parse_next(input)
}

fn expr(input: &mut TokenSlice<Token>) -> winnow::ModalResult<Expr> {
    expression(alt((
        e_literal.map(Expr::Literal),
        function_call.map(Expr::FunctionCall),
        paren_expr.map(Expr::Paren),
        struct_init.map(Expr::StructInit),
        ident.map(Expr::Ident),
    )))
    .postfix(alt((
        preceded(
            literal(TokenKind::Dot),
            Postfix(1, |input: &mut _, base| {
                let member = ident.parse_next(input)?;
                Ok(Expr::MemberAccess(Box::new(MemberAccessExpr {
                    base,
                    member,
                })))
            }),
        ),
        preceded(
            literal(TokenKind::OpenBracket),
            Postfix(1, |input: &mut _, base| {
                let index = terminated(expr, literal(TokenKind::CloseBracket)).parse_next(input)?;
                Ok(Expr::Subscript(Box::new(SubscriptExpr { base, index })))
            }),
        ),
    )))
    .parse_next(input)
}

fn place_expr(input: &mut TokenSlice<Token>) -> winnow::ModalResult<PlaceExpr> {
    // TODO
    alt((ident.map(PlaceExpr::Ident),)).parse_next(input)
}

fn e_literal(input: &mut TokenSlice<Token>) -> winnow::ModalResult<LiteralExpr> {
    // TODO: Number literals
    alt((
        string_lit.map(LiteralExpr::String),
        int_lit.map(LiteralExpr::Int),
    ))
    .parse_next(input)
}

fn function_call(input: &mut TokenSlice<Token>) -> winnow::ModalResult<FunctionCallExpr> {
    seq!(
        ident,
        _: literal(TokenKind::OpenPar),
        cut_err(separated(0.., arg_value, literal(TokenKind::Comma))),
        _: opt(literal(TokenKind::Comma)),
        _: cut_err(literal(TokenKind::ClosePar)),
    )
    .map(|(ident, arguments): (_, Vec<ArgumentValue>)| FunctionCallExpr { ident, arguments })
    .parse_next(input)
}

fn arg_value(input: &mut TokenSlice<Token>) -> winnow::ModalResult<ArgumentValue> {
    alt((
        preceded(literal(TokenKind::Ampersand), place_expr).map(ArgumentValue::Mutable),
        expr.map(ArgumentValue::Immutable),
    ))
    .parse_next(input)
}

fn paren_expr(input: &mut TokenSlice<Token>) -> winnow::ModalResult<Box<Rich<Expr>>> {
    seq!(
        literal(TokenKind::OpenPar),
        expr,
        literal(TokenKind::ClosePar),
    )
    .map(|(open, value, close)| {
        Box::new(Rich {
            value,
            span: ((open[0].span.start)..(close[0].span.end)).into(),
        })
    })
    .parse_next(input)
}

fn struct_init(input: &mut TokenSlice<Token>) -> winnow::ModalResult<StructInitExpr> {
    seq!(
        ident,
        _: literal(TokenKind::OpenBrace),
        separated(0.., struct_arg, literal(TokenKind::Comma)),
        _: literal(TokenKind::CloseBrace),
    )
    .map(|(ident, arguments)| StructInitExpr { ident, arguments })
    .parse_next(input)
}

fn struct_arg(input: &mut TokenSlice<Token>) -> winnow::ModalResult<StructInitArgument> {
    seq!(
        ident,
        _: literal(TokenKind::Colon),
        expr
    )
    .map(|(label, value)| StructInitArgument { label, value })
    .parse_next(input)
}

fn r#type(input: &mut TokenSlice<Token>) -> winnow::ModalResult<Type> {
    ident
        .map(|ident| {
            Type::Simple(SimpleType {
                ident,
                generic_parameters: vec![],
            })
        })
        .parse_next(input)
}

fn ident(input: &mut TokenSlice<Token>) -> winnow::ModalResult<Rich<String>> {
    literal(TokenKind::Id)
        .map(|name: &[Token]| Rich {
            value: name[0].value.clone(),
            span: name[0].span,
        })
        .parse_next(input)
}

fn string_lit(input: &mut TokenSlice<Token>) -> winnow::ModalResult<Rich<String>> {
    literal(TokenKind::String)
        .map(|name: &[Token]| Rich {
            value: name[0].value.clone(),
            span: name[0].span,
        })
        .parse_next(input)
}

fn int_lit(input: &mut TokenSlice<Token>) -> winnow::ModalResult<Rich<i128>> {
    literal(TokenKind::Int)
        .map(|name: &[Token]| {
            let (radix, num) = match name[0].value.get(..2) {
                Some("0b") => (2, &name[0].value[2..]),
                Some("0o") => (8, &name[0].value[2..]),
                Some("0x") => (16, &name[0].value[2..]),
                _ => (10, name[0].value.as_str()),
            };
            let value = i128::from_str_radix(num, radix)
                .expect("Int already has been parsed and so should be valid.");
            Rich {
                value,
                span: name[0].span,
            }
        })
        .parse_next(input)
}

// Below reporting code taken more or less straight from winnow
fn translate_position(input: &[u8], index: usize) -> (usize, usize) {
    if input.is_empty() {
        return (0, index);
    }

    let safe_index = index.min(input.len() - 1);
    let column_offset = index - safe_index;
    let index = safe_index;

    let nl = input[0..index]
        .iter()
        .rev()
        .enumerate()
        .find(|(_, b)| **b == b'\n')
        .map(|(nl, _)| index - nl - 1);
    let line_start = match nl {
        Some(nl) => nl + 1,
        None => 0,
    };
    let line = input[0..line_start].iter().filter(|b| **b == b'\n').count();

    // HACK: This treats byte offset and column offsets the same
    let column = core::str::from_utf8(&input[line_start..=index])
        .map(|s| s.chars().count() - 1)
        .unwrap_or_else(|_| index - line_start);
    let column = column + column_offset;

    (line, column)
}

pub fn print_parse_error(
    input: &str,
    e: ParseError<TokenSlice<'_, Token>, ContextError>,
) -> std::io::Result<()> {
    use std::io::Write;
    let mut f = std::io::stderr().lock();
    let input = input.as_bytes();
    let token = &e.input()[e.offset()];
    let span_start = token.span.start;
    let span_end = token.span.end;
    let (line_idx, col_idx) = translate_position(input, span_start);
    let line_num = line_idx + 1;
    let col_num = col_idx + 1;
    let gutter = line_num.to_string().len();
    let content = input
        .split(|c| *c == b'\n')
        .nth(line_idx)
        .expect("valid line number");

    writeln!(f, "parse error at line {line_num}, column {col_num}")?;
    //   |
    for _ in 0..gutter {
        write!(f, " ")?;
    }
    writeln!(f, " |")?;

    // 1 | 00:32:00.a999999
    write!(f, "{line_num} | ")?;
    writeln!(f, "{}", String::from_utf8_lossy(content))?;

    //   |          ^
    for _ in 0..gutter {
        write!(f, " ")?;
    }
    write!(f, " | ")?;
    for _ in 0..col_idx {
        write!(f, " ")?;
    }
    // The span will be empty at eof, so we need to make sure we always print at least
    // one `^`
    write!(f, "^")?;
    for _ in (span_start + 1)..(span_end.min(span_start + content.len())) {
        write!(f, "^")?;
    }
    writeln!(f)?;
    write!(f, "{}", e.inner())?;

    Ok(())
}
