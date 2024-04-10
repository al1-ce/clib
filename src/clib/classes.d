/**
DO NOT USE WITH ANYTHING EXCEPT `extern(C++)` CLASSES

Module containing class utils to work with betterC
*/
module clib.classes;

/++
DO NOT USE WITH ANYTHING EXCEPT `extern(C++)` CLASSES

ALTERNATIVE TO DECLARING `__gshared CppClass c = new CppClass();` (yes it works)

Used to allocate/deallocate memory for C++ classes

Example:
---
extern(C++) class CppClass {
    this(int p_a, char* p_b) {
        a = p_a;
        b = p_b;
    }

    int a;
    char* b;
    bool c = true;
}

extern(C) void main(int argc, char** argv) {
    CppClass cppClass = _new!CppClass(2, cast(char*) "Hello world".ptr);
    scope(exit) _free(cppClass);

    printf("%s, %i", cppClass.b, cppClass.a);
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
    // static if (__traits(hasMember, T, "__ctor"))
    t.__ctor(forward!args);

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

