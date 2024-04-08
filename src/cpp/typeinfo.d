/// TypeInfo betterC alternative (WIP)
module cpp.typeinfo;

private struct CppTypeInfo(T) {
    const(char*) name();
    // size_t toHash() const {}
    // bool opEquals(LHS, RHS)(LHS lhs, RHS rhs) const {}
    // const(char*) toString() const {}
    // opCmp() const {}
    // opCast() const {}
    bool isPointer() @nogc nothrow const {
        return isScalar() && !isIntegral() && !isFloating();
    }
    // hmm.....
    // bool isFunction() const { return is(T == function); }

    bool isArray() @nogc nothrow const { return is(T == E[], E); }
    // doCatch
    // doUpcast

    // int, float
    bool isArithmetic() @nogc nothrow const { return __traits(isArithmetic, T); }

    // float, double, real, ... float[]
    bool isFloating() @nogc nothrow const { return __traits(isFloating, T); }

    // bool, char, int
    bool isIntegral() @nogc nothrow const { return __traits(isIntegral, T); }

    // bool, char, int, float, ptr
    bool isScalar() @nogc nothrow const { return __traits(isScalar, T); }
}

/// Queries information about type
alias _typeid = getTypeId;

private CppTypeInfo!T getTypeId(T)(T t) @nogc nothrow {
    return CppTypeInfo!T();
}

private CppTypeInfo!T getTypeId(T)() @nogc nothrow {
    return CppTypeInfo!T();
}

