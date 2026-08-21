#![allow(dead_code)]

use crate::lexer::tokenise;
use crate::parser::parse;

mod ast;
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
}
