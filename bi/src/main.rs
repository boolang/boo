#![allow(dead_code)]
use crate::ast::{
    AssignmentStmt, Ast, Decl, Expr, Field, Function, FunctionCallExpr, FunctionSignature, Ident,
    LiteralExpr, MemberAccessExpr, MemberPlaceExpr, PlaceExpr, Rich, SimpleType, Stmt, Struct,
    StructInitArgument, StructInitExpr, Type, VarDecl,
};
use crate::interpreter::{Interpreter, Value};
use crate::lexer::tokenise;
use crate::parser::parse;
use std::range::Range;

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

fn main() {
    // println!(
    //     "{:?}",
    //     tokenise(
    //         r#"f foo bar 0b101011 -0x3276f "hi\n" '\'' "\\\"rteahsie\nah" // no more tokens :3
    //         oh ho "#
    //     )
    // )

    println!(
        "{:?}",
        parse(
            &tokenise(r#"s Person { name: S, age: I } f main() { l person = "stackotter"; }"#)
                .unwrap()
        )
    );

    println!("{:?}", tokenise("f foo bar 0b101011 -0x3276f"));

    let ast = Ast {
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
                        arguments: vec![Expr::MemberAccess(Box::new(MemberAccessExpr {
                            base: Expr::Ident(ident("person")),
                            member: ident("name"),
                        }))],
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
                        arguments: vec![Expr::MemberAccess(Box::new(MemberAccessExpr {
                            base: Expr::Ident(ident("person")),
                            member: ident("name"),
                        }))],
                    })),
                ],
            }),
        ],
    };

    let mut interpreter = Interpreter::new(ast);
    interpreter.register_builtin("print", vec![("string", "S")], |arguments| {
        println!("{}", arguments[0].as_string()?);
        Ok(Value::Unit)
    });

    interpreter.eval_fn("main", vec![]).unwrap();
}
