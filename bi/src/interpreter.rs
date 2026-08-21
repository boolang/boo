use std::collections::HashMap;

use crate::ast::{Ast, Decl, Enum, Expr, Function, LiteralExpr, Stmt, Struct};
use anyhow::{Result, anyhow};

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub enum Value {
    Int(i128),
    Bool(bool),
    String(String),
    Unit,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
struct Variable {
    mutable: bool,
    value: Option<Value>,
}

#[derive(Clone, Debug, Eq, PartialEq)]
struct Scope {
    is_loop: bool,
    variables: HashMap<String, Variable>,
}

impl Scope {
    fn new(is_loop: bool) -> Self {
        Self {
            is_loop,
            variables: HashMap::new(),
        }
    }
}

#[derive(Clone, Debug, Eq, PartialEq)]
struct Context {
    scopes: Vec<Scope>,
}

impl Context {
    fn new() -> Self {
        let mut context = Self { scopes: Vec::new() };
        context.new_scope(false);
        context
    }

    fn allow_loop_control(&self) -> bool {
        self.scopes.iter().any(|scope| scope.is_loop)
    }

    fn new_scope(&mut self, is_loop: bool) -> &mut Scope {
        self.scopes.push(Scope::new(is_loop));
        let index = self.scopes.len() - 1;
        &mut self.scopes[index]
    }

    fn pop_scope(&mut self) -> Option<Scope> {
        self.scopes.pop()
    }

    fn get_variable(&self, ident: &str) -> Result<Value> {
        for scope in self.scopes.iter().rev() {
            if let Some(variable) = scope.variables.get(ident) {
                return Ok(variable
                    .value
                    .clone()
                    .ok_or(anyhow!(
                        "Read from '{}' before it was assigned a value",
                        ident
                    ))?
                    .clone());
            }
        }
        Err(anyhow!("No such variable '{}' in current context", ident))
    }

    fn set_variable(&mut self, ident: &str, new_value: Value) -> Result<()> {
        for scope in self.scopes.iter_mut().rev() {
            if let Some(variable) = scope.variables.get_mut(ident) {
                variable.value = Some(new_value);
                return Ok(());
            }
        }
        Err(anyhow!("No such variable '{}' in current context", ident))
    }

    fn new_variable(&mut self, ident: &str, mutable: bool, value: Option<Value>) -> Result<()> {
        for scope in self.scopes.iter() {
            if scope.variables.contains_key(ident) {
                return Err(anyhow!("Variable already exists with name '{}'", ident));
            }
        }

        self.scopes
            .last_mut()
            .ok_or(anyhow!("Context with no scopes??"))?
            .variables
            .insert(String::from(ident), Variable { mutable, value });

        Ok(())
    }
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct Interpreter {
    functions: Vec<Function>,
    structs: Vec<Struct>,
    enums: Vec<Enum>,
    context: Context,
}

enum Action {
    Break,
    Continue,
    Return(Value),
}

impl Interpreter {
    pub fn new(ast: Ast) -> Self {
        Self {
            functions: ast
                .decls
                .iter()
                .flat_map(|decl| match decl {
                    Decl::Function(function) => Some(function.clone()),
                    _ => None,
                })
                .collect(),
            structs: ast
                .decls
                .iter()
                .flat_map(|decl| match decl {
                    Decl::Struct(struct_decl) => Some(struct_decl.clone()),
                    _ => None,
                })
                .collect(),
            enums: ast
                .decls
                .iter()
                .flat_map(|decl| match decl {
                    Decl::Enum(enum_decl) => Some(enum_decl.clone()),
                    _ => None,
                })
                .collect(),
            context: Context::new(),
        }
    }

    pub fn eval_fn(&mut self, ident: &str, arguments: Vec<Value>) -> Result<Value> {
        let function = match self
            .functions
            .iter()
            .find(|f| f.signature.ident.value == ident)
        {
            Some(f) => f,
            None => return Err(anyhow!("No such function {}", ident)),
        }
        .clone();

        if function.signature.parameters.len() != arguments.len() {
            return Err(anyhow!(
                "{} expected {} parameters, got {}",
                ident,
                function.signature.parameters.len(),
                arguments.len()
            ));
        }

        let caller_context = self.context.clone();

        self.context = Context::new();
        for (param, arg) in function.signature.parameters.iter().zip(arguments) {
            self.context
                .new_variable(&param.label.value, false, Some(arg))?;
        }
        self.exec_block(&function.stmts, false)?;

        self.context = caller_context;
        Ok(Value::Unit)
    }

    fn exec_block(&mut self, stmts: &[Stmt], is_loop: bool) -> Result<Option<Action>> {
        self.context.new_scope(is_loop);
        let result = self.exec_stmts(stmts)?;
        self.context.pop_scope();
        Ok(result)
    }

    fn exec_stmts(&mut self, stmts: &[Stmt]) -> Result<Option<Action>> {
        for stmt in stmts.iter() {
            if let Some(action) = self.exec_stmt(stmt)? {
                return Ok(Some(action));
            }
        }
        Ok(None)
    }

    fn exec_stmt(&mut self, stmt: &Stmt) -> Result<Option<Action>> {
        match stmt {
            Stmt::VarDecl(decl) => {
                let value = match &decl.value {
                    Some(expr) => Some(self.eval_expr(expr)?),
                    None => None,
                };
                self.context
                    .new_variable(&decl.ident.value, decl.mutable, value)?;
            }
            Stmt::Assignment(assignment) => {
                let value = self.eval_expr(&assignment.value)?;
                self.context.set_variable(&assignment.ident.value, value)?;
            }
            Stmt::If(if_stmt) => {
                for if_block in &if_stmt.if_blocks {
                    if self.eval_condition(&if_block.condition)? {
                        return self.exec_block(&if_block.stmts, false);
                    }
                }

                if let Some(else_block) = &if_stmt.else_block {
                    return self.exec_block(&else_block.stmts, false);
                }
            }
            Stmt::While(while_stmt) => loop {
                if !self.eval_condition(&while_stmt.condition)? {
                    break;
                }

                let action = self.exec_block(&while_stmt.stmts, true)?;
                match action {
                    Some(Action::Break) => break,
                    Some(Action::Return(value)) => return Ok(Some(Action::Return(value))),
                    Some(Action::Continue) | None => {}
                }
            },
            Stmt::Break => {
                if self.context.allow_loop_control() {
                    return Ok(Some(Action::Break));
                } else {
                    return Err(anyhow!("break is not allowed outside of loops"));
                }
            }
            Stmt::Continue => {
                if self.context.allow_loop_control() {
                    return Ok(Some(Action::Continue));
                } else {
                    return Err(anyhow!("continue is not allowed outside of loops"));
                }
            }
            Stmt::Return(expr) => match expr {
                Some(expr) => return Ok(Some(Action::Return(self.eval_expr(expr)?))),
                None => return Ok(Some(Action::Return(Value::Unit))),
            },
            Stmt::Expr(expr) => {
                self.eval_expr(expr)?;
            }
        }
        Ok(None)
    }

    fn eval_condition(&mut self, condition: &Expr) -> Result<bool> {
        let condition = self.eval_expr(condition)?;
        let condition_value = match condition {
            Value::Bool(value) => value,
            _ => return Err(anyhow!("Condition must be a boolean")),
        };
        Ok(condition_value)
    }

    fn eval_expr(&mut self, expr: &Expr) -> Result<Value> {
        match expr {
            Expr::Ident(ident) => self.context.get_variable(&ident.value),
            Expr::Literal(literal) => Ok(self.eval_literal(literal)),
            Expr::Paren(expr) => self.eval_expr(&expr.value),
            Expr::FunctionCall(call) => {
                let arguments: Result<Vec<_>> = call
                    .arguments
                    .iter()
                    .map(|argument| self.eval_expr(argument))
                    .collect();
                self.eval_fn(&call.ident.value, arguments?)
            }
        }
    }

    fn eval_literal(&mut self, literal: &LiteralExpr) -> Value {
        match literal {
            LiteralExpr::Int(value) => Value::Int(value.value),
            LiteralExpr::Bool(value) => Value::Bool(value.value),
            LiteralExpr::String(value) => Value::String(value.value.clone()),
        }
    }
}
