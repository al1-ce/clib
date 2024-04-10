/// C++ casts
module clib.typecast;

import core.internal.traits;

import clib.typeinfo;

/// Interprets F as T (dangerous, use mainly as workaround to bug 21690)
T reinterpret_cast(T, F)(F t) @nogc nothrow {
    return ( cast(T) cast(void*) t );
}

/// Downcasts F to T and returns null if unable to
T dynamic_cast(T, F)(F t) @nogc nothrow if (isClass!T && isClass!F) {
    if (_typeid!(F)().isBaseOf!(T)()) {
        return ( cast(T) cast(void*) t );
    } else {
        return null;
    }
}

/// Downcasts F to T or converts scalar types
T static_cast(T, F)(F t) @nogc nothrow
if ((isClass!T && isClass!F) || (isScalar!T && isScalar!F)) {
    if (isScalarType!T) {
        return cast(T) t;
    } else {
        return dynamic_cast!(T, F)(t);
    }
}

/// Performs basic type casting
T const_cast(T, F)(F t) @nogc nothrow {
    return cast(T) t;
}

private enum bool isScalar(T) = __traits(isScalar, T) && is(T : real);

private enum bool isClass(T) =
    (is(T == U*, U) && (is(T == class) || is(T == interface))) ||
    (is(T == class) || is(T == interface));

