use crate::lexer::tokenise;

mod lexer;

fn main() {
    println!("{:?}", tokenise("f foo bar"))
}
