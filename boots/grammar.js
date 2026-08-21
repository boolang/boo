/**
 * @file boo tree sitter grammar
 */

/// <reference types="tree-sitter-cli/dsl" />
// @ts-check

export default grammar({
  name: "boots",

  extras: ($) => [
    /\s/,
    $.comment,
  ],

  rules: {
    // TODO: add the actual grammar rules
    source_file: $ => repeat($._definition),

    _definition: $ => choice(
      $.fun_def,
      $.struct_def,
      $.enum_def,
    ),

    fun_def: $ => seq(
      'f',
      $.identifier,
      optional($.generics),
      '(',
      optional(seq($.typed_var, repeat(seq(',', $.typed_var)))),
      ')',
      optional(seq('->', $.type)),
      $.block,
    ),

    struct_def: $ => seq(
      's',
      $.identifier,
      optional($.generics),
      '{',
      $.struct_term,
      repeat(seq(',', $.struct_term)),
      '}',
    ),

    struct_term: $ => seq(
      $.identifier, ':', $.type, ','
    ),

    enum_def: $ => seq(
      't',
      $.identifier,
      optional($.generics),
      '{',
      $.enum_term,
      repeat(seq(',', $.enum_term)),
      '}',
    ),

    enum_term: $ => choice(
      $.identifier,
      seq($.identifier, '(', $.type, ')')
    ),

    generics: $ => seq(
      '<',
      $.type, repeat(seq(',', $.type)),
      '>'
    ),

    block: $ => seq(
      '{',
      repeat($.statement),
      '}',
    ),

    statement: $ => choice(
      $.if_statement,
      $.while_statement,
      $.match_statement,
      $.assign_statement,
      $.var_decl_statement,
      $.call_statement,
      $.return_statement,
      $.break,
      $.continue,
    ),

    if_statement: $ => seq(
      'i',
      '(', $.expression, ')',
      $.block,
      optional(choice(
        seq('e', $.block),
        seq('e', $.if_statement),
      )),
    ),

    while_statement: $ => seq(
      'w',
      '(', $.expression, ')',
      $.block,
    ),

    match_statement: $ => seq(
      'm',
      '(', $.expression, ')',
      '{',
      repeat(seq($.pattern, '=>', $.block, optional(','))),
      '}',
    ),

    assign_statement: $ => seq(
      $.binding,
      '=',
      $.expression,
      ';',
    ),

    var_decl_statement: $ => seq(
      choice('l', 'v'),
      choice($.binding, $.typed_var),
      '=',
      $.expression,
      ';',
    ),

    call_statement: $ => seq($.call, ';'),

    return_statement: $ => seq('r', $.expression, ';'),

    break: $ => seq('break', ';'),
    continue: $ => seq('continue', ';'),

    // TODO all of this
    expression: $ => choice(
      $.literal,
      $.binary_expr,
      $.call,
      $.identifier,
    ),

    literal: $ => choice(
      $.string,
      $.number,
    ),

    // TODO
    binary_expr: $ => choice(
      prec.left(1, seq($.expression, "==", $.expression)),
      prec.left(1, seq($.expression, "!=", $.expression)),
      prec.left(2, seq($.expression, "+", $.expression)),
      prec.left(3, seq($.expression, "*", $.expression)),
    ),

    call: $ => seq(
      $.identifier,
      '(',
      $.expression, repeat(seq(',', $.expression)),
      ')',
    ),

    pattern: $ => choice(
      $.identifier,
      seq($.identifier, '(', $.binding, ')'),
    ),

    typed_var: $ => seq(
      $.binding,
      ':',
      $.type,
    ),

    binding: $ => $.identifier,

    type: $ => choice(
      $.identifier,
      seq($.identifier, $.generics)
    ),

    string: $ => /\"[^\"]*\"/,

    number: $ => /([1-9][0-9]*)|0/,

    identifier: $ => /[a-zA-Z_][a-zA-Z0-9_]*/,

    comment: $ => token(
      choice(seq("//", /.*/))
    ),
  }
});
