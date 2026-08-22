s O<T> {
    value: V<T>,
}

f O_none<T>() -> O<T> {
    r O<T> { value: V_new<T>() };
}

f O_some<T>(value: T) -> O<T> {
    v vec = V_new<T>();
    V_push(vec, value);
    r O<T> { value: vec };
}

f O_is_none<T>(opt: O<T>) -> B {
    r I_eq(V_len(opt.value), 0);
}

f O_is_some<T>(opt: O<T>) -> B {
    r not(O_is_none<T>(opt));
}

f O_get<T>(opt: O<T>) -> T {
    r V_get(opt.value, 0);
}
