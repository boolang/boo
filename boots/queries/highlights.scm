[ "e" "f" "i" "l" "m" "r" "s" "t" "v" "w" ] @keyword

(fun_def (identifier) @function)
(struct_def (identifier) @type)
(enum_def (identifier) @type)
(type (identifier) @type)

(assign_statement (binding) @variable)
(var_decl_statement (binding) @variable)
(pattern (identifier) @constructor (binding) @variable)
(call (identifier) @function.call)
(expression (identifier) @variable)
(string) @string
