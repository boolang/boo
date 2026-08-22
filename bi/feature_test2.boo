// Built-ins (these will be built-ins in the interpreter, but the compiler will
// probably have lower level built-ins and these can be defined and implemented
// in a stdlib prelude)
//
//   f V_new<T>() -> V<T>; 
//   f V_append<T>(vec: &V<T>, element: T); 
//   f S_new_with_chars(chars: V<C>) -> S;
//   f S_concat(left: S, right: S) -> S;

f c_to_s(char: C) S {
    // At first (and maybe forever), we should always require explicitly
    // specifying generics (otherwise we have to write a whole inference thing).
    l chars = V_new<C>();
    V_append<C>(&chars, char);
    return S_new_with_chars(chars);
}
