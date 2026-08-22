#![allow(dead_code)]
use crate::ast::{
    ArgumentValue, AssignmentStmt, Ast, Decl, Expr, Field, Function, FunctionCallExpr,
    FunctionSignature, Ident, LiteralExpr, MemberAccessExpr, MemberPlaceExpr, PlaceExpr, Rich,
    SimpleType, Stmt, Struct, StructInitArgument, StructInitExpr, SubscriptExpr, Type, VarDecl,
};
use crate::interpreter::{Interpreter, Value};
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

    #[arg(required_unless_present("expr"))]
    input_file: Option<PathBuf>,

    #[arg(short, long, conflicts_with("input_file"))]
    expr: Option<String>,
}

fn main() {
    let args = Args::parse();

    let expr = args
        .input_file
        .map(|path| std::fs::read_to_string(path).unwrap())
        .or(args.expr)
        .unwrap();

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

    let ast = match parse(&tokens) {
        Ok(ast) => ast,
        Err(e) => {
            print_parse_error(&expr, e).unwrap();
            return;
        }
    };

    if args.ast {
        println!("{ast:#?}");
    }

    let ast = if args.bundled {
        Ast {
            decls: vec![
                Decl::Struct(Struct {
                    ident: ident("Person"),
                    fields: vec![
                        Field {
                            ident: ident("name"),
                            ty: ty("S"),
                        },
                        Field {
                            ident: ident("age"),
                            ty: ty("I"),
                        },
                    ],
                }),
                Decl::Function(Function {
                    signature: FunctionSignature {
                        ident: ident("main"),
                        parameters: vec![],
                        ret: None,
                    },
                    stmts: vec![
                        Stmt::VarDecl(VarDecl {
                            mutable: true,
                            ident: ident("person"),
                            ty: None,
                            value: Some(Expr::StructInit(StructInitExpr {
                                ident: ident("Person"),
                                arguments: vec![
                                    StructInitArgument {
                                        label: ident("name"),
                                        value: str_lit("stackotter"),
                                    },
                                    StructInitArgument {
                                        label: ident("age"),
                                        value: int_lit(21),
                                    },
                                ],
                            })),
                        }),
                        Stmt::Expr(Expr::FunctionCall(FunctionCallExpr {
                            ident: ident("print"),
                            arguments: vec![ast::ArgumentValue::Immutable(Expr::MemberAccess(
                                Box::new(MemberAccessExpr {
                                    base: Expr::Ident(ident("person")),
                                    member: ident("name"),
                                }),
                            ))],
                        })),
                        Stmt::Assignment(AssignmentStmt {
                            place: PlaceExpr::Member(Box::new(MemberPlaceExpr {
                                base: PlaceExpr::Ident(ident("person")),
                                member: ident("name"),
                            })),
                            value: str_lit("bpaul"),
                        }),
                        Stmt::Expr(Expr::FunctionCall(FunctionCallExpr {
                            ident: ident("print"),
                            arguments: vec![ArgumentValue::Immutable(Expr::MemberAccess(
                                Box::new(MemberAccessExpr {
                                    base: Expr::Ident(ident("person")),
                                    member: ident("name"),
                                }),
                            ))],
                        })),
                        Stmt::Expr(Expr::FunctionCall(FunctionCallExpr {
                            ident: ident("print"),
                            arguments: vec![ArgumentValue::Immutable(Expr::FunctionCall(
                                FunctionCallExpr {
                                    ident: ident("S_new_from_char"),
                                    arguments: vec![ArgumentValue::Immutable(Expr::Subscript(
                                        Box::new(SubscriptExpr {
                                            base: Expr::MemberAccess(Box::new(MemberAccessExpr {
                                                base: Expr::Ident(ident("person")),
                                                member: ident("name"),
                                            })),
                                            index: int_lit(3),
                                        }),
                                    ))],
                                },
                            ))],
                        })),
                    ],
                }),
            ],
        }
    } else {
        ast
    };

    let mut interpreter = Interpreter::new(ast);
    interpreter.register_stdlib_builtins();

    interpreter.eval_fn("main", vec![]).unwrap();
}
