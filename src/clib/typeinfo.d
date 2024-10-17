// SPDX-FileCopyrightText: (C) 2023 Alisa Lain <al1-ce@null.net>
// SPDX-License-Identifier: OSL-3.0

/// extern(C++) TypeInfo alternative
module clib.typeinfo;

// To prevent usage without reading readme (I hate when people are not reading readme)
version(D_BetterC) { version = CLIB_USE_TYPEINFO; }
version(CLIB_USE_TYPEINFO):

import clib.string: strcmp;
import clib.traits;

import clib.memory;

/// LINK: https://github.com/ldc-developers/ldc/issues/2425
/// HACK: _d_array_slice_copy
version(LDC) extern(C) void _d_array_slice_copy(void* dst, size_t dstlen, void* src, size_t srclen, size_t elemsz){
    import ldc.intrinsics;
    llvm_memcpy!size_t(dst, src, dstlen * elemsz, 0);
}

// TODO: maybe store rtti in char[][]?

/// Use this as parent for all `extern(C++)` classes
/// if you want to have typeinfo
extern(C++) abstract class CppObject {
    this() @nogc nothrow {}

    /// Convert CppObject into human readable string
    const(char*) toString() const @nogc nothrow {
        // return cast(char*) __traits(identifier, typeof(this)).ptr;
        return _typeid(this).name;
    }

    /// Compute hash function for CppObject
    size_t toHash() const @trusted @nogc nothrow {
        size_t addr = cast(size_t) cast(void*) this;
        return addr ^ (addr >>> 4);
    }

    /// Compares with another object. (must implement, default compares hash)
    /// Returns:
    /// -1 if `this < o`
    ///  0 if `this == o`
    ///  1 if `this > o`
    int opCmp(CppObject o) const @nogc nothrow {
        size_t a = this.toHash();
        size_t b = o.toHash();
        if (a < b) return -1;
        if (a > b) return 1;
        return 0;
    }

    bool opEquals(CppObject o) const @nogc nothrow {
        return this is o;
    }

    void __clib_cpp_object_identifier() {}
}

/// D's TypeInfo alternative
struct type_info {
    /// Fully qualified type name
    const char* name = "\0".ptr;
    /// Is type a pointer
    const bool isPointer = false;
    /// Is type a function
    const bool isFunction = false;
    private const char[] _strName;
    private bool _isACppObject = false;

    /// Returns fully qualified type name
    const(char*) toString() const { return name; }

    /// Returns 0
    size_t toHash() const @trusted @nogc nothrow {
        return 0;
    }

    int opCmp(CppObject other) const @nogc nothrow {
        return strcmp(name, _typeid(other).name);
    }

    int opCmp(type_info other) const @nogc nothrow {
        return strcmp(name, other.name);
    }

    bool opEquals(type_info other) const @nogc nothrow {
        return name == other.name;
    }

    bool opEquals(CppObject other) const @nogc nothrow {
        return name == _typeid(other).name;
    }

    /// Is T a child of type_info owner
    bool isBaseOf(T)(T t) @nogc nothrow {
        return isBaseOf!T;
    }

    /// Ditto
    bool isBaseOf(T)() @nogc nothrow {
        if (isPointer || isFunction) return false;
        import clib.string: strlen, memcmp;
        if (!isSubclassOfCppObject!T) return false;
        if (_isACppObject) return true;
        char[200] s = ' ';
        char[] t = cast(char[]) _strName;

        s[0..2] = cast(char[]) "__";

        for (int i = 0 ; i < t.length; ++i) {
            char c = t[i];
            if ( (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ) {
                s[2 + i] = c;
            } else {
                s[2 + i] = '_';
            }
        }

        s[(2 + t.length)..(2 + t.length + 13)] = "_clib_parent\0";

        foreach (m; __traits(allMembers, T)) {
            size_t ms = t.length + 14;
            if (memcmp(s.ptr, cast(char*) m.ptr, ms * char.sizeof) == 0) return true;
        }

        return false;
    }
}

/// Queries information about type
type_info _typeid(T)(T t) @nogc nothrow if (isSuitableForTypeID!T) {
    return _typeid!T();
}

/// Ditto
type_info _typeid(T)() @nogc nothrow if (isSuitableForTypeID!T) {
    type_info t = {
        cast(const(char*)) __traits(fullyQualifiedName, Unqual!T).ptr,
        isPointer!T,
        isFunctionPointer!T || isDelegate!T,
        cast(const(char[])) __traits(fullyQualifiedName, Unqual!T),
        is(T == CppObject)
    };

    return t;
}

private bool isSuitableForTypeID(T)() @nogc nothrow {
    static if (is(T == interface)) return true;
    const bool isPtr = isAnyPointerType!T;
    static if (!isPtr) {
        return isSubclassOfCppObject!T;
    } else {
        return true;
    }
}

private bool isSubclassOfCppObject(T)() @nogc nothrow if (!isAnyPointerType!T) {
    bool isCpp = __traits(getLinkage, T) == "C++";
    bool isObj = __traits(hasMember, T, "__clib_cpp_object_identifier");
    return isCpp && isObj;
}

private bool isAnyPointerType(T)() @nogc nothrow {
    return isPointer!T || isFunctionPointer!T || isDelegate!T;
}

/// Injects RunTime Type Information (allows type_info to see inheritance)
mixin template RTTI(T) if ((isSubclassOfCppObject!T || is(T == interface)) && !is(T == CppObject)) {
    mixin( __cpp_class_inheritance_generator!T() );
}

char[200] __cpp_class_inheritance_generator(T)() {
    import clib.string: strlen;
    char[200] s = ' ';
    char[] t = cast(char[]) __traits(fullyQualifiedName, T);

    s[0..7] = cast(char[]) "void __";

    for (int i = 0 ; i < t.length; ++i) {
        char c = t[i];
        if ( (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ) {
            s[7 + i] = c;
        } else {
            s[7 + i] = '_';
        }
    }

    s[(7 + t.length)..(7 + t.length + 18)] = "_clib_parent (){}\0";
    return s;
}

// TODO: add separate cast versions for C++ linkage and D classes

/// Interprets F as T (dangerous, use mainly as workaround to bug 21690)
T reinterpret_cast(T, F)(F t) @nogc nothrow {
    return ( cast(T) cast(void*) t );
}

/// Downcasts F to T (CAN RETURN NULL IF UNABLE TO DOWNCAST)
T dynamic_cast(T, F)(F t) @nogc nothrow if (isClass!T && isClass!F) {
    if (_typeid!(F)().isBaseOf!(T)()) {
        return ( cast(T) cast(void*) t );
    } else {
        return null;
    }
}

/// Downcasts F to T or converts scalar types (CAN RETURN NULL IF UNABLE TO DOWNCAST)
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

