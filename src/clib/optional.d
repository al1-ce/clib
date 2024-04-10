/++
Simple alternative to std.typecons: Nullable

Warning: frees any contained value on assignments
---
int* p = cast(int*) malloc(4 * int.sizeof);
optional!(int*) opt = p;
opt = null;
p[0] = 1; // SEGFAULT
---
+/
module clib.optional;

import core.stdc.stddef: nullptr_t;

/// Optional type
struct optional(T) {
    private T _value;
    private bool _hasValue = false;

    @property bool hasValue() @nogc nothrow { return _hasValue; }
    @property T value() @nogc nothrow { return _value; }
    T valueOr(T val) @nogc nothrow { return _hasValue ? _value : val; }

    /// Constructs optional as null
    this(nullptr_t _null) @nogc nothrow {}
    /// Constructs optional as value
    this(T p_val) @nogc nothrow {
        _value = p_val;
        _hasValue = true;
    }
    /// Constructs optional from other optional
    this(optional!T p_other) @nogc nothrow {
        _value = p_other._value;
        _hasValue = p_other._hasValue;
    }

    ~this() @nogc nothrow {
        destroy!false(_value);
    }

    void opAssign(T val) @nogc nothrow {
        destroy!false(_value);
        _value = val;
        _hasValue = true;
    }

    void opAssign(nullptr_t _null) @nogc nothrow {
        destroy!false(_value);
        _hasValue = false;
    }

    void opAssign(optional!T other) @nogc nothrow {
        destroy!false(_value);
        _value = other._value;
        _hasValue = other._hasValue;
    }

    bool opEquals(T other) const @nogc nothrow {
        return _hasValue ? (_value == other) : false;
    }

    bool opEquals(nullptr_t _null) const @nogc nothrow {
        return !_hasValue;
    }

    bool opEquals(optional!T other) const @nogc nothrow {
        if (!other._hasValue && !_hasValue) return true;
        return other._hasValue == _hasValue && other._value == _value;
    }

    /// Exchanges contents
    void swap(ref optional!T other) @nogc nothrow {
        T val = _value;
        bool has = _hasValue;
        _value = other._value;
        _hasValue = other._hasValue;
        other._value = val;
        other._hasValue = has;
    }

    /// Destroys contained value
    void reset() @nogc nothrow {
        destroy!false(_value);
        _hasValue = false;
    }
}

@nogc nothrow:
// Unittests

unittest {
    optional!int opt;
    assert(opt.hasValue == false);
    assert(opt.valueOr(5) == 5);
    opt = 1;
    assert(opt.hasValue == true);
    assert(opt.value == 1);
}

unittest {
    optional!int opt;
    opt = 2;
    opt = null;
    assert(opt.hasValue == false);
    assert(opt.valueOr(5) == 5);
    opt = optional!int(3);
    assert(opt == 3);
    assert(opt != null);
    assert(opt == optional!int(3));
}

unittest {
    optional!int a = 4;
    optional!int b;
    a.swap(b);
    assert(a == null);
    assert(b == 4);
    b.reset();
    assert(b == null);
}

