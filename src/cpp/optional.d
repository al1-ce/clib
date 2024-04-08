/++
Simple alternative to std.typecons: Nullable
+/
module cpp.optional;

import core.stdc.stddef: nullptr_t;

/// Optional type
alias optional = CppOptional;

/// Ditto
struct CppOptional(T) {

    private T _value;

    private bool _hasValue = false;

    @property bool hasValue() @nogc nothrow { return _hasValue; }

    @property T value() @nogc nothrow { return _value; }

    T valueOr(T val) @nogc nothrow { return _hasValue ? _value : val; }

    this(nullptr_t _null) @nogc nothrow {}

    this(T p_val) @nogc nothrow {
        _value = p_val;
        _hasValue = true;
    }

    this(optional!T* p_other) @nogc nothrow {
        _value = p_other._value;
        _hasValue = p_other._hasValue;
    }

    ~this() @nogc nothrow {
        destroy!false(_value);
    }
}
