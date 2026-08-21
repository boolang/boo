use crate::lexer::tokenise;

mod lexer;
mod ast;

fn main() {
    println!("{:?}", tokenise(r#"f foo bar 0b101011 -0x3276f "hi""#))
}
