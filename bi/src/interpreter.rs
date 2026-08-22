use std::range::Range;
use std::sync::Mutex;
use std::{collections::HashMap, sync::Arc};

use crate::ast::{
    ArgumentType, ArgumentValue as ArgumentValueExpr, Ast, Decl, Enum, Expr, Function,
    FunctionSignature, Ident, LiteralExpr, Parameter, PlaceExpr, SimpleType, Stmt, Struct,
    StructInitExpr, Type,
};
use anyhow::{Result, anyhow};

#[derive(Clone, Debug)]
pub struct StructValue {
    pub decl: Struct,
    pub value: HashMap<String, Arc<Mutex<Value>>>,
}

impl StructValue {
    fn ty(&self) -> Type {
        simple_type(&self.decl.ident.value)
    }
}

#[derive(Clone, Debug)]
pub enum Value {
    Int(i128),
    Bool(bool),
    String(String),
    Character(char),
    Unit,
    Struct(StructValue),
}

#[derive(Clone, Debug)]
pub enum ArgumentValue {
    Immutable(Value),
    Mutable(Arc<Mutex<Value>>),
}

impl ArgumentValue {
    fn value(&self) -> Value {
        match self {
            Self::Immutable(value) => value.clone(),
            Self::Mutable(value) => value.lock().expect("Poisoned lock").clone(),
        }
    }

    fn is_mutable_reference(&self) -> bool {
        match self {
            Self::Immutable(_) => false,
            Self::Mutable(_) => true,
        }
    }

    fn set_value(&self, new_value: Value) -> Result<()> {
        match self {
            Self::Immutable(_) => Err(anyhow!(
                "Value is not a mutable reference (attempted to take assign to it)"
            )),
            Self::Mutable(value) => {
                *(value.lock().map_err(|_| anyhow!("Poisoned lock"))?) = new_value;
                Ok(())
            }
        }
    }

    fn infer_type(&self) -> ArgumentType {
        ArgumentType {
            ty: self.value().infer_type(),
            mutable: self.is_mutable_reference(),
        }
    }
}

fn simple_type(ident: &str) -> Type {
    Type::Simple(SimpleType {
        ident: Ident::new(ident.into(), Range { start: 0, end: 0 }),
        generic_parameters: vec![],
    })
}

impl Value {
    fn infer_type(&self) -> Type {
        match self {
            Value::Int(_) => simple_type("I"),
            Value::Bool(_) => simple_type("B"),
            Value::String(_) => simple_type("S"),
            Value::Character(_) => simple_type("C"),
            Value::Unit => simple_type("U"),
            Value::Struct(value) => value.ty(),
        }
    }

    pub fn as_string(&self) -> Result<String> {
        match &self {
            Value::String(value) => Ok(value.clone()),
            _ => Err(anyhow!("Expected S, got {}", self.infer_type())),
        }
    }

    pub fn as_int(&self) -> Result<i128> {
        match &self {
            Value::Int(value) => Ok(*value),
            _ => Err(anyhow!("Expected I, got {}", self.infer_type())),
        }
    }

    pub fn as_bool(&self) -> Result<bool> {
        match &self {
            Value::Bool(value) => Ok(*value),
            _ => Err(anyhow!("Expected B, got {}", self.infer_type())),
        }
    }

    pub fn as_char(&self) -> Result<char> {
        match &self {
            Value::Character(value) => Ok(*value),
            _ => Err(anyhow!("Expected C, got {}", self.infer_type())),
        }
    }

    pub fn as_struct(&self) -> Result<StructValue> {
        match &self {
            Value::Struct(value) => Ok(value.clone()),
            _ => Err(anyhow!("Expected struct, got {}", self.infer_type())),
        }
    }

    pub fn as_struct_mut(&mut self) -> Result<&mut StructValue> {
        match self {
            Value::Struct(value) => Ok(value),
            _ => Err(anyhow!("Expected struct, got {}", self.infer_type())),
        }
    }
}

#[derive(Clone, Debug)]
struct Variable {
    mutable: bool,
    value: Option<Arc<Mutex<Value>>>,
    ty: Type,
}

#[derive(Clone, Debug)]
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

#[derive(Clone, Debug)]
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
                    .lock()
                    .map_err(|_| anyhow!("Poisoned mutex"))?
                    .clone());
            }
        }
        Err(anyhow!("No such variable '{}' in current context", ident))
    }

    fn set_variable(&mut self, ident: &str, new_value: Value) -> Result<()> {
        for scope in self.scopes.iter_mut().rev() {
            if let Some(variable) = scope.variables.get_mut(ident) {
                if variable.ty != new_value.infer_type() {
                    return Err(anyhow!(
                        "Attempted to assign value of type {} to variable '{}' with type {}",
                        new_value.infer_type(),
                        ident,
                        variable.ty
                    ));
                }
                if !variable.mutable {
                    return Err(anyhow!(
                        "Attempted to mutate immutable variable '{}'",
                        ident
                    ));
                }
                match &variable.value {
                    Some(location) => {
                        *(location.lock().map_err(|_| anyhow!("Poisoned lock"))?) = new_value
                    }
                    None => variable.value = Some(Arc::new(Mutex::new(new_value))),
                }
                return Ok(());
            }
        }
        Err(anyhow!("No such variable '{}' in current context", ident))
    }

    fn get_variable_mut(&self, ident: &str) -> Result<Arc<Mutex<Value>>> {
        for scope in self.scopes.iter().rev() {
            if let Some(variable) = scope.variables.get(ident) {
                if !variable.mutable {
                    return Err(anyhow!(
                        "Attempted to mutate immutable variable '{}'",
                        ident
                    ));
                }

                match &variable.value {
                    Some(value) => return Ok(value.clone()),
                    None => {
                        return Err(anyhow!(
                            "Attempted to get mutable reference to uninitialized variable '{}' (likely through a member access)",
                            ident
                        ));
                    }
                }
            }
        }
        Err(anyhow!("No such variable '{}' in current context", ident))
    }

    fn new_variable(
        &mut self,
        ident: &str,
        mutable: bool,
        ty: Option<Type>,
        value: Option<Value>,
    ) -> Result<()> {
        self.new_variable_from_arg(ident, mutable, ty, value.map(ArgumentValue::Immutable))
    }

    fn new_variable_from_arg(
        &mut self,
        ident: &str,
        mutable: bool,
        ty: Option<Type>,
        value: Option<ArgumentValue>,
    ) -> Result<()> {
        for scope in self.scopes.iter() {
            if scope.variables.contains_key(ident) {
                return Err(anyhow!("Variable already exists with name '{}'", ident));
            }
        }

        let ty = match ty {
            Some(ty) => ty,
            None => match &value {
                Some(value) => value.value().infer_type(),
                None => {
                    return Err(anyhow!(
                        "Variable declaration for '{}' must have an initial value or type annotation",
                        ident
                    ));
                }
            },
        };

        let value = match value {
            Some(ArgumentValue::Immutable(value)) => Some(Arc::new(Mutex::new(value))),
            Some(ArgumentValue::Mutable(value)) => Some(value.clone()),
            None => None,
        };

        self.scopes
            .last_mut()
            .ok_or(anyhow!("Context with no scopes??"))?
            .variables
            .insert(String::from(ident), Variable { mutable, value, ty });

        Ok(())
    }
}

type BuiltinFunctionBody = Arc<dyn Fn(Vec<Value>) -> Result<Value>>;

#[derive(Clone)]
struct BuiltinFunction {
    signature: FunctionSignature,
    body: BuiltinFunctionBody,
}

impl std::fmt::Debug for BuiltinFunction {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("BuiltinFunction")
            .field("signature", &self.signature)
            .finish()
    }
}

#[derive(Clone, Debug)]
pub struct Interpreter {
    functions: Vec<Function>,
    structs: Vec<Struct>,
    enums: Vec<Enum>,
    context: Context,
    builtins: HashMap<String, BuiltinFunction>,
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
            builtins: HashMap::new(),
        }
    }

    pub fn register_stdlib_builtins(&mut self) {
        self.register_builtin("print", vec![("string", "S")], |arguments| {
            println!("{}", arguments[0].as_string()?);
            Ok(Value::Unit)
        });
        self.register_builtin("S_new_from_char", vec![("char", "C")], |arguments| {
            Ok(Value::String(arguments[0].as_char()?.to_string()))
        });
    }

    pub fn register_builtin<F: Fn(Vec<Value>) -> Result<Value> + 'static>(
        &mut self,
        ident: &str,
        parameters: Vec<(&'static str, &'static str)>,
        body: F,
    ) {
        self.builtins.insert(
            String::from(ident),
            BuiltinFunction {
                signature: FunctionSignature {
                    ident: Ident::new(ident.into(), Range { start: 0, end: 0 }),
                    parameters: parameters
                        .iter()
                        .map(|(label, ty)| Parameter {
                            label: Ident::new((*label).into(), Range { start: 0, end: 0 }),
                            ty: ArgumentType {
                                ty: Type::Simple(SimpleType {
                                    ident: Ident::new((*ty).into(), Range { start: 0, end: 0 }),
                                    generic_parameters: vec![],
                                }),
                                mutable: false,
                            },
                        })
                        .collect(),
                    ret: None,
                },
                body: Arc::new(body),
            },
        );
    }

    pub fn eval_fn(&mut self, ident: &str, arguments: Vec<ArgumentValue>) -> Result<Value> {
        enum Body<'r> {
            Stmts(&'r Vec<Stmt>),
            Builtin(BuiltinFunctionBody),
        }

        let (signature, body) = match self
            .functions
            .iter()
            .find(|f| f.signature.ident.value == ident)
        {
            Some(f) => (f.signature.clone(), Body::Stmts(&f.stmts)),
            None => match self.builtins.get(ident) {
                Some(builtin) => (
                    builtin.signature.clone(),
                    Body::Builtin(builtin.body.clone()),
                ),
                None => return Err(anyhow!("No such function {}", ident)),
            },
        };

        if signature.parameters.len() != arguments.len() {
            return Err(anyhow!(
                "{} expected {} parameters, got {}",
                ident,
                signature.parameters.len(),
                arguments.len()
            ));
        }

        for (param, arg) in signature.parameters.iter().zip(&arguments) {
            if param.ty != arg.infer_type() {
                return Err(anyhow!(
                    "Parameter '{}' of function '{}' has type {} but got argument of type {}",
                    param.label.value,
                    ident,
                    param.ty,
                    arg.infer_type()
                ));
            }
        }

        let action = match body {
            Body::Stmts(stmts) => {
                let caller_context = self.context.clone();

                self.context = Context::new();
                for (param, arg) in signature.parameters.iter().zip(arguments) {
                    self.context.new_variable_from_arg(
                        &param.label.value,
                        false,
                        Some(param.ty.ty().clone()),
                        Some(arg),
                    )?;
                }

                let action = self.exec_block(&stmts.clone(), false)?;

                self.context = caller_context;

                action
            }
            Body::Builtin(body) => Some(Action::Return(body(
                arguments.iter().map(|arg| arg.value()).collect(),
            )?)),
        };

        match action {
            Some(Action::Break) => Err(anyhow!("break made it to top level of function??")),
            Some(Action::Continue) => Err(anyhow!("continue made it to top level of function??")),
            Some(Action::Return(value)) => Ok(value),
            None => Ok(Value::Unit),
        }
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
                self.context.new_variable(
                    &decl.ident.value,
                    decl.mutable,
                    decl.ty.clone(),
                    value,
                )?;
            }
            Stmt::Assignment(assignment) => {
                let value = self.eval_expr(&assignment.value)?;
                let target = self.resolve_lexpr(&assignment.place)?;
                let location = target.lock().map_err(|_| anyhow!("Poisoned lock"))?;
                if location.infer_type() != value.infer_type() {
                    return Err(anyhow!(
                        "Attempted to assign value of type {} to {} (which has type {})",
                        value.infer_type(),
                        assignment.place,
                        location.infer_type()
                    ));
                }
                drop(location);
                *(target.lock().map_err(|_| anyhow!("Poisoned lock"))?) = value;
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

    fn resolve_lexpr(&mut self, lexpr: &PlaceExpr) -> Result<Arc<Mutex<Value>>> {
        match lexpr {
            PlaceExpr::Ident(ident) => self.context.get_variable_mut(&ident.value),
            PlaceExpr::Member(member) => {
                let base = self.resolve_lexpr(&member.base)?;
                let base_struct = base
                    .lock()
                    .map_err(|_| anyhow!("Poisoned lock"))?
                    .as_struct()?;
                let ty = base_struct.ty();
                base_struct
                    .value
                    .get(&member.member.value)
                    .ok_or(anyhow!(
                        "Value of type '{}' doesn't have member '{}' (at {:?})",
                        ty,
                        member.member.value,
                        member.member.span
                    ))
                    .cloned()
            }
        }
    }

    fn eval_condition(&mut self, condition: &Expr) -> Result<bool> {
        let condition = self.eval_expr(condition)?;
        let condition_value = match condition {
            Value::Bool(value) => value,
            _ => return Err(anyhow!("Condition must be a boolean")),
        };
        Ok(condition_value)
    }

    fn eval_arg_value(&mut self, value: &ArgumentValueExpr) -> Result<ArgumentValue> {
        match value {
            ArgumentValueExpr::Immutable(expr) => {
                Ok(ArgumentValue::Immutable(self.eval_expr(expr)?))
            }
            ArgumentValueExpr::Mutable(expr) => {
                Ok(ArgumentValue::Mutable(self.resolve_lexpr(expr)?))
            }
        }
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
                    .map(|argument| self.eval_arg_value(argument))
                    .collect();
                self.eval_fn(&call.ident.value, arguments?)
            }
            Expr::StructInit(struct_init) => self.eval_struct_init(struct_init),
            Expr::MemberAccess(member_access) => {
                let base_value = self.eval_expr(&member_access.base)?;
                let struct_value = base_value.as_struct()?;

                match struct_value.value.get(&member_access.member.value) {
                    Some(value) => Ok(value.lock().map_err(|_| anyhow!("Poisoned lock"))?.clone()),
                    None => Err(anyhow!(
                        "Value of type '{}' has no member '{}'",
                        struct_value.ty(),
                        member_access.member.value
                    )),
                }
            }
            Expr::Subscript(subscript) => {
                let base_value = self.eval_expr(&subscript.base)?;
                let string = base_value.as_string()?;
                let index_value = self.eval_expr(&subscript.index)?;
                let index = index_value.as_int()?;

                if index < 0 || index as usize >= string.len() {
                    return Err(anyhow!(
                        "Index {} out of bounds for string of length {}",
                        index,
                        string.len()
                    ));
                }

                Ok(Value::Character(
                    string.chars().nth(index as usize).unwrap(),
                ))
            }
        }
    }

    fn eval_struct_init(&mut self, struct_init: &StructInitExpr) -> Result<Value> {
        let struct_decl = self
            .structs
            .iter()
            .find(|decl| decl.ident.value == struct_init.ident.value)
            .ok_or(anyhow!(
                "No such struct '{}' (referenced from struct init expr at {:?})",
                struct_init.ident.value,
                struct_init.ident.span
            ))?
            .clone();
        if struct_decl.fields.len() != struct_init.arguments.len() {
            return Err(anyhow!(
                "struct '{}' has {} fields, but got given {} in init expression",
                struct_decl.ident.value,
                struct_decl.fields.len(),
                struct_init.arguments.len()
            ));
        }

        for (field, argument) in struct_decl.fields.iter().zip(&struct_init.arguments) {
            if field.ident.value != argument.label.value {
                return Err(anyhow!(
                    "Expected field named {} at {:?} but got a field named {} (in struct init expression for '{}')",
                    field.ident.value,
                    argument.label.span,
                    argument.label.value,
                    struct_decl.ident.value
                ));
            }
        }

        let mut values = HashMap::new();
        for (field, argument) in struct_decl.fields.iter().zip(&struct_init.arguments) {
            let value = self.eval_expr(&argument.value)?;
            if !value.infer_type().is_equiv(&field.ty) {
                return Err(anyhow!(
                    "Expected expression of type {} but got expression of type {} (for field {} of struct {})",
                    field.ty,
                    value.infer_type(),
                    field.ident.value,
                    struct_decl.ident.value
                ));
            }
            values.insert(field.ident.value.clone(), Arc::new(Mutex::new(value)));
        }

        Ok(Value::Struct(StructValue {
            decl: struct_decl.clone(),
            value: values,
        }))
    }

    fn eval_literal(&mut self, literal: &LiteralExpr) -> Value {
        match literal {
            LiteralExpr::Int(value) => Value::Int(value.value),
            LiteralExpr::Bool(value) => Value::Bool(value.value),
            LiteralExpr::String(value) => Value::String(value.value.clone()),
        }
    }
}
