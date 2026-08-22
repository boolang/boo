s Person {
    name: S,
    age: I,
}

f mk_name() -> S {
    l value = "bpaul";
    r value;
}

f S_replace(self: &S, new: S) {
    self = new;
}

f main() {
    v person = Person { name: "stackotter", age: 1 };
    print(person.name);
    person.name = mk_name();
    print(person.name);

    v name = "";
    S_replace(&name, "max");
    print(name);
    name = mk_name();
}
