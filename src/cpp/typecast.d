/// C++ casts
module cpp.typecast;

// Unable to use since no TypeInfo
// T* dynamicCast(T, F)(F* t) {}
// T* staticCast(T, F)(F* t) {}
// T* constCast(T, F)(F* t) {}

/// Interprets F as T (dangerous, use as workaround to bug 21690)
T reinterpretCast(T, F)(F t) @nogc nothrow {
    return ( cast(T) cast(void*) t );
}
