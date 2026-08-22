s MMKey {
    ident: S,
    generic_args: V<Type>,
}

f MMKey_eq(left: MMKey, right: MMKey) -> B {
    i (not(S_eq(left.ident, right.ident))) {
        r n;
    }

    i (not(I_eq(V_len<Type>(left.generic_args), V_len<Type>(right.generic_args)))) {
        r n;
    }

    v idx = 0;
    w (I_lt(idx, V_len<Type>(left.generic_args))) {
        i (not(Type_eq(V_get<Type>(left.generic_args, idx), V_get<Type>(right.generic_args, idx)))) {
            r n;
        }
        idx = I_add(idx, 1);
    }

    r y;
}

f Type_eq(left: Type, right: Type) -> B {
    i (not(S_eq(left.ident, right.ident))) {
        r n;
    }

    i (not(I_eq(V_len<Type>(left.generic_parameters), V_len<Type>(right.generic_parameters)))) {
        r n;
    }

    v idx = 0;
    w (I_lt(idx, V_len<Type>(left.generic_parameters))) {
        i (not(Type_eq(V_get<Type>(left.generic_parameters, idx), V_get<Type>(right.generic_parameters, idx)))) {
            r n;
        }
        idx = I_add(idx, 1);
    }

    r y;
}


s MMapEntry<Value> {
    key: MMKey,
    value: Value,
}

s MMap<Value> {
    storage: V<MMapEntry<Value>>,
}

f MMap_new<U>() -> MMap<U> {
    l storage = V_new<MMapEntry<U>>();
    l map = MMap<U> {
        storage: storage
    };
    r map;
}

f MMap_count<T>(map: MMap<T>) -> I {
    r V_len<MMapEntry<T>>(map.storage);
}

f MMap_insert<T>(map: &MMap<T>, key: MMKey, value: T) {
    l idx = MMap_find<T>(map, key);
    l entry = MMapEntry<T> {
        key: key,
        value: value
    };
    i (I_lt(idx, 0)) {
        V_push<MMapEntry<T>>(&map.storage, entry);
    } e {
        V_set<MMapEntry<T>>(&map.storage, idx, entry);
    }
}

f MMap_get<T>(map: MMap<T>, key: MMKey) -> O<T> {
    l idx = MMap_find<T>(map, key);
    i (I_lt(idx, 0)) {
        r O_none<T>();
    } e {
        r O_some<T>(V_get<MMapEntry<T>>(map.storage, idx).value);
    }
}

f MMap_contains<T>(map: MMap<T>, key: MMKey) -> B {
    l idx = MMap_find<T>(map, key);
    r I_ge(idx, 0);
}

f MMap_find<T>(map: MMap<T>, key: MMKey) -> I {
    v idx = 0;
    w (I_lt(idx, V_len<MMapEntry<T>>(map.storage))) {
        i (MMKey_eq(key, V_get<MMapEntry<T>>(map.storage, idx).key)) {
            r idx;
        }
        idx = I_add(idx, 1);
    }
    r -1;
}
