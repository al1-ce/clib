// SPDX-FileCopyrightText: (C) 2023 Alisa Lain <al1-ce@null.net>
// SPDX-License-Identifier: OSL-3.0

/++
Exceptions and exception accessories (not really)

Do not use as is. `FILE` and `LINE` needs to be
provided in `msg` for clarity

Noone likes messages like `index 5 is out of bounds for size 2`
without knowing where they coming from
+/
module clib.exception;

import clib.stdlib: exit, EXIT_FAILURE;
import clib.stdio: stderr, fprintf;

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
    if (__is_catching_exception) {
        if (__caught_exception is null) {
            __caught_exception = cast(exception) cast(void*) e;
            __caught_exception.type = e.what;
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
TryCatchBlock _try(void delegate() @nogc nothrow try_block) @nogc nothrow {
    if (try_block is null) return TryCatchBlock();
    __is_catching_exception = true;
    try_block();
    __is_catching_exception = false;
    TryCatchBlock b = { __caught_exception };
    __caught_exception = null;
    return b;
}

/// Ditto
TryCatchBlock _catch(E: exception)(TryCatchBlock b, void delegate(E) @nogc nothrow catch_block) @nogc nothrow {
    if (b.e is null || b.handled == true || catch_block is null) return b;
    import clib.stdio;
    if (E.what == "Exception" || E.what == b.e.type) {
        catch_block(cast(E) cast(void*) b.e);
        b.handled = true;
    }
    return b;
}

/// Ditto
void _finally()(TryCatchBlock b, void delegate() @nogc nothrow finally_block = null) @nogc nothrow {
    if (b.e !is null) {
        if (b.handled == false) _throw!(exception)(b.e);
        if (finally_block !is null) finally_block();
        _free(b.e);
    }
}

private __gshared bool __is_catching_exception = false;
private __gshared exception __caught_exception = null;

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
        ~this() @nogc nothrow { import clib.stdlib; free(msg); }
    }

class logic_error: exception { mixin EXCTOR!("Logic Error"); }
class invalid_argument: logic_error { mixin EXCTOR!("Invalid Argument"); }
class out_of_bounds: logic_error { mixin EXCTOR!("Out of Bounds"); }

class runtime_error: exception { mixin EXCTOR!("Runtime Error"); }
class overflow_error: runtime_error { mixin EXCTOR!("Overflow Error"); }
class underflow_error: runtime_error { mixin EXCTOR!("Underflow Error"); }

class bad_alloc: exception { mixin EXCTOR!("Bad Memory Allocation"); }

class bad_cast: exception { mixin EXCTOR!("Bad Cast"); }

class bad_typeid: exception { mixin EXCTOR!("Bad TypeID"); }

private mixin template EXCTOR(string p_what) {
    this(char* p_msg = null) @nogc nothrow { super(p_msg); }
    static const string what = p_what;
}

