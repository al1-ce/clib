// SPDX-FileCopyrightText: (C) 2023 Alisa Lain <al1-ce@null.net>
// SPDX-License-Identifier: OSL-3.0

/// NoGC compatible LCFS container
module clib.stack;

import clib.vector;
import clib.memory;

/// LCFS container
struct stack(T, A: IAllocator!T = allocator!T) {
    private struct Node {
        T value;
        Node* next = null;
    }

    private Node* _root = null;
    private size_t _size = 0;
    private size_t _size_limit = -1;
    private A _allocator = null;

    /// Length of stack
    @property size_t size() @nogc nothrow { return _size; }

    /// Is stack empty
    @property bool empty() @nogc nothrow { return _root == null; }

    /// Returns first value without removing it from stack
    @property T front() @nogc nothrow {
        if (_root == null) return T.init;
        return (*_root).value;
    }

    /// Creates stack filled with vals
    this(T[] vals...) @nogc nothrow {
        _allocator = _new!A();
        push(vals);
    }

    this(ref scope stack!(T, A) other) @nogc nothrow {
        if (_allocator is null) _allocator = _new!A();
        Node* n = other._root;
        T* tmp = _allocator.allocate(T.sizeof * other._size);
        for (size_t i = 0; i < other._size; ++i) {
            tmp[i] = n.value;
            n = n.next;
        }
        for (size_t i = 0; i < other._size; ++i) {
            push(tmp[other._size - i - 1]);
        }
        _allocator.deallocate(tmp);
        _size = other._size;
        _size_limit = other._size_limit;
    }

    ~this() @nogc nothrow {
        while (_size > 0) pop();
        _free(_allocator);
    }

    scope stack!(T, A) clone() @nogc nothrow {
        if (_allocator is null) _allocator = _new!A();
        stack!(T, A) q;
        T* tmp = _allocator.allocate(T.sizeof * _size);
        Node* n = _root;
        for (size_t i = 0; i < _size; ++i) {
            tmp[i] = n.value;
            n = n.next;
        }
        for (size_t i = 0; i < _size; ++i) {
            q.push(tmp[_size - i - 1]);
        }
        _allocator.deallocate(tmp);
        q._size = _size;
        q._size_limit = _size_limit;
        return q;
    }


    /// opOpAssign x ~= y == x.push(y)
    void opOpAssign(string op: "~")( in T b ) @nogc nothrow {
        push(b);
    }

    /// Adds vals at end of stack (last val becomes front)
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
            ++_size;
            ++i;
        }

        for (;i < vals.length; ++i) {
            if (_size >= _size_limit) break;
            Node* ptr = cast(Node*) _allocator.allocate_vptr(Node.sizeof);
            (*ptr).value = vals[i];
            (*ptr).next = _root;
            _root = ptr;
            ++_size;
        }
    }

    /// Returns first value and removes it from stack
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
            }
        }
        _size = len;
        _size_limit = len;
    }

    /// Removes all elements from stack
    void clear() @nogc nothrow {
        while (_size > 0) pop();
        _root = null;
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

@nogc nothrow:
// Unittests

unittest {
    stack!int q = stack!int(1, 2, 3, 4);
    assert(q.size == 4);
    assert(q.pop == 4);
    assert(q.pop == 3);
    assert(q.pop == 2);
    assert(q.front == 1);
    assert(q.pop == 1);
    assert(q.size == 0);
    assert(q.pop == int.init);
}

unittest {
    stack!int q;
    assert(q.empty);
    assert(q.front == int.init);
    q.push(3, 2, 1);
    assert(q.front == 1);
    q ~= 3;
    q.push(2);
    assert(q.front == 2);
    assert(q.array == [2, 3, 1, 2, 3]);
}

unittest {
    stack!int q = stack!int(1, 2, 3, 4);
    q.clear();
    assert(q.size == 0);
    assert(q.pop == int.init);
}

unittest {
    stack!int q = stack!int(1, 2, 3, 4);
    q.push(5, 6, 7, 8, 9, 10);
    q.limit_length(7);
    assert(q.size == 7);
    assert(q.array == [10, 9, 8, 7, 6, 5, 4]);
}

unittest {
    stack!int q = stack!int(1, 2, 3, 4);
    stack!int w = q.clone();
    assert(q.array.array == w.array.array);
    w.pop();
    assert(q.array.array != w.array.array);
}

