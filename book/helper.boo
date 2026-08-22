// Stupid interpreter hack that won't compile where we execute invalid code if the assertion does fail
f assert(predicate: B, info: S) {
    i (not(predicate)) {
        print(info);
        assertion_failed = assertion_failed;
    }
}
