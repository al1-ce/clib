/++
betterC compatible dynamic size container.

Most of functionality is taken directly from cpp's std::vector with minor changes
+/
module clib.vector;

// import core.stdc.stdlib: free, malloc, calloc, realloc;
import core.stdc.string: memcpy, memcmp, strcpy, strcmp;

import clib.memory;

/// betterC compatible dynamic size container
struct vector(T, A: IAllocator!T = allocator!T) if (!is(T == bool)) {
    private T* _data = null;
    private A _allocator = null;

    size_t _capacity = 0;
    size_t _size = 0;

    /// Returns pointer to data array
    @property T* data() @nogc nothrow { return _data; }

    /// Ditto
    alias ptr = data;

    /// Returns array
    @property T[] array() @nogc nothrow { return _data[0.._size]; }

    /// Returns size of allocated storage space
    @property size_t capacity() @nogc nothrow { return _capacity; }

    /// Returns number of elements contained in vector
    @property size_t size() @nogc nothrow { return _size; }

    /// Ditto
    alias length = size;

    /// Returns true if vector is empty, i.e `size == 0`
    @property bool empty() @nogc nothrow { return _size == 0; }

    /// Returns last element or `T.init` if `size == 0`
    @property T back() @nogc nothrow { return _size == 0 ? T.init : _data[_size - 1]; }

    /// Returns first element or `T.init` if `size == 0`
    @property T front() @nogc nothrow { return _size == 0 ? T.init : _data[0]; }

    /++ Returns data pointer and clears vector
        IMPORTANT: Data pointer must be freed manually
    +/
    @property T* steal() @nogc nothrow {
        T* tmp = _data;
        _data = null;
        clear();
        return tmp;
    }

    static if (is(T == char)) {
        /// Returns null-terminated string
        @property vector!char stringz() @nogc nothrow {
            vector!char v = _data[0.._size];
            v ~= '\0';
            return v;
        }
    }

    // @disable this();

    /++
    Constructs new vector with data
    Example:
    ---
    vector!int v1 = vector!int(2, 1); // [ 2, 1 ]
    int[2] array = [1, 2];
    vector!int v2 = array; // [ 1, 2 ]
    ---
    +/
    this(T[] p_data...) @nogc nothrow {
        _allocator = _new!A();
        reserve(p_data.length);
        _size = p_data.length;
        _capacity = p_data.length;
        memcpy(_data, p_data.ptr, p_data.length * T.sizeof);
    }

    /// Ditto
    this(S)(T[S] p_data...) @nogc nothrow {
        _allocator = _new!A();
        reserve(S);
        _size = S;
        _capacity = S;
        memcpy(_data, p_data.ptr, p_data.length * T.sizeof);
    }

    /// Ditto
    this(T* p_data, size_t p_size) {
        _allocator = _new!A();
        assign(p_data, p_size);
    }

    static if (is(T == char)) {
        /// Ditto
        this(string str) @nogc nothrow {
            _allocator = _new!A();
            reserve(_size + str.length + 1);
            strcpy(&_data[_size], cast(char*) str.ptr);
            _size += str.length;
        }
    }

    ~this() @nogc nothrow { free(); }

    /// Length of vector
    size_t opDollar() @nogc nothrow const { return _size; }

    /// Assigns new data to vector
    void opAssign(size_t S)( T[S] p_data ) @nogc nothrow {
        clear();
        reserve(S);
        memcpy(_data, p_data.ptr, S * T.sizeof);
        _size = S;
    }

    /// Assigns new data to vector
    void opAssign( T p_val ) @nogc nothrow {
        size_t S = _size;
        clear();
        resize(S, p_val);
        _size = S;
    }

    /// Ditto
    void opOpAssign(string op: "~")(T item) @nogc nothrow { push(item); }
    /// Ditto
    void opOpAssign(string op: "~")(T[] arr) @nogc nothrow { push(arr); }
    /// Ditto
    void opOpAssign(string op: "~")(vector!T vec) @nogc nothrow { push(vec.array); }

    static if (is(T == char)) {
        /// Ditto
        void opOpAssign(string op: "~")(string arr) @nogc nothrow {
            reserve(_size + arr.length + 1);
            strcpy(&_data[_size], cast(char*) arr.ptr);
            _size += arr.length;
        }
    }

    /// Ditto
    void opIndexAssign(T val, size_t index) @nogc nothrow { _data[index] = val; }
    /// Ditto
    void opIndexAssign(T val) @nogc nothrow { _data[0 .. _size] = val; }

    /// Returns element of vector
    T opIndex(size_t p_position) @nogc nothrow { return _data[p_position]; }
    /// Ditto
    T* opIndex() @nogc nothrow { return _data; }

    /// Returns slice
    T[] opSlice(size_t start, size_t end) @nogc nothrow {
        return _data[start .. end];
    }

    // bool opEquals(LHS, RHS)(LHS lhs, RHS rhs) const @nogc nothrow;
    /// Compares vector to value
    /// `vector!T other` is `ref` to prevent dtor() from being called
    bool opEquals(M)(ref vector!(T, M) other) const @nogc nothrow {
        if (_data == null) return false;
        if (other._data == null) return false;
        if (other._size != _size) return false;
        return memcmp(_data, other._data, _size * T.sizeof) == 0;
    }
    /// Ditto
    bool opEquals(T[] other) const @nogc nothrow {
        if (_data == null) return false;
        if (_size != other.length) return false;
        return memcmp(_data, other.ptr, _size * T.sizeof) == 0;
    }
    /// Ditto
    bool opEquals(size_t N)(T[N] other) const @nogc nothrow {
        if (_data == null) return false;
        if (_size != other.length) return false;
        return memcmp(_data, other.ptr, _size * T.sizeof) == 0;
    }

    // TODO: possibly opBinary(~) since ref seems to work

    vector!T opBinary(string op: "~")(T other) @nogc nothrow {
        vector!T v = vector!T(_data[0.._size]);
        v ~= other;
        return v;
    }

    vector!T opBinary(string op: "~")(T[] other) @nogc nothrow {
        vector!T v = vector!T(_data[0.._size]);
        v ~= other;
        return v;
    }

    vector!T opBinary(string op: "~")(ref vector!T other) @nogc nothrow {
        vector!T v = vector!T(_data[0.._size]);
        v ~= other.array;
        return v;
    }

    vector!T opBinaryRight(string op: "~")(T other) @nogc nothrow {
        vector!T v = vector!T(other);
        v ~= _data[0.._size];
        return v;
    }

    vector!T opBinaryRight(string op: "~")(T[] other) @nogc nothrow {
        vector!T v = vector!T(other);
        v ~= _data[0.._size];
        return v;
    }

    static if (is(T == char)) {
        vector!char opBinary(string op: "~")(string str) @nogc nothrow {
            vector!char v;
            v ~= _data[0.._size];
            v ~= str;
            return v;
        }

        vector!char opBinaryRight(string op: "~")(string str) @nogc nothrow {
            vector!char v;
            v ~= str;
            v ~= _data[0.._size];
            return v;
        }
    }

    /// Assigns new data to vector with size and capacity set to `p_size`
    void assign( T* p_data, size_t p_size ) @nogc nothrow {
        resize(p_size);
        _size = p_size;
        _capacity = p_size;
        memcpy(_data, p_data, p_size * T.sizeof);
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

    /// Resizes vector to `p_size` and assigns `p_val` to new elements if `p_size > size`
    /// Returns true on success
    bool resize(size_t p_size, const T p_val = T.init) @nogc nothrow {
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

        if (p_size > _size) {
            while (_size < _capacity) push(p_val);
        }

        _size = p_size;

        return true;
    }

    /// Pushes new element to the end of vector.
    /// If `newSize + 1 >= capacity` then it will `reserve(capacity * 2 + 2)`
    void push(T val) @nogc nothrow {
        if (_size >= _capacity) reserve(_capacity * 2 + 2);
        _data[_size] = val;
        ++_size;
    }

    /// Ditto
    void push(T[] arr...) @nogc nothrow {
        foreach (i; arr) push(i);
    }

    /// Pushes new element to beginning of vector.
    /// If `newSize + 1 > capacity` then it will `reserve(capacity * 2 + 2)`
    void pushFront(T val) @nogc nothrow {
        if (_size >= _capacity) reserve((_capacity + 1) * 2);
        // for (size_t i = _size; i > 0; --i) _data[i] = _data[i - 1];
        memcpy(&_data[1], _data, _size * T.sizeof);
        _data[0] = val;
        ++_size;
    }

    /// Pushes new elements to beginning of vector.
    /// If `newSize > capacity` then it will `reserve(capacity * 2 + newSize + 2)`
    void pushFront(T[] vals...) @nogc nothrow {
        if (_size + vals.length >= _capacity) reserve(_capacity * 2 + vals.length + 2);
        memcpy(&_data[vals.length], _data, _size * T.sizeof);
        memcpy(_data, vals.ptr, vals.length * T.sizeof);
        // for (size_t i= _size; i > 0; --i) _data[i + val.length - 1] = _data[i - 1];
        // for (size_t i = 0; i < val.length; ++i) _data[i] = val[i];
        _size += vals.length;
    }

    /// Removes element at `pos`
    /// If `pos >= size` then it will do nothing
    void erase(size_t pos) @nogc nothrow {
        if (_size == 0) return;
        if (pos >= _size) return;
        for (size_t i = pos; i < _size - 1; ++i) {
            _data[i] = _data[i + 1];
        }
        --_size;
    }

    /// Removes elements between `p_start` and `p_end`, including `p_end`
    /// If `p_end >= size` then `p_end = size - 1`
    /// If `p_end <= p_start` then it does nothing
    void erase(size_t p_start, size_t p_end) @nogc nothrow {
        if (_size == 0) return;
        if (p_end >= _size) p_end = _size - 1;
        if (p_end <= p_start) return;
        if (p_end == _size - 1) {_size = p_start + 1; return;}
        size_t diff = p_end - p_start;

        for (size_t i = 1; i < diff + 1; ++i) {
            if (p_end + i >= _size) break;
            _data[p_start + i] = _data[p_end + i];
        }

        _size -= diff;
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

    /// Returns first element or `T.init` if `size == 0` and removes it from vector
    T popFront() @nogc nothrow {
        if (_size == 0) return T.init;
        T val = _data[0];
        erase(0);
        return val;
    }

    /// Returns last element or `T.init` if `size == 0` and removes it from vector
    T pop() @nogc nothrow {
        if (_size == 0) return T.init;
        --_size;
        return _data[_size];
    }

    /// Inserts value into vector at `p_pos`
    /// If `newSize + 1 >= capacity` then it will `reserve((capacity + 1) * 2)`
    /// If `p_pos >= size` then it will do nothing (use `push()` instead)
    void insert(size_t p_pos, T p_val) @nogc nothrow {
        if (p_pos >= _size) return;
        if (_size >= _capacity) reserve((_capacity + 1) * 2);
        for (size_t i = _size; i > p_pos; --i) _data[i] = _data[i - 1];
        _data[p_pos] = p_val;
        ++_size;
    }

    /// Swaps contents with another vector
    void swap(vector!T* p_vec) @nogc nothrow {
        T* pd = p_vec._data;
        size_t ps = p_vec._size;
        size_t pc = p_vec._capacity;
        p_vec._data = _data;
        p_vec._size = _size;
        p_vec._capacity = _capacity;
        _data = pd;
        _size = ps;
        _capacity = pc;
    }

    /// Destroys vector data and sets size to 0
    void clear() @nogc nothrow {
        if (_allocator is null) _allocator = _new!A();
        void* newData = _allocator.allocate(_capacity * T.sizeof);
        if (newData is null) return;

        if (_data !is null) {
            freeData();
            _allocator.deallocate(_data);
        }

        _data = cast(T*) newData;
        _size = 0;
    }

    /// Destroys vector data without allocating new memory
    void free() @nogc nothrow {
        if (_allocator is null) _allocator = _new!A();
        if (_data !is null) {
            freeData();
            _allocator.deallocate(_data);
        }
        if (_allocator !is null) _allocator._free();
        _data = null;
        _size = 0;
        _capacity = 0;
    }

    private void freeData() @nogc nothrow {
        if (_data !is null) {
            for (size_t i = 0; i < _size; ++i) destroy!false(_data[i]);
        }
    }
}

// Unittests
// TODO: more edge cases
@nogc nothrow:

unittest {
    int[3] testArr = [2, 5, 6];
    vector!int v = testArr;
    assert(v[0..$] == [2, 5, 6]);

    v = vector!int(1, 4, 2);
    assert(v.array == [1, 4, 2]);
}

unittest {
    int[3] a = [1, 2, 3];
    vector!int v = a;
    v ~= 2;
    assert(v[0..$] == [1, 2, 3, 2]);
    v ~= a;
    assert(v[0..$] == [1, 2, 3, 2, 1, 2, 3]);
}

unittest {
    int[3] a = [1, 2, 3];
    vector!int v = a;
    assert(v[1] == 2);
    v[1] = 4;
    assert(v[0..$] == [1, 4, 3]);
    v = 2;
    assert(v[0..$] == [2, 2, 2]);
}

unittest {
    int[3] a = [1, 2, 3];
    vector!int v = vector!int(3, 2, 1);
    assert(v != a);
    assert(v != [1, 3, 2]);
    assert(v == [3, 2, 1]);
    vector!int vb = vector!int(3, 2, 1);
    assert(v == vb);
    vb = vector!int(1, 2, 3);
    assert(v != vb);
    vb = vector!int(3, 2, 1, 0);
    assert(v != vb);
}

unittest {
    int[3] a = [1, 2, 3];
    vector!int v = vector!int(3, 2, 1);
    vector!int b = v ~ a;
    assert(b == [3, 2, 1, 1, 2, 3]);
    b = a ~ v;
    assert(b == [1, 2, 3, 3, 2, 1]);
    b = a;
    b = v ~ b;
    assert(b == [3, 2, 1, 1, 2, 3]);
}

unittest {
    import core.stdc.string;
    int[4] data = [1, 2, 3, 4];
    vector!int v;
    v.assign(data.ptr, 4);
    assert(v[0..$] == [1, 2, 3, 4]);

    vector!int k = vector!int(data.ptr, 4);
    assert(v[0..$] == [1, 2, 3, 4]);
}

unittest {
    int[3] a = [1, 2, 3];
    vector!int v = a;
    assert(v.size == 3);

    assert(v.resize(6));
    assert(v.size == 6);

    assert(v.reserve(12));
    assert(v.capacity == 12);
    assert(v.size == 6);
}

unittest {
    int[3] a = [1, 2, 3];
    vector!int v = a;
    assert(v.front == 1);
    assert(v.back == 3);
    v.push(4, 5);
    assert(v.array == [1, 2, 3, 4, 5]);
    v.pushFront(0);
    assert(v.array == [0, 1, 2, 3, 4, 5]);
    v.pushFront(-2, -1);
    assert(v.array == [-2, -1, 0, 1, 2, 3, 4, 5]);
}

unittest {
    vector!int v = vector!int(0, 1, 2, 3, 4, 5, 6);
    v.erase(2, 4);
    assert(v.array == [0, 1, 2, 5, 6]);
    assert(v.size == 5);
}

unittest {
    vector!int v = vector!int(0, 1, 2, 3, 4, 5, 6);
    assert(v.reserve(20));
    assert(v.shrink());
    assert(v.size == 7);
}

unittest {
    vector!int v = vector!int(0, 1, 2, 3, 4, 5, 6);
    v.pop();
    v.popFront();
    assert(v.array == [1, 2, 3, 4, 5]);
    v.clear();
    assert(v.popFront() == int.init);
    assert(v.pop() == int.init);
    assert(v.size == 0);
}

unittest {
    vector!int v = vector!int(0, 1, 2, 3);
    v.insert(2, 12);
    assert(v.array == [0, 1, 12, 2, 3]);
    v.insert(0, 13);
    assert(v.array == [13, 0, 1, 12, 2, 3]);
    v.insert(v.size - 1, 14);
    assert(v.array == [13, 0, 1, 12, 2, 14, 3]);
    v.insert(v.size, 15);
    assert(v.array == [13, 0, 1, 12, 2, 14, 3]);
}

unittest {
    vector!int va = vector!int(0, 1);
    vector!int vb = vector!int(2, 3);
    va.swap(&vb);
    assert(va.array == [2, 3]);
    assert(vb.array == [0, 1]);
}

unittest {
    vector!int v = vector!int(0);
    v.clear();
    assert(v.size == 0);
    assert(v.capacity == 1);
}

unittest {
    vector!char v = "testing man";
    assert(v == "testing man");
}

unittest {
    vector!char v;
    v ~= "test";
    char[4] t = ['t', 'e', 's', 't'];
    assert(v == t);
    assert(v == "test");
}

unittest {
    vector!char v = "no ";
    vector!char n = v ~ "test";
    assert(n == "no test");
    n = "there is " ~ n ~ " at all";
    assert(n == "there is no test at all");
}

unittest {
    vector!char v = "test";
    char[5] a = ['t', 'e', 's', 't', '\0'];
    import core.stdc.string: strcmp;
    assert(strcmp(v.stringz.ptr, a.ptr) == 0);
    char* sz = v.stringz.steal;
    assert(strcmp(sz, a.ptr) == 0);
    import core.stdc.stdlib;
    free(sz);
}

