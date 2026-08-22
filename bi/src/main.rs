#![allow(dead_code)]
use crate::ast::{
    ArgumentValue, AssignmentStmt, Ast, Decl, Expr, Field, Function, FunctionCallExpr,
    FunctionSignature, Ident, LiteralExpr, MemberAccessExpr, MemberPlaceExpr, PlaceExpr, Rich,
    SimpleType, Stmt, Struct, StructInitArgument, StructInitExpr, SubscriptExpr, Type, VarDecl,
};
use crate::interpreter::Interpreter;
use crate::lexer::tokenise;
use crate::parser::{parse, print_parse_error};

use std::path::PathBuf;
use std::range::Range;

use clap::Parser;

mod ast;
mod interpreter;
mod lexer;
mod parser;

fn ident(ident: &str) -> Ident {
    Ident::new(ident.into(), Range { start: 0, end: 0 })
}

fn ty(ty: &str) -> Type {
    Type::Simple(SimpleType {
        ident: ident(ty),
        generic_parameters: vec![],
    })
}

fn str_lit(value: &str) -> Expr {
    Expr::Literal(LiteralExpr::String(ident(value)))
}

fn int_lit(value: i128) -> Expr {
    Expr::Literal(LiteralExpr::Int(Rich {
        value,
        span: Range { start: 0, end: 0 },
    }))
}

#[derive(Parser)]
#[command(version, about, long_about = None)]
struct Args {
    #[arg(short, long)]
    tokenise: bool,

    #[arg(short, long)]
    ast: bool,

    #[arg(short, long)]
    bundled: bool,

    // #[arg(required_unless_present("expr"))]
    input_files: Vec<PathBuf>,
    // #[arg(short, long, conflicts_with("input_file"))]
    // expr: Option<String>,
}

fn main() {
    let args = Args::parse();

    let mut ast = Ast { decls: vec![] };

    for file in args.input_files {
        if args.tokenise || args.ast {
            eprintln!("{}", file.display());
        }

        let expr = std::fs::read_to_string(file).unwrap();

        let tokens = match tokenise(&expr) {
            Ok(tokens) => tokens,
            Err(e) => {
                eprintln!("{e}");
                return;
            }
        };

        if args.tokenise {
            println!("{tokens:#?}");
        }

        let mut file_ast = match parse(&tokens) {
            Ok(ast) => ast,
            Err(e) => {
                print_parse_error(&expr, e).unwrap();
                return;
            }
        };

        if args.ast {
            println!("{ast:#?}");
        }

        ast.decls.append(&mut file_ast.decls);
    }

    let mut interpreter = Interpreter::new(ast);
    interpreter.register_stdlib_builtins();

    interpreter.eval_fn("main", vec![], vec![]).unwrap();
}
