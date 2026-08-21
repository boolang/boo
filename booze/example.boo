t Question {
  MultiChoice,
  ShortResponse,
}

t Result<Success, Failure> {
  Ok(Success),
  Err(Failure),
}

s Exam {
  questions: Vec<Question>,
}

f add(int1: I, int2: I) -> I {
  l result = int1 + int2;
  r result;
}

f display_question(question: Question, result: Result<I, I>) {
  m (question) {
    MultiChoice => {
      m (result) {
        Ok(value) => { print("It was okay :)"); }
        Error(value) => { print("There was an error :("); }
      }
    }
  }
}

f main() {
  v index = 5;
  w (index != 0) {
    i (index == 1) {
      print("1");
    } e i (index == 2) {
      print("2");
    } e {
      print("3");
    }
  }
}
