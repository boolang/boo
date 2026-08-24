s MapEntry<Value> {
    key: S,
    value: Value,
}

s Map<Value> {
    storage: V<MapEntry<Value>>,
    count: I
}

f Map_new<U>() -> Map<U> {
    l storage = V_new<MapEntry<U>>();
    l map = Map<U> {
        storage: storage,
        count: 0
    };
    r map;
}

f Map_count<T>(map: Map<T>) -> I {
    r map.count;
}

f Map_insert<T>(map: &Map<T>, key: S, value: T) {
    l idx = Map_find<T>(map, key);
    l entry = MapEntry<T> {
        key: key,
        value: value
    };
    i (I_lt(idx, 0)) {
        i (I_lt(map.count, V_len<MapEntry<T>>(map.storage))) {
            V_set<MapEntry<T>>(&map.storage, map.count, entry);
        } e {
            V_push<MapEntry<T>>(&map.storage, entry);
        }
        map.count = I_add(map.count, 1);
    } e {
        V_set<MapEntry<T>>(&map.storage, idx, entry);
    }
}

f Map_pop<T>(map: &Map<T>) {
    map.count = I_sub(map.count, 1);
}

f Map_get<T>(map: Map<T>, key: S) -> O<T> {
    l idx = Map_find<T>(map, key);
    i (I_lt(idx, 0)) {
        r O_none<T>();
    } e {
        r O_some<T>(V_get<MapEntry<T>>(map.storage, idx).value);
    }
}

f Map_contains<T>(map: Map<T>, key: S) -> B {
    l idx = Map_find<T>(map, key);
    r I_ge(idx, 0);
}

f Map_find<T>(map: Map<T>, key: S) -> I {
    v idx = 0;
    w (I_lt(idx, map.count)) {
        i (S_eq(key, V_get<MapEntry<T>>(map.storage, idx).key)) {
            r idx;
        }
        idx = I_add(idx, 1);
    }
    r -1;
}
