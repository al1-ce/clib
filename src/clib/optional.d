// SPDX-FileCopyrightText: (C) 2023 Alisa Lain <al1-ce@null.net>
// SPDX-License-Identifier: GPL-3.0-or-later

/++
Simple alternative to std.typecons: Nullable

Warning: frees any contained value on assignments
Warning: not intended to be used with clib containers
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

    /// Returns true if value is set
    @property bool hasValue() @nogc nothrow { return _hasValue; }

    /// Returns value
    @property T value() @nogc nothrow { return _value; }

    /// Returns value or T val
    T valueOr(T val) @nogc nothrow { return _hasValue ? _value : val; }

    /// Constructs optional as null
    this(nullptr_t _null) @nogc nothrow {}
    /// Constructs optional as value
    this(T p_val) @nogc nothrow {
        _value = p_val;
        _hasValue = true;
    }
    /// Constructs optional from other optional
    this(ref scope optional!T p_other) @nogc nothrow {
        _value = p_other._value;
        _hasValue = p_other._hasValue;
    }

    ~this() @nogc nothrow {
        destroy!false(_value);
    }

    /// Creates copy of this optional
    scope optional!T clone() @nogc nothrow {
        optional!T o;
        o._value = _value;
        o._hasValue = _hasValue;
        return o;
    }

    void opAssign(T val) @nogc nothrow {
        destroy!true(_value);
        _value = val;
        _hasValue = true;
    }

    void opAssign(nullptr_t _null) @nogc nothrow {
        destroy!true(_value);
        _hasValue = false;
    }

    void opAssign(optional!T other) @nogc nothrow {
        destroy!true(_value);
        _value = other._value;
        _hasValue = other._hasValue;
    }

    bool opEquals(const T other) const @nogc nothrow {
        return _hasValue ? (_value == other) : false;
    }

    bool opEquals(const nullptr_t _null) const @nogc nothrow {
        return !_hasValue;
    }

    bool opEquals(ref const optional!T other) const @nogc nothrow {
        if (!other._hasValue && !_hasValue) return true;
        if (other._hasValue != _hasValue) return false;
        return other._value == _value;
    }

    size_t toHash() const @nogc nothrow {
        if (!_hasValue) return 0;
        static if (__traits(hasMember, T, "toHash")) {
            return _value.toHash();
        } else {
            return _value.hashOf();
        }
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
        destroy!true(_value);
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
    optional!int b = optional!int(3);
    assert(opt == b);
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

unittest {
    import clib.vector;
    optional!(vector!int) a;
    vector!int v = vector!int(1, 2, 3, 4);
    a = v;
    assert(a.hasValue);
    assert(a.value == [1, 2, 3, 4]);
    optional!(vector!int) b;
    b = a;
    assert(a.hasValue);
    assert(a.value == [1, 2, 3, 4]);
    assert(b.hasValue);
    assert(b.value == [1, 2, 3, 4]);
    assert(a == b);
    import core.stdc.stdlib;
    void test1(optional!(vector!int) o) { free(o.value.release()); }
    void test2(vector!int v) { free(v.release()); }

    test1(a);
    test2(a.value);

    assert(a.hasValue);
    assert(a.value == [1, 2, 3, 4]);
    assert(b.hasValue);
    assert(b.value == [1, 2, 3, 4]);
    assert(a == b);
}

unittest {
    import clib.vector;
    optional!int o1 = 15;
    optional!(vector!int) o2 = vector!int(1, 2, 3);
    cast(void) o1.toHash;
    cast(void) o2.toHash;
}

