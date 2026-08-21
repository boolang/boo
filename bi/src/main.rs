#![allow(dead_code)]
use crate::ast::{
    Ast, Decl, Expr, Function, FunctionCallExpr, FunctionSignature, Ident, LiteralExpr, Stmt,
    StringLiteral,
};
use crate::interpreter::Interpreter;
use crate::lexer::tokenise;
use crate::parser::parse;
use std::range::Range;

mod ast;
mod interpreter;
mod lexer;
mod parser;

fn main() {
    // println!(
    //     "{:?}",
    //     tokenise(
    //         r#"f foo bar 0b101011 -0x3276f "hi\n" '\'' "\\\"rteahsie\nah" // no more tokens :3
    //         oh ho "#
    //     )
    // )

    println!("{:?}", parse(&tokenise("s Foo {}").unwrap()));

    let dummy_span: Range<usize> = Range { start: 0, end: 0 };
    let ast = Ast {
        decls: vec![Decl::Function(Function {
            signature: FunctionSignature {
                ident: Ident::new(String::from("main"), dummy_span),
                parameters: vec![],
            },
            stmts: vec![Stmt::Expr(Expr::FunctionCall(FunctionCallExpr {
                ident: Ident::new(String::from("print"), dummy_span),
                arguments: vec![Expr::Literal(LiteralExpr::String(StringLiteral::new(
                    String::from("Hello, World!"),
                    dummy_span,
                )))],
            }))],
        })],
    };
    let mut interpreter = Interpreter::new(ast);
    interpreter.eval_fn("main", vec![]).unwrap();

    println!("{:?}", tokenise("f foo bar 0b101011 -0x3276f"))
}
