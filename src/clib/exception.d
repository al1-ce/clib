// SPDX-FileCopyrightText: (C) 2023 Alisa Lain <al1-ce@null.net>
// SPDX-License-Identifier: GPL-3.0-or-later

/++
Exceptions and exception accessories (not really)

Do not use as is. `FILE` and `LINE` needs to be
provided in `msg` for clarity

Noone likes messages like `index 5 is out of bounds for size 2`
without knowing where they coming from
+/
module clib.exception;

import core.stdc.stdlib: exit, EXIT_FAILURE;
import core.stdc.stdio: stderr, fprintf;

import clib.memory;
import clib.format;
import clib.string;

/++
Enforces that `cond == true`
Params:
    cond = Condition to check
    fmt = Message format string
    args = Format arguments
+/
void enforce(E: exception = exception, A...)
    (bool cond, char[] fmt, A args) @nogc nothrow {
    if (!cond) _throw!(E)(fmt, args);
}

/// Ditto
void enforce(E: exception = exception, A...)
    (bool cond, string fmt, A args) @nogc nothrow {
    if (!cond) _throw!(E)(fmt, args);
}

/// Ditto
void enforce(E: exception = exception)
    (bool cond, E e) @nogc nothrow {
    if (!cond) _throw!(E)(e);
}

/++
Throws an exception E
Params:
    cond = Condition to check
    fmt = Message format string
    args = Format arguments
+/
void _throw(E: exception, A...)
    (char[] fmt, A args) @nogc nothrow {
    cstring s = format(fmt, args);
    E e = _new!E(s.release());
    _throw!(E)(e);
}

/// Ditto
void _throw(E: exception, A...)
    (string fmt = "", A args) @nogc nothrow {
    _throw!(E)(cast(char[]) fmt, args);
}

/++
Throws an exception E
Params:
    e = Exception
    release = Should free message? (to shush valgrind)
+/
void _throw(E: exception)(E e) @nogc nothrow {
    if (__isCatchingException) {
        if (__caughtException is null) {
            __caughtException = cast(exception) cast(void*) e;
            __caughtException.type = e.what;
        }
        return;
    }

    if (e.msg == null) {
        fprintf(stderr, "Error: %s.\n", cast(char*) e.what.ptr);
    } else {
        fprintf(stderr, "Error: %s - %s.\n", cast(char*) e.what.ptr, e.msg);
    }

    _free(e);

    exit(EXIT_FAILURE);
}

/++
Try-Catch NoGC alternative

Allows you to catch either specific exceptions with no
inheritance distinction or to catch generic exception

Also due to technicality all exceptions in _try block
are considered caught, which is unlike normal try-catch

To circumvent that please ensure that _finally is called
no matter what

Example:
---
_try(() {
    _throw!overflow_error("Any possibly illegal op here");
})._catch((runtime_error e) {
    // Will not trigger even though overflow_error is a runtime_error
})._catch((overflow_error e) {
    // Will catch overflow_error specifically
})._catch((exception e) {
    // Will handle any exception
})._finally(() {
    // Will run if there was exception
    // Or will throw if exception was not handled
});

_try(() {
    _throw!overflow_error("Any possibly illegal op here");
    // Finally will throw that exception since it wasnt handled
})._finally();
---
+/
TryCatchBlock _try(void delegate() @nogc nothrow tryBlock) @nogc nothrow {
    if (tryBlock is null) return TryCatchBlock();
    __isCatchingException = true;
    tryBlock();
    __isCatchingException = false;
    TryCatchBlock b = { __caughtException };
    __caughtException = null;
    return b;
}

/// Ditto
TryCatchBlock _catch(E: exception)(TryCatchBlock b, void delegate(E) @nogc nothrow catchBlock) @nogc nothrow {
    if (b.e is null || b.handled == true || catchBlock is null) return b;
    import core.stdc.stdio;
    if (E.what == "Exception" || E.what == b.e.type) {
        catchBlock(cast(E) cast(void*) b.e);
        b.handled = true;
    }
    return b;
}

/// Ditto
void _finally()(TryCatchBlock b, void delegate() @nogc nothrow finallyBlock = null) @nogc nothrow {
    if (b.e !is null) {
        if (b.handled == false) _throw!(exception)(b.e);
        if (finallyBlock !is null) finallyBlock();
        _free(b.e);
    }
}

private __gshared bool __isCatchingException = false;
private __gshared exception __caughtException = null;

private struct TryCatchBlock {
    private exception e = null;
    private bool handled = false;
}

    class exception {
        static const string what = "Exception";
        char* msg;
        private string type;
        private string file;
        private int line;
        private bool lfset = false;
        this(char* p_msg = null) @nogc nothrow { msg = p_msg; }
        ~this() @nogc nothrow { import core.stdc.stdlib; free(msg); }
    }

class logic_error: exception { mixin exctor!("Logic Error"); }
class invalid_argument: logic_error { mixin exctor!("Invalid Argument"); }
class out_of_bounds: logic_error { mixin exctor!("Out of Bounds"); }

class runtime_error: exception { mixin exctor!("Runtime Error"); }
class overflow_error: runtime_error { mixin exctor!("Overflow Error"); }
class underflow_error: runtime_error { mixin exctor!("Underflow Error"); }

class bad_alloc: exception { mixin exctor!("Bad Memory Allocation"); }

class bad_cast: exception { mixin exctor!("Bad Cast"); }

class bad_typeid: exception { mixin exctor!("Bad TypeID"); }

private mixin template exctor(string p_what) {
    this(char* p_msg = null) @nogc nothrow { super(p_msg); }
    static const string what = p_what;
}

