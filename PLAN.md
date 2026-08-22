## Features

- Subscripts for strings
- Generics
- Array standard library functions
- Way to get length of string
- Way for function to take mutable borrow of value (for 'methods' that have to mutate 'self')
- Operators (could maybe start out as built-in functions for now?)

## Time savers

- We should require that integer literals are typed (e.g. `1u8` and `12i32`), because otherwise we have to propagate type information back up to integer literals so that we know what type to instantiate them as. This decision should save a bunch of time on the type checking/inference side of things.
- We should always require generics to be explicitly specified (for similar reasons to the one about integer literals). Otherwise we have to do a bunch more type inference stuff.
