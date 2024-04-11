/++
A simple allocator. Allows for custom custom allocators to be used with some cpp types.

All allocators must have same "signature" as `allocator`
+/
module clib.memory;

import core.stdc.stdlib: malloc, realloc, free;

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

    // Obviously get size of class instance
    enum tsize = __traits(classInstanceSize, T);

    // Magic memory allocation
    T t = () @trusted {
        import core.memory : pureMalloc;

        // Allocate memory
        auto _t = cast(T) pureMalloc(tsize);
        if (!_t) return null;

        import core.stdc.string : memcpy;

        // Copies initial state of T (initSymbol -> const(void)[]) into _t
        memcpy(cast(void*) _t, __traits(initSymbol, T).ptr, tsize);

        return _t;
    }();
    if (!t) return null;

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

    // Just freeing memory
    pureFree(cast(void*) t);

    // And if T is nullable then make it null
    static if (__traits(compiles, { t = null; })) t = null;
}

/// Default allocator
alias allocator = Mallocator;

/// Unmanaged allocator (a wrapper over malloc)
extern(C++) class Mallocator(T): IAllocator!T if (isValidAlloccatorType!T()) {

    /// Allocator has no state
    this() @nogc nothrow {}

    /// Ditto
    ~this() @nogc nothrow {}

    /// Allocates new chunk of memory
    T* allocate(const size_t size, const size_t alignment = 0) @nogc nothrow {
        void* memory = malloc(size);
        return cast(T*) memory;
    }

    /// Reallocates memory
    T* reallocate(T* ptr, const size_t size, const size_t alignment = 0) @nogc nothrow {
        void* memory = realloc(ptr, size);
        return cast(T*) memory;
    }

    /// Deallocates memory
    void deallocate(T* memory) @nogc nothrow {
        free(cast(void*) memory);
    }
}

extern(C++) interface IAllocator(T) {
    T* allocate(const size_t, const size_t) @nogc nothrow;
    T* reallocate(T*, const size_t, const size_t) @nogc nothrow;
    void deallocate(T*) @nogc nothrow;
}

private bool isValidAlloccatorType(T)() @nogc nothrow {
    return !is(T == const) && !is(T == immutable) && !is(T == class);
}

