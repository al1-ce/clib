/++
Simple alternative to std.typecons: Nullable
+/
module cppd.optional;

import core.stdc.stddef: nullptr_t;

/// Optional type
alias optional = CppOptional;

/// Ditto
struct CppOptional(T) {

    private T _value;

    private bool _hasValue = false;

    @property bool hasValue() { return _hasValue; }

    @property T value() { return _value; }

    @property T valueOr(T val) { return _hasValue ? _value : val; }

    this(nullptr_t _null) {}

    this(T p_val) {
        _value = p_val;
        _hasValue = true;
    }

    this(optional!T* p_other) {
        _value = p_other._value;
        _hasValue = p_other._hasValue;
    }
}
