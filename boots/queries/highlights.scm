[ "b" "c" "e" "f" "i" "l" "m" "r" "s" "t" "v" "w" ] @keyword

[ "=" "->" "=>" ] @punctuation
[ "(" ")" "{" "}" "<" ">" "[" "]" ] @punctuation.bracket
[ "," ";" ":" "::" "." ] @punctuation.delimiter

[ "-" "+" "*" "/" "%" "&" "|" ">>" "<<" "&&" "||" "==" "!=" "!" "~" ] @operator

(fun_def (identifier) @function)
(struct_def (identifier) @type)
(struct_term (identifier) @variable)
(enum_def (identifier) @type)
(enum_term (identifier) @constructor)
(place_expr (binding) @variable)
(place_expr (identifier) @variable)
(var_decl_statement (binding) @variable)
(typed_var (binding) @variable)
(pattern (identifier) @constructor)
(pattern (binding) @variable)
(call (identifier) @function.call)
(expression (identifier) @variable)
(member_access (identifier) @variable)
(struct_init_arg (identifier) @variable)
(enum_init (identifier) @constructor)
(type (identifier) @type)
(string) @string
(char) @string
(number) @number
(comment) @comment
