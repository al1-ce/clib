/++
A simple allocator. Allows for custom custom allocators to be used with some cppd types.

All allocators must have same `signature` as CppAllocatorUnmanaged
+/
module cppd.allocator;

import core.stdc.stdlib: malloc, realloc, free;

/// Default unmanaged allocator (a wrapper over malloc)
alias allocator = CppAllocatorUnmanaged;

/// Ditto
extern(C++) private class CppAllocatorUnmanaged(T) if (isValidAlloccatorType!T()) {

    /// Allocator has no state
    this() {}

    /// Ditto
    ~this() {}

    /// Allocates new chunk of memory
    T* allocate(const size_t size, const size_t alignment = 0) {
        void* memory = malloc(size);
        return cast(T*) memory;
    }

    /// Reallocates memory
    T* reallocate(T* ptr, const size_t size, const size_t alignment = 0) {
        void* memory = realloc(ptr, size);
        return cast(T*) memory;
    }

    /// Deallocates memory
    void deallocate(void* memory) {
        free(memory);
    }
}

private bool isValidAlloccatorType(T)() {
    return !is(T == const) && !is(T == immutable) && !is(T == class);
}
