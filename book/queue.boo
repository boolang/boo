s Q<T> {
	queue: V<T>,
	idx: I
}

f Q_new<T>() -> Q<T> {
	r Q<T> { queue: V_new<T>(), idx: 0 };
}

f Q_pop<T>(queue: &Q<T>) -> O<T> {
	i (I_lt(queue.idx, V_len<T>(queue.queue))) {
		l pop = O_some<T>(V_get<T>(queue.queue, queue.idx));
		queue.idx = I_add(queue.idx, 1);
		r pop;
	} e {
		r O_none<T>();
	}
}

f Q_push<T>(queue: &Q<T>, element: T) {
	V_push<T>(&queue.queue, element);
}

f Q_contains_string(queue: Q<S>, element: S) -> B {
	v idx = queue.idx;
	w (I_lt(idx, V_len<S>(queue.queue))) {
		i (S_eq(element, V_get<S>(queue.queue, idx))) {
			r y;
		}
	}
	r n;
}
