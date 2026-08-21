## Plan

- Interpreter supports basic subset of planned language features (enough to implement compiler)
- Interpreter has minimal type checking (just checks the types of values when they're used, Python-style)
- Compiler aims to compile basic programs first and ignores the fact that it has to compile itself
- Eventually compiler compiles itself

## Stdlib

- Interpreter will have lookup table of built-in functions with implementations written in Rust
- Compiler can have builtins for the basic syscalls that we need and then just codegen those builtins as syscalls

## Syntax

```rs
t Question {
  MultiChoice,
  ShortResponse
}

t Result<Success, Failure> {
  Ok(Success),
  Err(Failure)
}

s Exam {
  questions: Vec<Question>
}

f add(int1: I, int2: I) -> I {
  l result = int1 + int2
  r result
}

f display_result(result: Result<S, U>) {
  m (result) {
    Ok(value) => {
      
    }
  }
}

f main() {
  v index = 5
  w (index != 0) {
    i (index == 1) {
      print("1")
    } e i (index == 2) {
      print("2")
    } e {
      print("3")
    }
  }
}
```

```
f main( (( (((
  if (index == 1(( (((
    print( (((((Hello, World((((( ((
  ((((
((((
```

```
a
b => break
c => continue
d
e => else
f => function
g
h
i => if
j
k
l => let (immutable variable)
m => match
n
o
p
q
r => return
s => struct
t => type (enum)
u
v => var (mutable variable)
w => while
x
y
z

A
B => boolean
C => 8 bit integer
D => 32 bit integer
E
F
G
H
I => integer
J
K
L
M
N
O
P
Q => 64 bit integer
R
S => string
T
U => unit type (and prefix for unsigned integer types)
V => vector
W
X
Y
Z
```
