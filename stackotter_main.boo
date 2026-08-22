f main() {
    v map = Map_new<S>();
    Map_insert<S>(&map, "a", "x");
    Map_insert<S>(&map, "b", "y");
    Map_insert<S>(&map, "a", "z");
    print("a is:");
    print(O_get<S>(Map_get<S>(map, "a")));
    print("b is:");
    print(O_get<S>(Map_get<S>(map, "b")));
    i (Map_contains<S>(map, "a")) {
        print("Map contains key 'a'");
    } e {
        print("Map doesn't contain key 'a'");
    }
    i (Map_contains<S>(map, "c")) {
        print("Map contains key 'c'");
    } e {
        print("Map doesn't contain key 'c'");
    }
}
