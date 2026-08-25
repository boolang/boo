// Probably only works for non-negative integers
f I_mod(value: I, modulus: I) -> I {
    r I_sub(value, I_mul(I_udiv(value, modulus), modulus));
}

f I_to_string(value: I) -> S {
    i (I_eq(value, 0)) {
        r "0";
    }

    l is_negative = I_lt(value, 0);

    v out = "";
    v rest = value;
    i (is_negative) {
        rest = I_neg(rest);
    }
    w (not(I_eq(rest, 0))) {
        out = S_concat(S_new_from_char(I_chr(I_add(48, I_mod(rest, 10)))), out);
        rest = I_udiv(rest, 10);
    }
    
    i (is_negative) {
        print("negative");
        out = S_concat("-", out);
    }

    r out;
}

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
