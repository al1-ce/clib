// SPDX-FileCopyrightText: (C) 2023 Alisa Lain <al1-ce@null.net>
// SPDX-License-Identifier: OSL-3.0

/++
noGC compatible dynamic size container.

Most of functionality is taken directly from cpp's std::vector with minor changes
+/
module clib.vector;

// import clib.stdlib: free, malloc, calloc, realloc;
import clib.string: memcpy, memcmp, strcpy, strcmp;

import clib.memory;
import clib.iterator;

/// noGC compatible dynamic size container
struct vector(T, A: IAllocator!T = allocator!T) if (!is(T == bool)) {
    private T* _data = null;
    private A _allocator = null;

    private size_t _capacity = 0;
    private size_t _size = 0;

    // // See copy ctor
    // private size_t* _refCounter;

    /// Returns pointer to data array
    @property T* data() @nogc nothrow { return _data; }

    /// Returns array
    @property T[] array() @nogc nothrow { return _data[0.._size]; }

    /// Returns size of allocated storage space
    @property size_t capacity() @nogc nothrow { return _capacity; }

    /// Returns number of elements contained in vector
    @property size_t size() @nogc nothrow { return _size; }

    /// Returns true if vector is empty, i.e `size == 0`
    @property bool empty() const @nogc nothrow { return _size == 0; }

    /// Returns last element or `T.init` if `size == 0`
    @property T back() @nogc nothrow { return _size == 0 ? T.init : _data[_size - 1]; }

    /// Returns first element or `T.init` if `size == 0`
    @property T front() @nogc nothrow { return _size == 0 ? T.init : _data[0]; }

    VectorIterator!(T) begin() @nogc nothrow {
        return VectorIterator!(T)(&this, false);
    }

    VectorIterator!(T) end() @nogc nothrow {
        return VectorIterator!(T)(&this, true);
    }

    ConstVectorIterator!(T) begin() const @nogc nothrow {
        return ConstVectorIterator!(T)(&this, false);
    }

    ConstVectorIterator!(T) end() const @nogc nothrow {
        return ConstVectorIterator!(T)(&this, true);
    }

    /// Returns backward iterator to beginning (for reverse iteration)
    ReverseVectorIterator!(T) rbegin() @nogc nothrow {
        return ReverseVectorIterator!(T)(&this, false);
    }

    /// Returns backward iterator to end (for reverse iteration)
    ReverseVectorIterator!(T) rend() @nogc nothrow {
        return ReverseVectorIterator!(T)(&this, true);
    }

    /// Returns const backward iterator to beginning (for reverse iteration)
    ConstReverseVectorIterator!(T) rbegin() const @nogc nothrow {
        return ConstReverseVectorIterator!(T)(&this, false);
    }

    /// Returns const backward iterator to end (for reverse iteration)
    ConstReverseVectorIterator!(T) rend() const @nogc nothrow {
        return ConstReverseVectorIterator!(T)(&this, true);
    }

    private struct VectorIterator(T) {
        vector!(T, A)* container;
        size_t index;
        bool isEnd;

        this(vector!(T, A)* c, bool end) @nogc nothrow {
            container = c;
            isEnd = end;
            index = end ? container._size : 0;
        }

        @property bool empty() const @nogc nothrow {
            return index >= container._size;
        }

        @property ref T front() @nogc nothrow {
            return container._data[index];
        }

        void popFront() @nogc nothrow {
            ++index;
        }
    }

    private struct ConstVectorIterator(T) {
        const vector!(T, A)* container;
        size_t index;
        bool isEnd;

        this(const vector!(T, A)* c, bool end) @nogc nothrow {
            container = c;
            isEnd = end;
            index = end ? container._size : 0;
        }

        @property bool empty() const @nogc nothrow {
            return index >= container._size;
        }

        @property ref const(T) front() const @nogc nothrow {
            return container._data[index];
        }

        void popFront() @nogc nothrow {
            ++index;
        }
    }

    private struct ReverseVectorIterator(T) {
        vector!(T, A)* container;
        size_t index;
        bool isEnd;

        this(vector!(T, A)* c, bool end) @nogc nothrow {
            container = c;
            isEnd = end;
            index = end ? 0 : container._size;
        }

        @property bool empty() const @nogc nothrow {
            return index == 0;
        }

        @property ref T front() @nogc nothrow {
            return container._data[index - 1];
        }

        void popFront() @nogc nothrow {
            --index;
        }
    }

    private struct ConstReverseVectorIterator(T) {
        const vector!(T, A)* container;
        size_t index;
        bool isEnd;

        this(const vector!(T, A)* c, bool end) @nogc nothrow {
            container = c;
            isEnd = end;
            index = end ? 0 : container._size;
        }

        @property bool empty() const @nogc nothrow {
            return index == 0;
        }

        @property ref const(T) front() const @nogc nothrow {
            return container._data[index - 1];
        }

        void popFront() @nogc nothrow {
            --index;
        }
    }

    /++ Returns data pointer and clears vector
        IMPORTANT: Data pointer must be freed manually
    +/
    @property T* release() @nogc nothrow {
        T* tmp = _data;
        _data = null;
        free();
        return tmp;
    }

    /// Implements foreach support
    int opApply(scope int delegate(ref T) @nogc nothrow dg) @nogc nothrow {
        if (empty) return 0;

        auto it = begin();
        while (!it.empty) {
            if (int result = dg(it.front)) {
                return result;
            }
            it.popFront();
        }
        return 0;
    }

    /// Implements const foreach support
    int opApply(scope int delegate(ref const T) @nogc nothrow dg) const @nogc nothrow {
        if (empty) return 0;

        auto it = begin();
        while (!it.empty) {
            auto temp = it.front; // Create a temporary to get a reference
            if (int result = dg(temp)) {
                return result;
            }
            it.popFront();
        }
        return 0;
    }

    /// Implements foreach_reverse support
    int opApplyReverse(scope int delegate(ref T) @nogc nothrow dg) @nogc nothrow {
        if (empty) return 0;

        auto it = rbegin();
        while (!it.empty) {
            if (int result = dg(it.front)) {
                return result;
            }
            it.popFront();
        }
        return 0;
    }

    /// Implements const foreach_reverse support
    int opApplyReverse(scope int delegate(ref const T) @nogc nothrow dg) const @nogc nothrow {
        if (empty) return 0;

        auto it = rbegin();
        while (!it.empty) {
            auto temp = it.front; // Create a temporary to get a reference
            if (int result = dg(temp)) {
                return result;
            }
            it.popFront();
        }
        return 0;
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

    static if (is(T == char)) {
        /// Ditto
        this(string str) @nogc nothrow {
            _allocator = _new!A();
            reserve(_size + str.length + 1);
            strcpy(&_data[_size], cast(char*) str.ptr);
            _size += str.length;
        }
    }

    // Copy ctor
    this(ref scope vector!(T, A) other) @nogc nothrow {
        // // I'm just going to leave it here
        // // Make type be passed by reference
        // // Fun stuff, but probably no
        // if (other._refCounter is null) {
        //     import clib.stdlib;
        //     other._refCounter = cast(size_t*) malloc(size_t.sizeof);
        //     if (other_refCounter is null) {} // handle fail
        //     other._refCounter[0] = 1;
        // }
        // _refCounter = other._refCounter;
        // _data = other._data;
        // _size = other._size;
        // _capacity = other._capacity;
        // _refCounter[0] += 1;
        assign_copy(other._data, other._size);
    }

    ~this() @nogc nothrow {
        // // See copy ctor
        // if (_refCounter is null) return;
        // _refCounter[0] -= 1;
        // if (_refCounter[0] == 0) {
        //     import clib.stdlib: cfree = free;
        //     cfree(_refCounter);
        //     free();
        // }
        free();
    }

    /// Returns copy of this vector
    scope vector!(T, A) clone() @nogc nothrow {
        vector!(T, A) v;
        v.assign_copy(_data, _size);
        return v;
    }

    /// Returns true if vector contains value
    bool contains(T val) @nogc nothrow {
        for (int i = 0; i < _size; ++i) {
            if (_data[i] == val) return true;
        }
        return false;
    }

    /// Returns index of value or -1 (size_t.max == -1)
    size_t find(T val) @nogc nothrow {
        for (int i = 0; i < _size; ++i) {
            if (_data[i] == val) return i;
        }
        return -1;
    }

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
    void opOpAssign(string op: "~")(ref vector!T vec) @nogc nothrow { push(vec.array); }

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

    /// Returns element at given position
    ref T opIndex(size_t p_position) @nogc nothrow {
        return _data[p_position];
    }

    /// Returns element at given position (const)
    ref const(T) opIndex(size_t p_position) const @nogc nothrow {
        return _data[p_position];
    }

    /// Returns slice of vector
    T[] opIndex() @nogc nothrow {
        return _data[0 .. _size];
    }

    /// Returns slice of vector (const)
    const(T)[] opIndex() const @nogc nothrow {
        return _data[0 .. _size];
    }

    /// Returns slice
    T[] opSlice(size_t start, size_t end) @nogc nothrow {
        return _data[start .. end];
    }

    // bool opEquals(LHS, RHS)(LHS lhs, RHS rhs) const @nogc nothrow;
    /// Compares vector to value
    /// `vector!T other` is `ref` to prevent dtor() from being called
    bool opEquals(M)(ref const vector!(T, M) other) const @nogc nothrow {
        if (_data == null) return false;
        if (other._data == null) return false;
        if (other._size != _size) return false;
        return memcmp(_data, other._data, _size * T.sizeof) == 0;
    }

    /// Ditto
    bool opEquals(const T[] other) const @nogc nothrow {
        if (_data == null) return false;
        if (_size != other.length) return false;
        return memcmp(_data, other.ptr, _size * T.sizeof) == 0;
    }

    /// Ditto
    bool opEquals(size_t N)(const T[N] other) const @nogc nothrow {
        if (_data == null) return false;
        if (_size != other.length) return false;
        return memcmp(_data, other.ptr, _size * T.sizeof) == 0;
    }

    size_t toHash() const @nogc nothrow {
        if (_size == 0) return 0;

        // FNV-1a hash
        size_t hash = 0xcbf29ce484222325;  // FNV offset basis
        const(ubyte)* ptr = cast(const(ubyte)*)_data;
        size_t bytes = _size * T.sizeof;

        for (size_t i = 0; i < bytes; ++i) {
            hash ^= ptr[i];
            hash *= 0x100000001b3;  // FNV prime
        }
        return hash;
    }

    scope vector!T opBinary(string op: "~")(T other) @nogc nothrow {
        vector!T v = vector!T(_data[0.._size]);
        v ~= other;
        return v;
    }

    scope vector!T opBinary(string op: "~")(T[] other) @nogc nothrow {
        vector!T v = vector!T(_data[0.._size]);
        v ~= other;
        return v;
    }

    scope vector!T opBinary(string op: "~")(ref vector!T other) @nogc nothrow {
        vector!T v = vector!T(_data[0.._size]);
        v ~= other.array;
        return v;
    }

    scope vector!T opBinaryRight(string op: "~")(T other) @nogc nothrow {
        vector!T v = vector!T(other);
        v ~= _data[0.._size];
        return v;
    }

    scope vector!T opBinaryRight(string op: "~")(T[] other) @nogc nothrow {
        vector!T v = vector!T(other);
        v ~= _data[0.._size];
        return v;
    }

    static if (is(T == char)) {
        scope vector!char opBinary(string op: "~")(string str) @nogc nothrow {
            vector!char v;
            v ~= _data[0.._size];
            v ~= str;
            return v;
        }

        scope vector!char opBinaryRight(string op: "~")(string str) @nogc nothrow {
            vector!char v;
            v ~= str;
            v ~= _data[0.._size];
            return v;
        }
    }

    /++
    Assigns new data to vector with size and capacity set to `p_size`

    DO NOT USE ON STACK-ALLOCATED MEMORY (WILL SEGFAULT)!
    +/
    void assign_pointer( T* p_data, size_t p_size ) @nogc nothrow {
        if (_allocator is null) _allocator = _new!A();
        if (_capacity != 0 || _data !is null) _allocator.deallocate(_data);
        _size = p_size;
        _capacity = p_size;
        _data = p_data;
    }

    /// Copies data to vector and sets size and capacity to `p_size`
    void assign_copy( T* p_data, size_t p_size ) @nogc nothrow {
        if (_allocator is null) _allocator = _new!A();
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

        void* new_data;

        if (_data is null) {
            new_data = _allocator.allocate(p_size * T.sizeof);
        } else {
            new_data = _allocator.reallocate(_data, p_size * T.sizeof);
        }

        if (new_data is null) return false;
        _data = cast(T*) new_data;

        _capacity = p_size;

        return true;
    }

    /// Resizes vector to `p_size` and assigns `p_val` to new elements if `p_size > size`
    /// Returns true on success
    bool resize(size_t p_size, const T p_val = T.init) @nogc nothrow {
        if (_allocator is null) _allocator = _new!A();
        if (p_size == _size) return true;

        if (p_size > _size) {
            // Growing
            if (p_size > _capacity) {
                void* new_data = _allocator.reallocate(_data, p_size * T.sizeof);
                if (new_data is null) return false;
                _data = cast(T*) new_data;
                _capacity = p_size;
            }
            // Fill new elements
            while (_size < p_size) {
                _data[_size] = p_val;
                ++_size;
            }
        } else {
            // Shrinking
            _size = p_size;
            if (_size == 0 && _data !is null) {
                void* new_data = _allocator.reallocate(_data, _capacity * T.sizeof);
                if (new_data !is null) {
                    _data = cast(T*) new_data;
                }
            }
        }
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
    void push_front(T val) @nogc nothrow {
        if (_size >= _capacity) reserve((_capacity + 1) * 2);
        // for (size_t i = _size; i > 0; --i) _data[i] = _data[i - 1];
        memcpy(&_data[1], _data, _size * T.sizeof);
        _data[0] = val;
        ++_size;
    }

    /// Pushes new elements to beginning of vector.
    /// If `newSize > capacity` then it will `reserve(capacity * 2 + newSize + 2)`
    void push_front(T[] vals...) @nogc nothrow {
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

    /// Removes elements between `p_start` and `p_end`, including start and end
    /// If `p_end >= size` then `p_end = size - 1`
    /// If `p_end <= p_start` then it does nothing
    void erase(size_t p_start, size_t p_end) @nogc nothrow {
        if (_size == 0) return;
        if (p_end < p_start) return;
        if (p_start >= _size) return;
        if (p_end == p_start) { erase(p_start); return; }
        if (p_end >= _size) { _size = p_start + 1; return; }
        size_t diff = p_end - p_start + 1;
        size_t nmax = _size - diff;

        for (size_t i = 0; i < nmax; ++i) {
            if (p_end + i + 1 >= _size) break;
            _data[p_start + i] = _data[p_end + 1 + i];
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
            void* new_data;
            new_data = _allocator.reallocate(_data, _size * T.sizeof);
            if (new_data is null) return false;
            import std.traits;
            _data = cast(T*) new_data;
            _capacity = _size;
        }

        return true;
    }

    /// Returns first element or `T.init` if `size == 0` and removes it from vector
    T pop_front() @nogc nothrow {
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
        void* new_data = _allocator.allocate(_capacity * T.sizeof);
        if (new_data is null) return;

        if (_data !is null) {
            free_data();
            _allocator.deallocate(_data);
        }

        _data = cast(T*) new_data;
        _size = 0;
    }

    /// Destroys vector data without allocating new memory
    void free() @nogc nothrow {
        if (_allocator is null) _allocator = _new!A();
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

// Unittests
@nogc nothrow {

    // Test vector initialization from array and variadic constructor
    unittest {
        int[3] testArr;
        testArr[0] = 2; testArr[1] = 5; testArr[2] = 6;
        vector!int v = testArr;
        assert(v[0..$] == [2, 5, 6]);

        v = vector!int(1, 4, 2);
        assert(v.array == [1, 4, 2]);
    }

    // Test vector push operations and array concatenation
    unittest {
        int[3] a;
        a[0] = 1; a[1] = 2; a[2] = 3;
        vector!int v = a;
        v.push(2);
        assert(v[0..$] == [1, 2, 3, 2]);

        foreach(i; 0..3) {
            v.push(a[i]);
        }
        assert(v[0..$] == [1, 2, 3, 2, 1, 2, 3]);
    }

    // Test vector concatenation with another vector using manual pushing
    unittest {
        vector!int v;
        v.push(3); v.push(2); v.push(1);
        vector!int other;
        other.push(1); other.push(2); other.push(3);
        vector!int b = v;
        foreach(i; 0..other.size) {
            b.push(other[i]);
        }
        assert(b[0..$] == [3, 2, 1, 1, 2, 3]);
    }

    // Test vector equality and inequality comparisons
    unittest {
        vector!int a;
        a.push(1); a.push(2); a.push(3); a.push(4);
        vector!int b;
        b.push(1); b.push(2); b.push(3); b.push(4);
        assert(a == b);
        b.pop();
        b.push(5);
        assert(a != b);
    }

    // Test vector comparison with arrays and other vectors
    unittest {
        int[3] a = [1, 2, 3];
        vector!int v;
        v.push(3); v.push(2); v.push(1);
        assert(v != a);
        int[3] b = [1, 3, 2];
        assert(v != b);
        int[3] c = [3, 2, 1];
        assert(v == c);
        vector!int vb;
        vb.push(3); vb.push(2); vb.push(1);
        assert(v == vb);
        vb.clear();
        vb.push(1); vb.push(2); vb.push(3);
        assert(v != vb);
        vb.clear();
        vb.push(3); vb.push(2); vb.push(1); vb.push(0);
        assert(v != vb);
    }

    // Test vector concatenation operator
    unittest {
        vector!int v;
        v.push(3); v.push(2); v.push(1);
        vector!int other;
        other.push(1); other.push(2); other.push(3);
        vector!int b = v;
        b ~= other;
        assert(b == [3, 2, 1, 1, 2, 3]);
    }

    // Test vector initialization and assignment
    unittest {
        int[3] testArr = [2, 5, 6];
        vector!int v = testArr;
        assert(v[0..$] == [2, 5, 6]);

        v = vector!int(1, 4, 2);
        assert(v.array == [1, 4, 2]);
    }

    // Test clear operation and capacity preservation
    unittest {
        vector!int v;
        int[5] init_data;
        init_data[0] = 1; init_data[1] = 2; init_data[2] = 3;
        init_data[3] = 4; init_data[4] = 5;
        v = init_data;

        // Test basic clear
        size_t oldCapacity = v.capacity;
        v.clear();
        assert(v.empty);
        assert(v.size == 0);
        assert(v.capacity == oldCapacity); // Clear shouldn't change capacity

        // Test clear on empty vector
        v.clear();
        assert(v.empty);
        assert(v.size == 0);
        assert(v.capacity == oldCapacity);

        // Test clear after operations
        v.push(42);
        v.clear();
        assert(v.empty);
        assert(v.size == 0);
    }

    // Test resize and reserve operations
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

    // Test front and back accessors
    unittest {
        int[3] a = [1, 2, 3];
        vector!int v = a;
        assert(v.front == 1);
        assert(v.back == 3);
        v.push(4, 5);
        assert(v.array == [1, 2, 3, 4, 5]);
        v.push_front(0);
        assert(v.array == [0, 1, 2, 3, 4, 5]);
        v.push_front(-2, -1);
        assert(v.array == [-2, -1, 0, 1, 2, 3, 4, 5]);
    }

    // Test erase operations
    unittest {
        vector!char c = "words are not enough";
        c.erase(9, 12);
        assert(c.array == "words are enough", c.array);
        vector!int v = vector!int(0, 1, 2, 3, 4, 5, 6);
        v.erase(3, 4);
        assert(v.array == [0, 1, 2, 5, 6]);
        assert(v.size == 5);
        vector!int q = vector!int(0, 1, 2, 3, 4, 5, 6, 7, 8);
        q.erase(2, 5);
        assert(q.array == [0, 1, 6, 7, 8]);
        assert(q.size == 5);
        q.erase(0, 1);
        assert(q.array == [6, 7, 8]);
        assert(q.size == 3);
        q.erase(1, 2);
        assert(q.array == [6]);
        assert(q.size == 1);

    }

    // Test shrink operation
    unittest {
        vector!int v = vector!int(0, 1, 2, 3, 4, 5, 6);
        assert(v.reserve(20));
        assert(v.shrink());
        assert(v.size == 7);
    }

    // Test pop operations
    unittest {
        vector!int v = vector!int(0, 1, 2, 3, 4, 5, 6);
        v.pop();
        v.pop_front();
        assert(v.array == [1, 2, 3, 4, 5]);
        v.clear();
        assert(v.pop_front() == int.init);
        assert(v.pop() == int.init);
        assert(v.size == 0);
    }

    // Test insert operation
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

    // Test swap operation
    unittest {
        vector!int va = vector!int(0, 1);
        vector!int vb = vector!int(2, 3);
        va.swap(&vb);
        assert(va.array == [2, 3]);
        assert(vb.array == [0, 1]);
    }

    // Test const iteration
    unittest {
        // Test empty const vector
        vector!int temp;
        const vector!int empty = temp;
        assert(empty.empty);
        size_t count = 0;
        foreach(e; empty) count++;
        assert(count == 0);

        // Test non-empty const vector
        vector!int m;
        m.push(42);
        const vector!int v = m;
        assert(!v.empty);
        count = 0;
        foreach(e; v) {
            assert(e == 42);
            count++;
        }
        assert(count == 1);

        // Test const reverse iteration
        count = 0;
        foreach_reverse(e; v) {
            assert(e == 42);
            count++;
        }
        assert(count == 1);
    }

    // Test hash function
    unittest {
        vector!int v1;
        v1.push(1); v1.push(2); v1.push(3);

        vector!int v2;
        v2.push(1); v2.push(2); v2.push(3);

        vector!int v3;
        v3.push(3); v3.push(2); v3.push(1);

        assert(v1.toHash() == v2.toHash());
        assert(v1.toHash() != v3.toHash());

        // Hash should remain stable after operations
        size_t hash = v1.toHash();
        v1.push(4);
        v1.pop();
        assert(v1.toHash() == hash);
    }

    // Test string operations
    unittest {
        vector!char v = "testing man";
        assert(v == "testing man");
    }

    // Test string concatenation
    unittest {
        vector!char v;
        v ~= "test";
        char[4] t = ['t', 'e', 's', 't'];
        assert(v == t);
        assert(v == "test");
    }

    // Test string concatenation with operator
    unittest {
        vector!char v = "no ";
        vector!char n = v ~ "test";
        assert(n == "no test");
        n = "there is " ~ n ~ " at all";
        assert(n == "there is no test at all");
    }

    // Test null-terminated string
    unittest {
        vector!char v = "test";
        char[5] a = ['t', 'e', 's', 't', '\0'];
        import clib.string: strcmp;
        assert(strcmp(v.stringz.data, a.ptr) == 0);
        char* sz = v.stringz.release();
        assert(strcmp(sz, a.ptr) == 0);
        import clib.stdlib;
        free(sz);
    }

    // Test iterators
    unittest {
        // Test iterators
        vector!int v;
        v.reserve(5);
        v.push(1);
        v.push(2);
        v.push(3);
        v.push(4);
        v.push(5);

        // Test forward iteration with begin/end
        {
            auto it = v.begin();
            assert(!it.empty);
            assert(it.front == 1);
            it.popFront();
            assert(it.front == 2);
        }

        // Test reverse iteration with rbegin/rend
        {
            auto rit = v.rbegin();
            assert(!rit.empty);
            assert(rit.front == 5);
            rit.popFront();
            assert(rit.front == 4);
        }

        // Test foreach iteration
        {
            int i = 1;
            foreach (ref val; v) {
                assert(val == i);
                ++i;
            }
        }

        // Test const iteration
        {
            const cv = v;
            int i = 1;
            foreach (ref const val; cv) {
                assert(val == i);
                ++i;
            }
        }
    }

    // Test empty vector behavior
    unittest {
        vector!int v;
        assert(v.empty);
        assert(v.size == 0);
        assert(v.capacity == 0);
        assert(v.front == int.init);
        assert(v.back == int.init);
        assert(v.toHash() == 0);
    }

    // Test single element operations
    unittest {
        vector!int v;
        v.push(42);
        assert(!v.empty);
        assert(v.size == 1);
        assert(v.front == 42);
        assert(v.back == 42);

        // Test pop on single element
        v.pop();
        assert(v.empty);
        assert(v.size == 0);
    }

    // Test capacity growth
    unittest {
        vector!int v;
        v.reserve(4);
        assert(v.capacity == 4);
        assert(v.size == 0);

        // Fill to capacity
        v.push(1);
        v.push(2);
        v.push(3);
        v.push(4);
        assert(v.size == 4);
        assert(v.capacity == 4);

        // Test growth beyond capacity
        v.push(5);
        assert(v.size == 5);
        assert(v.capacity > 4);
    }

    // Test clear behavior
    unittest {
        vector!int v;
        int[5] data;
        data[0] = 1; data[1] = 2; data[2] = 3; data[3] = 4; data[4] = 5;
        v = data;

        // Test basic clear
        size_t oldCapacity = v.capacity;
        v.clear();
        assert(v.empty);
        assert(v.size == 0);
        assert(v.capacity == oldCapacity); // Clear shouldn't change capacity
    }

    // Test resize behavior
    unittest {
        vector!int v;

        // Resize larger
        v.resize(3, 42);
        assert(v.size == 3);
        assert(v[0] == 42 && v[1] == 42 && v[2] == 42);

        // Resize smaller
        v.resize(1);
        assert(v.size == 1);
        assert(v[0] == 42);

        // Resize to zero
        v.resize(0);
        assert(v.empty);
    }

    // Test slice operations
    unittest {
        vector!int v;
        int[5] data;
        data[0] = 1; data[1] = 2; data[2] = 3; data[3] = 4; data[4] = 5;
        v = data;

        // Full slice
        assert(v[0..$] == [1, 2, 3, 4, 5]);

        // Partial slice
        assert(v[1..4] == [2, 3, 4]);

        // Empty slice
        assert(v[2..2].length == 0);
    }

    // Test concatenation with empty vector
    unittest {
        vector!int v;
        vector!int other;
        vector!int result;

        // Empty + Empty
        result = v;
        foreach(i; 0..other.size) {
            result.push(other[i]);
        }
        assert(result.empty);

        // Empty + Non-empty
        other.push(1);
        result = v;
        foreach(i; 0..other.size) {
            result.push(other[i]);
        }
        assert(result.size == 1);
        assert(result[0] == 1);

        // Non-empty + Empty
        v.push(2);
        result = v;
        other.clear();
        foreach(i; 0..other.size) {
            result.push(other[i]);
        }
        assert(result.size == 1);
        assert(result[0] == 2);
    }
}