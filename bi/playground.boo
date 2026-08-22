s Person {
    name: S,
    age: I,
}

t Token {
    Comma,
    Integer(I),
}

f mk_name() -> S {
    l value = "bpaul";
    r value;
}

f S_replace(self: &S, new: S) {
    self = new;
}

f id<T>(value: T) -> T {
    r value;
}

f main() {
    v person = Person { name: "stackotter", age: 1 };
    print(person.name);
    person.name = mk_name();
    print(person.name);

    v name = "";
    S_replace(&name, "max");
    print(name);

    l token1 = Token::Comma;
    l token2 = Token::Integer(1);

    print(id(name));
}
