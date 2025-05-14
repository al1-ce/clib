// SPDX-FileCopyrightText: (C) 2024 Alisa Lain <al1-ce@null.net>
// SPDX-License-Identifier: OSL-3.0

module clib.conv;
// TODO: add separate cast versions for C++ linkage and D classes

/// Interprets F as T (dangerous, use mainly as workaround to bug 21690)
T reinterpret_cast(T, F)(F t) @nogc nothrow if (T.sizeof == F.sizeof) {
    return ( cast(T) cast(void*) t );
}

/// Downcasts F to T (CAN RETURN NULL IF UNABLE TO DOWNCAST)
T dynamic_cast(T, F)(F t) @nogc nothrow if ((IS_CLASS!T && IS_CLASS!F) || is(T: F)) {
    version (CLIB_USE_TYPEINFO) {
        if (_typeid!(F)().is_base_of!(T)()) {
            return ( cast(T) cast(void*) t );
        } else {
            return null;
        }
    } else {
        return cast(T) cast(void*) t;
    }
}

/// Downcasts F to T or converts scalar types (CAN RETURN NULL IF UNABLE TO DOWNCAST)
T static_cast(T, F)(F t) @nogc nothrow
if ((IS_CLASS!T && IS_CLASS!F) || (IS_SCALAR!T && IS_SCALAR!F)) {
    if (IS_SCALAR_TYPE!T) {
        return cast(T) t;
    } else {
        return dynamic_cast!(T, F)(t);
    }
}

/// Performs basic type casting
T const_cast(T, F)(F t) @nogc nothrow {
    return cast(T) t;
}

private enum bool IS_SCALAR(T) = __traits(isScalar, T) && is(T : real);

private enum bool IS_CLASS(T) =
    (is(T == U*, U) && (is(T == class) || is(T == interface))) ||
    (is(T == class) || is(T == interface));


