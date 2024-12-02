// SPDX-FileCopyrightText: (C) 2023 Alisa Lain <al1-ce@null.net>
// SPDX-License-Identifier: OSL-3.0

/// NoGC compatible FCFS container
module clib.queue;

import clib.vector;
import clib.memory;
import clib.iterator;

/// FCFS container
struct queue(T, A: IAllocator!T = allocator!T) {
    private struct Node {
        T value;
        Node* next = null;
    }

    private Node* _root = null;
    private Node* _end = null;
    private size_t _size = 0;
    private size_t _size_limit = -1;
    private A _allocator = null;

    /// Length of queue
    @property size_t size() @nogc nothrow { return _size; }

    /// Is queue empty
    @property bool empty() @nogc nothrow { return _root == null; }

    /// Returns first value without removing it from queue
    @property T front() @nogc nothrow {
        if (_root == null) return T.init;
        return (*_root).value;
    }

    /// Creates queue filled with vals
    this(T[] vals...) @nogc nothrow {
        _allocator = _new!A();
        push(vals);
    }

    this(ref scope queue!(T, A) other) @nogc nothrow {
        Node* n = other._root;
        for (int i = 0; i < other._size; ++i) {
            push(n.value);
            n = n.next;
        }
        _size = other._size;
        _size_limit = other._size_limit;
    }

    ~this() @nogc nothrow {
        while (_size > 0) pop();
        _free(_allocator);
    }

    scope queue!(T, A) clone() @nogc nothrow {
        queue!(T, A) q;
        Node* n = _root;
        for (int i = 0; i < _size; ++i) {
            q.push(n.value);
            n = n.next;
        }
        q._size = _size;
        q._size_limit = _size_limit;
        return q;
    }

    /// opOpAssign x ~= y == x.push(y)
    void opOpAssign(string op: "~")( in T b ) @nogc nothrow {
        push(b);
    }

    /// Adds vals at end of queue
    void push(T[] vals...) @nogc nothrow {
        if (_allocator is null) _allocator = _new!A();
        if (vals.length == 0) return;
        if (_size >= _size_limit) return;

        int i = 0;
        if (_root == null && _size < _size_limit) {
            Node* ptr = cast(Node*) _allocator.allocate_vptr(Node.sizeof);
            (*ptr).value = vals[i];
            (*ptr).next = null;
            _root = ptr;
            _end = ptr;
            ++_size;
            ++i;
        }

        for (;i < vals.length; ++i) {
            if (_size >= _size_limit) break;
            Node* ptr = cast(Node*) _allocator.allocate_vptr(Node.sizeof);
            (*ptr).value = vals[i];
            (*ptr).next = null;
            (*_end).next = ptr;
            _end = ptr;
            ++_size;
        }
    }

    /// Returns first value and removes it from queue or returns T.init if empty
    T pop() @nogc nothrow {
        if (_root == null) { return T.init; }
        T val = (*_root).value;
        --_size;
        if ((*_root).next != null) {
            Node* tmp = _root;
            _root = (*_root).next;
            _allocator.deallocate_vptr(tmp);
        } else {
            _allocator.deallocate_vptr(_root);
            _root = null;
            _end = null;
        }
        return val;
    }

    /++
    Limits length of queue, default is -1 which is limitless.
    If length is limited and new element is attempted to be
    pushed when Queue is overfilled nothing will happen.
    +/
    void limit_length(size_t len) @nogc nothrow {
        if (_root == null) return;
        if (len == 0) {
            while (_size > 0) pop();
            return;
        }
        if (len >= _size) return;
        Node* _node = _root;
        for (int i = 0; i < len; ++i) {
            if (i != len - 1) {
                _node = (*_node).next;
            } else {
                Node* n = (*_node).next;
                for (int j = i + 1; j < _size; ++j) {
                    if (n == null) break;
                    Node* tmp = n;
                    n = (*n).next;
                    _allocator.deallocate_vptr(tmp);
                }
                (*_node).next = null;
                _end = _node;
            }
        }
        _size = len;
        _size_limit = len;
    }

    /// Removes all elements from queue
    void clear() @nogc nothrow {
        while (_size > 0) pop();
        _root = null;
        _end = null;
        _size = 0;
    }

    /// Returns data as vector
    scope vector!T array() @nogc nothrow {
        vector!T arr;
        if (_root == null) return arr;


        Node* last = _root;

        while(true) {
            arr ~= (*last).value;
            if ((*last).next == null) break;
            last = (*last).next;
        }
        return arr;
    }
}

@nogc nothrow {
    // Unittests
    unittest {
        queue!int q = queue!int(1, 2, 3, 4);
        assert(q.size == 4);
        assert(q.pop == 1);
        assert(q.pop == 2);
        assert(q.pop == 3);
        assert(q.front == 4);
        assert(q.pop == 4);
        assert(q.size == 0);
        assert(q.pop == int.init);
    }

    unittest {
        queue!int q;
        assert(q.empty);
        assert(q.front == int.init);
        q.push(3, 2, 1);
        assert(q.front == 3);
        q ~= 3;
        q.push(2);
        assert(q.front == 3);
        assert(q.array == [3, 2, 1, 3, 2]);
    }

    unittest {
        queue!int q = queue!int(1, 2, 3, 4);
        q.clear();
        assert(q.size == 0);
        assert(q.pop == int.init);
    }

    unittest {
        queue!int q = queue!int(1, 2, 3, 4);
        q.push(5, 6, 7, 8, 9, 10);
        q.limit_length(7);
        assert(q.size == 7);
        assert(q.array == [1, 2, 3, 4, 5, 6, 7]);
    }

    unittest {
        queue!int q = queue!int(1, 2, 3, 4);
        queue!int w = q.clone();
        assert(q.array.array == w.array.array);
        w.pop();
        assert(q.array.array != w.array.array);
    }

}