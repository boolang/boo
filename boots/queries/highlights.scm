[ "b" "c" "e" "f" "i" "l" "m" "r" "s" "t" "v" "w" ] @keyword

[ "=" "->" "=>" ] @punctuation
[ "(" ")" "{" "}" "<" ">" ] @punctuation.bracket
[ "," ";" ":" ] @punctuation.delimiter

[ "-" "+" "*" "/" "%" "&" "|" ">>" "<<" "&&" "||" "==" "!=" "!" "~" ] @operator

(fun_def (identifier) @function)
(struct_def (identifier) @type)
(struct_term (identifier) @variable)
(enum_def (identifier) @type)
(enum_term (identifier) @constructor)
(type (identifier) @type)
(assign_statement (binding) @variable)
(var_decl_statement (binding) @variable)
(typed_var (binding) @variable)
(pattern (identifier) @constructor)
(pattern (binding) @variable)
(call (identifier) @function.call)
(expression (identifier) @variable)
(string) @string
(number) @number
