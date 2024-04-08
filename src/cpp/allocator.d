/++
A simple allocator. Allows for custom custom allocators to be used with some cpp types.

All allocators must have same `signature` as CppAllocatorUnmanaged
+/
module cpp.allocator;

import core.stdc.stdlib: malloc, realloc, free;

/// Default unmanaged allocator (a wrapper over malloc)
alias allocator = CppAllocatorUnmanaged;

/// Ditto
extern(C++) private class CppAllocatorUnmanaged(T) if (isValidAlloccatorType!T()) {

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
    void deallocate(void* memory) @nogc nothrow {
        free(memory);
    }
}

private bool isValidAlloccatorType(T)() @nogc nothrow {
    return !is(T == const) && !is(T == immutable) && !is(T == class);
}
