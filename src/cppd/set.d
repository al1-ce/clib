/++
betterC compatible associative container that contains a sorted set of unique objects
+/
module cppd.set;

import cppd.allocator;
import cppd.betterc;

alias set = CppSet;

private struct CppSet(T, alias F = sortFunction, A = allocator!T) {
    private T* _data;
    private A _allocator;

    private size_t _size;
    private size_t _capacity;

    this(T[] vals...) {

    }

    void insert() {

    }
}

private bool sortFunction(T)(T a, T b) {
    return a < b;
}
