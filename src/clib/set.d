// SPDX-FileCopyrightText: (C) 2023 Alisa Lain <al1-ce@null.net>
// SPDX-License-Identifier: OSL-3.0

/++
noGC compatible associative container that contains a sorted set of unique objects
+/
module clib.set;

import clib.string: memcmp;

import clib.memory;
import clib.typeinfo;

/++
Unique value container.

Default sorting order is `a > b` for non `char*` and `ctrcmp(a, b) > 0` for `char*`.
Default sorting algorithm is bubble sort.

Prefer inserting values by bulk because it sorts after each `insert` call.
++/
struct set(T, alias COMPARE = sort_function, A: IAllocator!T = allocator!T) {
    private T* _data = null;
    private A _allocator = null;

    private size_t _size = 0;
    private size_t _capacity = 0;

    /// Returns pointer to data array
    @property T* data() @nogc nothrow { return _data; }

    /// Returns array
    @property T[] array() @nogc nothrow { return _data[0.._size]; }

    /// Returns size of allocated storage space
    @property size_t capacity() @nogc nothrow { return _capacity; }

    /// Returns number of elements contained in set
    @property size_t size() @nogc nothrow { return _size; }

    /// Returns true if set is empty, i.e `size == 0`
    @property bool empty() @nogc nothrow { return _size == 0; }

    /// Returns last element or `T.init` if `size == 0`
    @property T back() @nogc nothrow { return _size == 0 ? T.init : _data[_size - 1]; }

    /// Returns first element or `T.init` if `size == 0`
    @property T front() @nogc nothrow { return _size == 0 ? T.init : _data[0]; }

    // @disable this();

    this(T[] vals...) @nogc nothrow {
        _allocator = _new!A();
        insert(vals);
    }

    ~this() @nogc nothrow { free(); }

    /// Length of set
    size_t opDollar() @nogc nothrow const { return _size; }

    /// Assigns new data to set
    void opAssign(size_t S)( T[S] p_data ) @nogc nothrow {
        clear();
        reserve(S);
        memcpy(_data, p_data.ptr, S * T.sizeof);
        _size = S;
    }

    /// Ditto
    void opOpAssign(string op: "~")(T item) @nogc nothrow { insert(item); }
    /// Ditto
    void opOpAssign(string op: "~")(T[] arr) @nogc nothrow { insert(arr); }

    /// Returns element of set
    T opIndex(size_t p_position) @nogc nothrow { return _data[p_position]; }
    /// Ditto
    T* opIndex() @nogc nothrow { return _data; }

    /// Returns slice
    T[] opSlice(size_t start, size_t end) @nogc nothrow {
        return _data[start .. end];
    }

    /// Ditto
    bool opEquals(const T[] other) const @nogc nothrow {
        if (!_size == other.length) return false;
        return memcmp(_data, other.ptr, _size * T.sizeof) == 0;
    }
    /// Ditto
    bool opEquals(size_t N)(const T[N] other) const @nogc nothrow {
        if (!_size == other.length) return false;
        return memcmp(_data, other.ptr, _size * T.sizeof) == 0;
    }

    /// Inserts values into set if `!has(val)`
    void insert(T[] vals...) @nogc nothrow {
        for (size_t i = 0; i < vals.length; ++i) {
            if (!has(vals[i])) insert_one(vals[i]);
        }
        sort();
    }

    /// Ditto
    private void insert_one(T val) @nogc nothrow {
        if (_size >= _capacity) reserve(_capacity * 2 + 2);
        _data[_size] = val;
        ++_size;
    }

    /// Returns true if set contains value
    alias has = contains;

    /// Ditto
    bool contains(T val) @nogc nothrow {
        for (size_t i = 0; i < _size; ++i) if (_data[i] == val) return true;
        return false;
    }

    /// Bubble sort (it's stable, it's simple, if you using set on large data
    /// then you better rethink your life)
    private void sort() @nogc nothrow {
        bool swapped;
        for (size_t i = 0; i <  _size - 1; ++i) {
            swapped = false;
            for (size_t j = 0; j < _size - i - 1; ++j) {
                if (COMPARE(_data[j], _data[j + 1])) {
                    T temp = _data[j];
                    _data[j] = data[j + 1];
                    _data[j + 1] = temp;
                    swapped = true;
                }
            }
            if (!swapped) break;
        }
    }

    /// Allocates memory for `p_size` elements if `p_size > capacity`
    /// Returns true on success
    bool reserve(size_t p_size) @nogc nothrow {
        if (p_size <= _capacity) return true;
        if (_allocator is null) _allocator = _new!A();

        void* newData;

        if (_data is null) {
            newData = _allocator.allocate(p_size * T.sizeof);
        } else {
            newData = _allocator.reallocate(_data, p_size * T.sizeof);
        }

        if (newData is null) return false;
        _data = cast(T*) newData;

        _capacity = p_size;

        return true;
    }

    /// Reallocates memory so that `capacity == size`.
    /// Does nothing if data is uninitialized
    /// Returns true if was successful
    bool shrink() @nogc nothrow {
        if (_size == _capacity) return true;
        if (_allocator is null) _allocator = _new!A();

        if (_data !is null) {
            void* newData;
            newData = _allocator.reallocate(_data, _size * T.sizeof);
            if (newData is null) return false;
            _data = cast(T*) newData;
            _capacity = _size;
        }

        return true;
    }

    /// Destroys vector data and sets size to 0
    void clear() @nogc nothrow {
        if (_allocator is null) _allocator = _new!A();
        void* newData = _allocator.allocate(_capacity * T.sizeof);
        if (newData is null) return;

        if (_data !is null) {
            free_data();
            _allocator.deallocate(_data);
        }

        _data = cast(T*) newData;
        _size = 0;
    }

    void free() @nogc nothrow {
        if (_data !is null) {
            free_data();
            _allocator.deallocate(_data);
        }
        if (_allocator !is null) _allocator._free();
        _data = null;
        _size = 0;
        _capacity = 0;
    }

    private void free_data() @nogc nothrow {
        if (_data !is null) {
            for (size_t i = 0; i < _size; ++i) destroy!false(_data[i]);
        }
    }
}

private bool sort_function(T)(T a, T b) @nogc nothrow {
    static if (is(T == char*)) {
        import clib.string: strcmp;
        return strcmp(a, b) > 0;
    } else {
        return a > b;
    }
}

@nogc nothrow {
    // Unittests
    unittest {
        set!int s = set!int(3, 2, 1, 4, 12, 0);
        assert(s == [0, 1, 2, 3, 4, 12]);
        assert(s.size == 6);
        assert(s.front == 0);
        assert(s.back == 12);
        s.clear();
        assert(s.empty);
        assert(s.size == 0);
    }

    unittest {
        set!int s = set!int(1, 2, 3);
        s ~= 4;
        int[2] arr = [0, -1];
        s ~= arr;
        assert(s == [-1, 0, 1, 2, 3, 4]);
    }

    unittest {
        set!int s = set!int(1, 2, 3);
        s.insert(-1, 2, 5, 6, 12);
        assert(s == [-1, 1, 2, 3, 5, 6, 12]);
        assert(s.has(1));
        assert(!s.has(15));
    }

    unittest {
        set!int s;
        s.reserve(12);
        assert(s.capacity == 12);
        assert(s.size == 0);
        s.insert(2);
        s.shrink();
        assert(s.size == 1);
        assert(s == [2]);
        assert(s.capacity == 1);
    }

    unittest {
        set!(char*) s;
        char*[5] a = [
            cast(char*)"abcd".ptr,
            cast(char*)"cbda".ptr,
            cast(char*)"dcba".ptr,
            cast(char*)"add".ptr,
            cast(char*)"remove".ptr
        ];
        s.insert(a);
        char*[5] b = [
            cast(char*)"add".ptr,
            cast(char*)"abcd".ptr,
            cast(char*)"cbda".ptr,
            cast(char*)"dcba".ptr,
            cast(char*)"remove".ptr
        ];
        import clib.string: strcmp;
        assert(strcmp(s[0], cast(char*) "abcd".ptr) == 0);
        assert(strcmp(s[1], cast(char*) "add".ptr) == 0);
    }

    unittest {
        bool revFunc(int a, int b) @nogc nothrow {return a < b;}
        set!(int, revFunc) s = set!(int, revFunc)(1, 2, 3, 5, 12, 0);
        assert(s == [12, 5, 3, 2, 1, 0]);
    }
}
