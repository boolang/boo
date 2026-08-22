f write_to_file(path: S, contents: S) -> U;

f or(first: B, second: B) -> B;
f and(first: B, second: B) -> B;
f not(first: B) -> B;

f C_eq(char: C, char: C) -> B;
f C_ord(char: C) -> I;
f C_le(char: C, char: C) -> B;
f C_ge(char: C, char: C) -> B;

f I_le(a: I, b: I) -> B;
f I_ge(a: I, b: I) -> B;
f I_lt(a: I, b: I) -> B;
f I_gt(a: I, b: I) -> B;

f S_new_from_char(char: C) -> S;
f S_is_empty(string: S) -> B;
f S_push(string: S, char: C) -> S;

f S_len(string: S) -> I;
f S_advance(string: S, offset: I) -> S;
f S_eq(string: S, string: S) -> B;
f S_length(string: S) -> I;
f S_set_range(replacer: &S, offset: I, substr: S) -> U;

f I_add(a: I, b: I) -> I;
f I_sub(a: I, b: I) -> I;
f I_mul(a: I, b: I) -> I;
f I_neg(a: I) -> I;
f I_to_string(a: I) -> S;
f I_eq(a: I, b: I) -> B;
f I_chr(a: I) -> C;
f I_u16_to_bytes(a: I) -> S;
f I_u32_to_bytes(a: I) -> S;
f I_i32_to_bytes(a: I) -> S;
f I_u64_to_bytes(a: I) -> S;

f read(path: S) -> S;

f V_new<T>() -> V<T>;
f V_push<T>(vec: &V<T>, element: T) -> U;
f V_len<T>(vec: &V<T>) -> I;
f V_get<T>(vec: &V<T>, idx: I) -> T;
f V_set<T>(vec: &V<T>, idx: I, new_value: T) -> U;
