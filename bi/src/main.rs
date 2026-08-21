#![allow(dead_code)]

use crate::lexer::tokenise;

mod ast;
mod lexer;

fn main() {
    println!(
        "{:?}",
        tokenise(
            r#"f foo bar 0b101011 -0x3276f "hi\n" '\'' "\\\"rteahsie\nah" // no more tokens :3
            oh ho "#
        )
    )
}
