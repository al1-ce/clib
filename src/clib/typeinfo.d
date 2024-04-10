/// TypeInfo betterC alternative (WIP DO NOT USE)
module clib.typeinfo;

import core.stdc.string: strcmp;
import core.internal.traits;

import clib.classes;
import clib.typecast;
import clib.cstring;

/// Use this as parent for all `extern(C++)` classes
/// if you want to have typeinfo
extern(C++) class cppObject {
    this() @nogc nothrow {}

    /// Convert cppObject into human readable string
    const(char*) toString() const @nogc nothrow {
        // return cast(char*) __traits(identifier, typeof(this)).ptr;
        return _typeid(this).name;
    }

    /// Compute hash function for cppObject
    size_t toHash() const @trusted @nogc nothrow {
        size_t addr = cast(size_t) cast(void*) this;
        return addr ^ (addr >>> 4);
    }

    /// Compares with another object. (must implement, default compares hash)
    /// Returns:
    /// -1 if `this < o`
    ///  0 if `this == o`
    ///  1 if `this > o`
    int opCmp(cppObject o) const @nogc nothrow {
        size_t a = this.toHash();
        size_t b = o.toHash();
        if (a < b) return -1;
        if (a > b) return 1;
        return 0;
    }

    bool opEquals(cppObject o) const @nogc nothrow {
        return this is o;
    }

    private void __clib_cpp_object_identifier() {}
}


struct type_info {
    /// Fully qualified type name
    const char* name = "\0".ptr;
    /// Is type a pointer
    const bool isPointer = false;
    /// Is type a function
    const bool isFunction = false;
    private const char[] strName;

    const(char*) toString() const { return name; }

    size_t toHash() const @trusted @nogc nothrow {
        return 0;
    }

    int opCmp(cppObject other) const @nogc nothrow {
        return strcmp(name, _typeid(other).name);
    }

    int opCmp(type_info other) const @nogc nothrow {
        return strcmp(name, other.name);
    }

    bool opEquals(type_info other) const @nogc nothrow {
        return name == other.name;
    }

    bool opEquals(cppObject other) const @nogc nothrow {
        return name == _typeid(other).name;
    }

    /// Is T a child of type_info owner
    bool isBaseOf(T)(T t) @nogc nothrow {
        return isBaseOf!T;
    }

    /// Ditto
    bool isBaseOf(T)() @nogc nothrow {
        if (!isSubclassOfCppObject!T) return false;
        import core.stdc.string: strlen, memcmp;
        char[200] s = ' ';
        char[] t = cast(char[]) strName;

        s[0..2] = cast(char[]) "__";

        for (int i = 0 ; i < t.length; ++i) {
            if (t[i] == '.') {
                s[2 + i] = '_';
            } else {
                s[2 + i] = t[i];
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
        cast(const(char[])) __traits(fullyQualifiedName, Unqual!T)
    };

    return t;
}

private bool isSuitableForTypeID(T)() @nogc nothrow {
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

mixin template RTTI(T) if (isSubclassOfCppObject!T) {
    mixin( __cpp_class_inheritance_generator!T() );
}

char[200] __cpp_class_inheritance_generator(T)() {
    import core.stdc.string: strlen;
    char[200] s = ' ';
    char[] t = cast(char[]) __traits(fullyQualifiedName, T);

    s[0..7] = cast(char[]) "void __";

    for (int i = 0 ; i < t.length; ++i) {
        if (t[i] == '.') {
            s[7 + i] = '_';
        } else {
            s[7 + i] = t[i];
        }
    }

    s[(7 + t.length)..(7 + t.length + 18)] = "_clib_parent (){}\0";

    return s;
}

