f mk_msg() -> S {
    v msg: S = "Hello, World!";
    msg = "Boo, World!";
    r msg;
}

f main() {
    // my_print(mk_msg());
    // print(mk_msg());

    // v lhs = "lhs";
    // v rhs = "rhs";
    // print_both(lhs, rhs);
    // v lhs1 = y;
    // v rhs1 = n;
    // check_both(lhs1, rhs1);

    exit(I_add(12, 13));
}

f check_both(lhs: B, rhs: B) {
    i (lhs) {
        print("lhs is y");
    } e {
        print("lhs is n");
    }

    i (rhs) {
        print("rhs is y");
    } e {
        print("lhs is n");
    }
}

f proxy(lhs: S, rhs: S) {
    print_both(lhs, rhs);
}

f print_both(lhs: S, rhs: S) {
    print(lhs);
    print(rhs);
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
