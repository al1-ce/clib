// SPDX-FileCopyrightText: (C) 2023 Alisa Lain <al1-ce@null.net>
// SPDX-License-Identifier: OSL-3.0

/++
Utilities for memory management
+/
module clib.memory;

import clib.stdlib: malloc, realloc, free;

mixin template DISABLE_GC() {
    extern(C) __gshared string[] rt_options = [ "gcopt=disable:1" ];
}

/++
Used to allocate/deallocate memory for classes

Example:
---
class NoGCClass {
    this(int p_a) { a = p_a; }
    int a;
}

void main() @nogc {
    NoGCClass nogcClass = _new!NoGCClass(2);
    _free(cppClass);
}
---
+/
T _new(T, Args...)(auto ref Args args) @nogc nothrow {
    // Taken from lsferreira classes betterc d
    enum tsize = __traits(classInstanceSize, T);
    // Magic memory allocation
    T t = () @trusted {
        import core.memory : pureMalloc;
        auto _t = cast(T) pureMalloc(tsize);
        if (_t is null) return null;
        import clib.string : memcpy;
        // Copies initial state of T (initSymbol -> const(void)[]) into _t
        memcpy(cast(void*) _t, __traits(initSymbol, T).ptr, tsize);
        return _t;
    }();
    if (t is null) return null;

    import core.lifetime : forward;
    // Actual construction
    static if (__traits(hasMember, T, "__ctor")) t.__ctor(forward!args);
    return t;
}

/// Ditto
void _free(T)(ref T t) @nogc nothrow {
    // If there's ~this we wanna call it
    static if (__traits(hasMember, T, "__xdtor")) t.__xdtor();
    import core.memory : pureFree;
    pureFree(cast(void*) t);
    // And if T is nullable then make it null
    static if (__traits(compiles, { t = null; })) t = null;
}

/// Default allocator
alias allocator = Mallocator;

/// Unmanaged allocator (a wrapper over malloc)
class Mallocator(T): IAllocator!T if (IS_VALID_ALLOCATOR_TYPE!T()) {

    /// Allocator has no state
    this() @nogc nothrow {}
    /// Ditto
    ~this() @nogc nothrow {}

    /// Allocates new chunk of memory
    T* allocate(const size_t size, const size_t alignment = 0) @nogc nothrow {
        return cast(T*) allocate_vptr(size, alignment);
    }

    /// Ditto
    void* allocate_vptr(const size_t size, const size_t alignment = 0) @nogc nothrow {
        return malloc(size);
    }

    /// Reallocates memory
    T* reallocate(T* ptr, const size_t size, const size_t alignment = 0) @nogc nothrow {
        return cast(T*) reallocate_vptr(cast(void*) ptr, size, alignment);
    }

    /// Ditto
    void* reallocate_vptr(void* ptr, const size_t size, const size_t alignment = 0) @nogc nothrow {
        return realloc(ptr, size);
    }

    /// Deallocates memory
    void deallocate(T* memory) @nogc nothrow {
        free(cast(void*) memory);
    }

    /// Ditto
    void deallocate_vptr(void* memory) @nogc nothrow {
        free(memory);
    }
}

interface IAllocator(T) {
    /// Allocates new chunk of memory
    T* allocate(const size_t size, const size_t alignment = 0) @nogc nothrow;
    /// Ditto
    void* allocate_vptr(const size_t size, const size_t alignment = 0) @nogc nothrow;
    /// Reallocates memory
    T* reallocate(T* ptr, const size_t size, const size_t alignment = 0) @nogc nothrow;
    /// Ditto
    void* reallocate_vptr(void* ptr, const size_t size, const size_t alignment = 0) @nogc nothrow;
    /// Deallocates memory
    void deallocate(T* ptr) @nogc nothrow;
    /// Ditto
    void deallocate_vptr(void* ptr) @nogc nothrow;
}

private bool IS_VALID_ALLOCATOR_TYPE(T)() @nogc nothrow {
    return !is(T == const) && !is(T == immutable);
}

