// Stupid interpreter hack that won't compile where we execute invalid code if the assertion does fail
f assert(predicate: B, info: S) {
    i (not(predicate)) {
        print(info);
        assertion_failed = assertion_failed;
    }
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
