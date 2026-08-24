f not(val: B) -> B {
    i (val) {
        r n;
    } e {
        r y;
    }
}

f or(left: B, right: B) -> B {
    i (left) {
        r y;
    } e i (right) {
        r y;
    } e {
        r n;
    }
}

f and(left: B, right: B) -> B {
    r not(or(not(left), not(right)));
}

f I_ge(left: I, right: I) -> B {
    r not(I_lt(left, right));
}

f I_gt(left: I, right: I) -> B {
    r and(I_ge(left, right), not(I_eq(left, right)));
}

f I_le(left: I, right: I) -> B {
    r not(I_gt(left, right));
}

f I_sub(left: I, right: I) -> B {
    r I_add(left, I_neg(right));
}

f C_le(left: C, right: C) -> B {
    r I_le(C_ord(left), C_ord(right));
}

f C_ge(char: C, char: C) -> B {
    r I_ge(C_ord(left), C_ord(right));
}

f C_eq(left: C, right: C) -> B {
    r I_eq(C_ord(left), C_ord(right));
}

// FIXME: Jank alert!! These builtins rely on our current lack of type checking

f I_chr(val: I) -> C {
    r val;
}

f C_ord(char: C) -> I {
    r char;
}
