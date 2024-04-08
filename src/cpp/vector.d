/++
betterC compatible dynamic size container.

Most of functionality is taken directly from cpp's std::vector with minor changes
+/
module cpp.vector;

// import core.stdc.stdlib: free, malloc, calloc, realloc;
import core.stdc.string: memcpy;

import cpp.allocator;
import cpp.classes;

/// betterC compatible dynamic size container
alias vector = CppVector;

/// Ditto
private struct CppVector(T, A = allocator!T) if (!is(T == bool)) {
    private T* _data = null;
    private A _allocator = null;

    size_t _capacity = 0;
    size_t _size = 0;

    /// Returns pointer to data array
    @property T* data() @nogc nothrow { return _data; }

    /// Returns size of allocated storage space
    @property size_t capacity() @nogc nothrow { return _capacity; }

    /// Returns number of elements contained in vector
    @property size_t size() @nogc nothrow { return _size; }

    /// Returns true if vector is empty, i.e `size == 0`
    @property bool empty() @nogc nothrow { return _size == 0; }

    /// Returns last element or `T.init` if `size == 0`
    @property T back() @nogc nothrow { return _size == 0 ? T.init : _data[_size - 1]; }

    /// Returns first element or `T.init` if `size == 0`
    @property T front() @nogc nothrow { return _size == 0 ? T.init : _data[0]; }

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
    this(T[] p_data1, T[] p_data2) @nogc nothrow {
        _allocator = _new!A();
        size_t S1 = p_data1.length;
        size_t S2 = p_data2.length;
        reserve(S1 + S2 - 1);
        _size = S1 + S2 - 1;
        _capacity = S1 + S2 - 1;
        memcpy(_data, p_data1.ptr, S1 * T.sizeof);
        memcpy(&_data[S1], p_data2.ptr, S2 * T.sizeof);
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
    /// Ditto
    void opOpAssign(string op: "~")(T item) @nogc nothrow { push(item); }
    /// Ditto
    void opOpAssign(string op: "~")(T[] arr) @nogc nothrow { push(arr); }

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
    void push(T[] arr) @nogc nothrow {
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
    void erase(size_t pos) @nogc nothrow {
        for (size_t i = pos; i < _size - 1; ++i) {
            _data[i] = _data[i + 1];
        }
        --_size;
    }

    /// Removes elements between `p_start` and `p_end`
    void erase(size_t p_start, size_t p_end) @nogc nothrow {
        if (p_end <= p_start) return;
        size_t diff = p_end - p_start + 1;

        for (size_t i = 1; i < diff + 1; ++i) {
            _data[p_start + i] = _data[p_end + i + 1];
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
    void insert(size_t p_pos, T p_val) @nogc nothrow {
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
