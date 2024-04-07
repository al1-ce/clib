/// TypeInfo betterC alternative (WIP)
module cppd.typeinfo;

private struct CppTypeInfo(T) {
    const(char*) name();
    // size_t toHash() const {}
    // bool opEquals(LHS, RHS)(LHS lhs, RHS rhs) const {}
    // const(char*) toString() const {}
    // opCmp() const {}
    // opCast() const {}
    bool isPointer() const {
        return isScalar() && !isIntegral() && !isFloating();
    }
    // hmm.....
    // bool isFunction() const { return is(T == function); }

    bool isArray() const { return is(T == E[], E); }
    // doCatch
    // doUpcast

    // int, float
    bool isArithmetic() const { return __traits(isArithmetic, T); }

    // float, double, real, ... float[]
    bool isFloating() const { return __traits(isFloating, T); }

    // bool, char, int
    bool isIntegral() const { return __traits(isIntegral, T); }

    // bool, char, int, float, ptr
    bool isScalar() const { return __traits(isScalar, T); }
}

/// Queries information about type
alias _typeid = getTypeId;

private CppTypeInfo!T getTypeId(T)(T t) {
    return CppTypeInfo!T();
}

private CppTypeInfo!T getTypeId(T)() {
    return CppTypeInfo!T();
}

