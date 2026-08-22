use std::range::Range;
use std::sync::Mutex;
use std::{collections::HashMap, sync::Arc};

use crate::ast::{
    ArgumentType, ArgumentValue as ArgumentValueExpr, Ast, Binding, Decl, Enum, EnumInitExpr, Expr,
    Function, FunctionSignature, Ident, LiteralExpr, Parameter, PlaceExpr, SimpleType, Stmt,
    Struct, StructInitExpr, Type,
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
pub struct EnumValue {
    pub decl: Enum,
    pub case: usize,
    pub value: Option<Value>,
}

impl EnumValue {
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
    Enum(Box<EnumValue>),
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
            Value::Enum(value) => value.ty(),
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

    pub fn as_enum(&self) -> Result<EnumValue> {
        match &self {
            Value::Enum(value) => Ok(*value.clone()),
            _ => Err(anyhow!("Expected enum, got {}", self.infer_type())),
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
    generic_parameters: HashMap<String, Type>,
}

impl Context {
    fn new() -> Self {
        let mut context = Self {
            scopes: Vec::new(),
            generic_parameters: HashMap::new(),
        };
        context.new_scope(false);
        context
    }

    fn add_generic_params(
        &mut self,
        generic_params: Vec<Ident>,
        generic_args: Vec<Type>,
    ) -> Result<()> {
        if generic_params.len() != generic_args.len() {
            return Err(anyhow!(
                "Expected {} generic arguments, but got {}",
                generic_params.len(),
                generic_args.len(),
            ));
        }

        for (param, arg) in generic_params.into_iter().zip(generic_args) {
            if self.generic_parameters.contains_key(&param.value) {
                return Err(anyhow!(
                    "Duplicate generic parameter name '{}'",
                    param.value
                ));
            }
            self.generic_parameters.insert(param.value, arg);
        }

        Ok(())
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
        self.new_variable_from_storage(ident, mutable, ty, value.map(|x| Arc::new(Mutex::new(x))))
    }

    fn new_variable_from_arg(
        &mut self,
        ident: &str,
        ty: Option<Type>,
        value: ArgumentValue,
    ) -> Result<()> {
        let (mutable, storage) = match value {
            ArgumentValue::Immutable(value) => (false, Some(Arc::new(Mutex::new(value)))),
            ArgumentValue::Mutable(value) => (true, Some(value.clone())),
        };
        self.new_variable_from_storage(ident, mutable, ty, storage)
    }

    fn new_variable_from_storage(
        &mut self,
        ident: &str,
        mutable: bool,
        ty: Option<Type>,
        storage: Option<Arc<Mutex<Value>>>,
    ) -> Result<()> {
        let ty = match ty {
            Some(ty) => ty,
            None => match &storage {
                Some(storage) => storage
                    .lock()
                    .map_err(|_| anyhow!("Poisoned lock"))?
                    .infer_type(),
                None => {
                    return Err(anyhow!(
                        "Variable declaration for '{}' must have an initial value or type annotation",
                        ident
                    ));
                }
            },
        };

        let variable = Variable {
            mutable,
            value: storage,
            ty,
        };

        self.new_variable_raw(ident, variable)
    }

    fn new_variable_raw(&mut self, ident: &str, variable: Variable) -> Result<()> {
        for scope in self.scopes.iter() {
            if scope.variables.contains_key(ident) {
                return Err(anyhow!("Variable already exists with name '{}'", ident));
            }
        }

        self.scopes
            .last_mut()
            .ok_or(anyhow!("Context with no scopes??"))?
            .variables
            .insert(String::from(ident), variable);

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
        self.register_builtin("print", vec![("string", "S")], "U", |arguments| {
            println!("{}", arguments[0].as_string()?);
            Ok(Value::Unit)
        });

        self.register_builtin(
            "or",
            vec![("first", "B"), ("second", "B")],
            "B",
            |arguments| {
                Ok(Value::Bool(
                    arguments[0].as_bool()? || arguments[1].as_bool()?,
                ))
            },
        );
        self.register_builtin(
            "and",
            vec![("first", "B"), ("second", "B")],
            "B",
            |arguments| {
                Ok(Value::Bool(
                    arguments[0].as_bool()? && arguments[1].as_bool()?,
                ))
            },
        );
        self.register_builtin("not", vec![("first", "B")], "B", |arguments| {
            Ok(Value::Bool(!arguments[0].as_bool()?))
        });

        self.register_builtin(
            "C_eq",
            vec![("char", "C"), ("char", "C")],
            "B",
            |arguments| {
                Ok(Value::Bool(
                    arguments[0].as_char()? == arguments[1].as_char()?,
                ))
            },
        );
        self.register_builtin("C_ord", vec![("char", "C")], "I", |arguments| {
            Ok(Value::Int(arguments[0].as_char()? as _))
        });
        self.register_builtin(
            "C_le",
            vec![("char", "C"), ("char", "C")],
            "B",
            |arguments| {
                Ok(Value::Bool(
                    arguments[0].as_char()? <= arguments[1].as_char()?,
                ))
            },
        );
        self.register_builtin(
            "C_ge",
            vec![("char", "C"), ("char", "C")],
            "B",
            |arguments| {
                Ok(Value::Bool(
                    arguments[0].as_char()? >= arguments[1].as_char()?,
                ))
            },
        );

        self.register_builtin("S_new_from_char", vec![("char", "C")], "S", |arguments| {
            Ok(Value::String(arguments[0].as_char()?.to_string()))
        });
        self.register_builtin(
            "S_push",
            vec![("string", "S"), ("char", "C")],
            "S",
            |arguments| {
                Ok(Value::String({
                    let mut s = arguments[0].as_string()?;
                    s.push(arguments[1].as_char()?);
                    s
                }))
            },
        );
        self.register_builtin(
            "S_advance",
            vec![("string", "S"), ("offset", "I")],
            "S",
            |arguments| {
                Ok(Value::String(
                    arguments[0].as_string()?[arguments[1].as_int()? as usize..].to_owned(),
                ))
            },
        );
        self.register_builtin(
            "S_eq",
            vec![("string", "S"), ("string", "S")],
            "B",
            |arguments| {
                Ok(Value::Bool(
                    arguments[0].as_string()? == arguments[1].as_string()?,
                ))
            },
        );

        self.register_builtin("I_add", vec![("a", "I"), ("b", "I")], "I", |arguments| {
            Ok(Value::Int(arguments[0].as_int()? + arguments[1].as_int()?))
        });
        self.register_builtin("I_sub", vec![("a", "I"), ("b", "I")], "I", |arguments| {
            Ok(Value::Int(arguments[0].as_int()? - arguments[1].as_int()?))
        });
        self.register_builtin("I_mul", vec![("a", "I"), ("b", "I")], "I", |arguments| {
            Ok(Value::Int(arguments[0].as_int()? * arguments[1].as_int()?))
        });
        self.register_builtin("I_neg", vec![("a", "I")], "I", |arguments| {
            Ok(Value::Int(-arguments[0].as_int()?))
        });
        self.register_builtin("I_to_string", vec![("a", "I")], "S", |arguments| {
            Ok(Value::String(arguments[0].as_int()?.to_string()))
        });
    }

    pub fn register_builtin<F: Fn(Vec<Value>) -> Result<Value> + 'static>(
        &mut self,
        ident: &str,
        parameters: Vec<(&'static str, &'static str)>,
        return_type: &'static str,
        body: F,
    ) {
        self.builtins.insert(
            String::from(ident),
            BuiltinFunction {
                signature: FunctionSignature {
                    ident: Ident::new(ident.into(), Range { start: 0, end: 0 }),
                    generic_parameters: vec![],
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
                    ret: Some(Type::Simple(SimpleType {
                        ident: Ident::new((*return_type).into(), Range { start: 0, end: 0 }),
                        generic_parameters: vec![],
                    })),
                },
                body: Arc::new(body),
            },
        );
    }

    pub fn eval_arg_ty(&mut self, ty: &ArgumentType) -> Result<ArgumentType> {
        let resolved = self.eval_ty(&ty.ty)?;
        Ok(ArgumentType {
            ty: resolved,
            mutable: ty.mutable,
        })
    }

    pub fn eval_ty(&mut self, ty: &Type) -> Result<Type> {
        // If the type doesn't have generic parameters of its own, search for
        // it in the generic parameters first (they can shadow other global
        // declarations)
        if let Type::Simple(simple) = ty
            && simple.generic_parameters.is_empty()
            && let Some(arg) = self.context.generic_parameters.get(&simple.ident.value)
        {
            return Ok(arg.clone());
        }

        // Allow built-in types
        if ["S", "C", "I", "U"].contains(&ty.to_string().as_str()) {
            return Ok(ty.clone());
        }

        match ty {
            Type::Simple(ty) => {
                if self.structs.iter().any(|x| x.ident.value == ty.ident.value)
                    || self.enums.iter().any(|x| x.ident.value == ty.ident.value)
                {
                    Ok(Type::Simple(ty.clone()))
                } else {
                    Err(anyhow!("No such type '{}'", ty))
                }
            }
        }
    }

    pub fn eval_fn(
        &mut self,
        ident: &str,
        generic_arguments: Vec<Type>,
        arguments: Vec<ArgumentValue>,
    ) -> Result<Value> {
        enum Body {
            Stmts(Vec<Stmt>),
            Builtin(BuiltinFunctionBody),
        }

        let (signature, body) = match self
            .functions
            .iter()
            .find(|f| f.signature.ident.value == ident)
        {
            Some(f) => (f.signature.clone(), Body::Stmts(f.stmts.clone())),
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

        let caller_context = self.context.clone();

        self.context = Context::new();
        self.context
            .add_generic_params(signature.generic_parameters, generic_arguments)?;

        for (param, arg) in signature.parameters.iter().zip(&arguments) {
            let param_ty = self.eval_arg_ty(&param.ty)?;
            if !param_ty.is_equiv(&arg.infer_type()) {
                return Err(anyhow!(
                    "Parameter '{}' of function '{}' has type {} but got argument of type {}",
                    param.label.value,
                    ident,
                    param_ty,
                    arg.infer_type()
                ));
            }
        }

        let action = match body {
            Body::Stmts(stmts) => {
                for (param, arg) in signature.parameters.iter().zip(arguments) {
                    self.context.new_variable_from_arg(
                        &param.label.value,
                        Some(param.ty.ty().clone()),
                        arg,
                    )?;
                }

                self.exec_block(&stmts.clone(), false)?
            }
            Body::Builtin(body) => Some(Action::Return(body(
                arguments.iter().map(|arg| arg.value()).collect(),
            )?)),
        };

        let return_value = match action {
            Some(Action::Break) => return Err(anyhow!("break made it to top level of function??")),
            Some(Action::Continue) => {
                return Err(anyhow!("continue made it to top level of function??"));
            }
            Some(Action::Return(value)) => value,
            None => Value::Unit,
        };

        let declared_return_type = self.eval_ty(&signature.ret.unwrap_or(Type::unit()))?;

        self.context = caller_context;

        if !return_value.infer_type().is_equiv(&declared_return_type) {
            return Err(anyhow!(
                "Function '{}' returned value of type {} but declared a return type of {}",
                signature.ident.value,
                return_value.infer_type(),
                declared_return_type
            ));
        }

        Ok(return_value)
    }

    fn exec_block(&mut self, stmts: &[Stmt], is_loop: bool) -> Result<Option<Action>> {
        self.exec_block_with_vars(stmts, is_loop, vec![])
    }

    fn exec_block_with_vars(
        &mut self,
        stmts: &[Stmt],
        is_loop: bool,
        vars: Vec<(String, Variable)>,
    ) -> Result<Option<Action>> {
        self.context.new_scope(is_loop);
        for (ident, var) in vars.into_iter() {
            self.context.new_variable_raw(&ident, var)?;
        }
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
            Stmt::Match(match_stmt) => {
                let value = self.eval_expr(&match_stmt.value)?;
                let enum_value = value.as_enum()?;
                for case_block in &match_stmt.case_blocks {
                    if case_block.pattern.ident.value != enum_value.decl.ident.value {
                        return Err(anyhow!(
                            "Found case for enum '{}' in match of value from enum '{}'",
                            case_block.pattern.ident.value,
                            enum_value.decl.ident.value
                        ));
                    }

                    if !enum_value
                        .decl
                        .cases
                        .iter()
                        .any(|x| x.ident.value == case_block.pattern.case.value)
                    {
                        return Err(anyhow!(
                            "Enum '{}' does not have a case called '{}' (in match)",
                            enum_value.decl.ident.value,
                            case_block.pattern.case.value
                        ));
                    }
                }

                let block = match_stmt.case_blocks.iter().find(|case| {
                    case.pattern.ident.value == enum_value.decl.cases[enum_value.case].ident.value
                });
                if let Some(block) = block {
                    let vars: Vec<(String, Variable)> = match (
                        &block.pattern.binding,
                        enum_value.value,
                    ) {
                        (Some(Binding::Ident(binding)), Some(value)) => {
                            vec![(
                                binding.value.clone(),
                                Variable {
                                    mutable: false,
                                    ty: value.infer_type(),
                                    value: Some(Arc::new(Mutex::new(value))),
                                },
                            )]
                        }
                        (Some(_), None) => {
                            return Err(anyhow!(
                                "Attempted to destructure case '{}' of enum '{}' with associated value but the case was valueless",
                                block.pattern.case.value,
                                block.pattern.ident.value
                            ));
                        }
                        _ => vec![],
                    };
                    return self.exec_block_with_vars(&block.stmts, false, vars);
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
                self.eval_fn(
                    &call.ident.value,
                    call.generic_parameters.clone(),
                    arguments?,
                )
            }
            Expr::StructInit(struct_init) => self.eval_struct_init(struct_init),
            Expr::EnumInit(enum_init) => self.eval_enum_init(enum_init),
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

    fn eval_enum_init(&mut self, enum_init: &EnumInitExpr) -> Result<Value> {
        let enum_decl = self
            .enums
            .iter()
            .find(|decl| decl.ident.value == enum_init.ident.value)
            .ok_or(anyhow!(
                "No such enum '{}' (referenced from enum init expr at {:?})",
                enum_init.ident.value,
                enum_init.ident.span
            ))?
            .clone();

        let (case_index, case) = enum_decl
            .cases
            .iter()
            .enumerate()
            .find(|x| x.1.ident.value == enum_init.case.value)
            .ok_or(anyhow!(
                "Enum '{}' has no case '{}'",
                enum_decl.ident.value,
                enum_init.case.value
            ))?;

        if case.ty.is_some() != enum_init.value.is_some() {
            return Err(anyhow!(
                "Case '{}' of enum '{}' expected a value and wasn't given one, or vice versa",
                case.ident.value,
                enum_decl.ident.value
            ));
        }

        let value = enum_init
            .value
            .clone()
            .map(|expr| self.eval_expr(&expr))
            .transpose()?;

        // Check value type against expected type
        if let (Some(ty), Some(value)) = (&case.ty, &value)
            && !ty.is_equiv(&value.infer_type())
        {
            return Err(anyhow!(
                "Case '{}' of enum '{}' expected a value of type '{}' but got a value of type '{}'",
                case.ident.value,
                enum_decl.ident.value,
                ty,
                value.infer_type()
            ));
        }

        Ok(Value::Enum(Box::new(EnumValue {
            decl: enum_decl,
            case: case_index,
            value,
        })))
    }

    fn eval_literal(&mut self, literal: &LiteralExpr) -> Value {
        match literal {
            LiteralExpr::Int(value) => Value::Int(value.value),
            LiteralExpr::Bool(value) => Value::Bool(value.value),
            LiteralExpr::String(value) => Value::String(value.value.clone()),
            LiteralExpr::Char(value) => Value::Character(value.value),
        }
    }
}
