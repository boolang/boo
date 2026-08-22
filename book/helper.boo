// Stupid interpreter hack that won't compile where we execute invalid code if the assertion does fail
f assert(predicate: B, info: S) {
    i (not(predicate)) {
        print(info);
        assertion_failed = assertion_failed;
    }
}

f dbg_print(string: S) {
    print(string);
}

f parser_dbg_print(string: S) {
}

f S_concat(first: S, second: S) -> S {
    v acc = first;
    v acc2 = second;

    w (not(S_is_empty(acc2))) {
        acc = S_push(acc, acc2[0]);
        acc2 = S_advance(acc2, 1);
    }

    r acc;
}

f I_min(left: I, right: I) -> I {
    i (I_lt(left, right)) {
        r left;
    }
    r right;
}

f V_find_string(vec: V<S>, key: S) -> I {
    v idx = 0;
    w (I_lt(idx, V_len<S>(vec))) {
        i (S_eq(key, V_get<S>(vec, idx))) {
            r idx;
        }
        idx = I_add(idx, 1);
    }
    r -1;
}
