# IR specification

## Procedures
Procedures will be stored in a list, and their indices in the list will be their ids.
Procedures must specify argument count and return value size maybe?!

```
s Procedure {
    args: V<Variable>,
}
```

## Graph structure
Graphs represent procedures.
Graph structure given by list of blocks and list of successor info described by indices in the block list.

Successor info will be struct
```
s Successor {
    cond: Variable,
    true_branch: I,
    false_branch: I,
}
```
The cond variable being zero or non-zero dictates which branch will run.
The block should compute the truth value of the conditional in its body.

## Blocks
Blocks are just lists of statements.

## Statements
- Assign to copy a variable
- Load int literal into variable
- Deref (with a size) a pointer stored in a variable into another variable (with the right size).
- REDUNDANT just do addition lol ~~Struct offset a variable which is holding a pointer~~
- Calls, which take a bunch of variables as params and return one param into a variable.

```
t Statement {
    Copy(Copy),
    AssignLit(AssignLit),
    Load(Load),
    Call(Call),
}

s Copy {
    from: Variable,
    to: Variable,
}

s AssignLit {
    var: Variable,
    val: I,
}

s Load {
    // Stores a pointer
    from: Variable,
    // Will hold the value pointed to
    to: Variable,
}

s Call {
    proc_id: I,
    args: V<Variable>,
    ret: Variable,
}
```

## Variable
Variables are values stored on the stack.
```
s Variable {
    size: I,
    id: I,
}
```
