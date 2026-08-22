f main() {
    do_exit<S>(43);
    do_exit<I>(43);
}

f do_exit<T>(x: T) {
    exit(67);
}
