use crate::lexer::tokenise;

mod lexer;

fn main() {
    println!("{:?}", tokenise("f foo bar 0b101011 -0x3276f"))
}
