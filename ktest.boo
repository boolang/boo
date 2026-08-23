f mk_msg() -> S {
    r "Hello, World!";
}

f main() {
    // malloc(32);
    // nop();
    // i (n) {
    //     print("No");
    // } e i (n) {
    //     print("Yes");
    // } e {
    //     print("Else");
    // }
    // do_exit<S>(43);
    // do_exit<I>(43);

    v cond: B = n;
    check(cond);
    my_print(mk_msg());
    exit(0);
}

f my_print(msg: S) {
    print(msg);
}

f check(var: B) {
    i (var) {
        print("Fizz");
    } e {
        print("Buzz");
    }
}

f nop() {}
