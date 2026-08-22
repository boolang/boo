s Variable {
    size: I,
    id: I,
}

s Copy {
    from: Variable,
    to: Variable,
}

s AssignLit {
    var: Variable,
    val: I,
}

s Load {
    from: Variable,
    to: Variable,
}

s Call {
    proc_id: I,
    args: V<Variable>,
    ret: Variable,
}

t Statement {
    Copy(Copy),
    AssignLit(AssignLit),
    Load(Load),
    Call(Call),
}

s Block {
    stmts: V<Statement>,
}

s Successor {
    cond: Variable,
    true: I,
    false: I,
}

s CFG {
    blocks: V<Block>,
    succs: V<Successor>,
    vars: V<Variable>,
}

s Procedure {
    cfg: CFG,
    // Name of variables that are passed in
    args: V<Variable>,
    // Name of variable that stores the return result
    return: Variable,
}

s Program {
    procedures: V<Procedure>,
}

f var_mem(var: Variable, list: V<Variable>) -> B {
    v var_idx = 0;
    w (not(I_eq(var_idx, V_len<Variable>(list)))) {
        i (I_eq(var.id, list[var_idx].id)) {
            r y;
        }
        var_idx = I_add(var_idx, 1);
    }
    r n;
}

// Check that every variable used in the cfg is in the vars list of the cfg. Panics if not.
f validate_vars(graph: CFG) {
    v block_idx = 0;
    w (not(I_eq(block_idx, V_len<Block>(graph.blocks)))) {
        l stmts = graph.blocks[block_idx].stmts;
        v stmt_idx = 0;
        w (not(I_eq(stmt_idx, V_len<Statement>(stmts)))) {
            m (stmts[stmt_idx]) {
                Statement::Copy(copy) => {
                    assert(var_mem(copy.from, graph.vars), "var not declared");
                    assert(var_mem(copy.to, graph.vars), "var not declared");
                }
                Statement::AssignLit(assign) => {
                    assert(var_mem(assign.var, graph.vars), "var not declared");
                }
                Statement::Load(load) => {
                    assert(var_mem(load.from, graph.vars), "var not declared");
                    assert(var_mem(load.to, graph.vars), "var not declared");
                }
                Statement::Call(call) => {
                    assert(var_mem(call.ret, graph.vars), "var not declared");
                    v arg_idx = 0;
                    w (not(I_eq(arg_idx, V_len<Variable>(call.args)))) {
                        assert(var_mem(call.args[arg_idx], graph.vars), "var not declared");
                        arg_idx = I_add(arg_idx, 1);
                    }
                }
            }
            stmt_idx = I_add(stmt_idx, 1);
        }
        block_idx = I_add(block_idx, 1);
    }
}
