// Required built-ins:
// * read(S) (read the contents of a file)

f main() {
	// TODO: Get target file/files from argv
	l src = "hello.boo";
	l contents = read(src);
	print(contents);
}
