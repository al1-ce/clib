// SPDX-FileCopyrightText: (C) 2023 Alisa Lain <al1-ce@null.net>
// SPDX-License-Identifier: OSL-3.0

/// NoGC compatible format
module clib.format;

import clib.stdio: snprintf;
import clib.stdlib: malloc;

import clib.string;

/++
Formats string
Params:
    buffer - Buffer to write formatted string to
    fmt - Format string
    args - Args to format
Example:
---
size_t l = format()
format()
---
+/
scope cstring format(A...)(const(char)[] fmt, A args) @nogc nothrow {
    size_t len = snprintf(cast(char*) null, 0, fmt.ptr, args) + 1;
    char* buffer = cast(char*) malloc(len);
    snprintf(buffer, len, fmt.ptr, args);
    cstring str;
    str.assign_pointer(buffer, len);
    return str;
}

/// Ditto
scope cstring format(A...)(string fmt, A args) @nogc nothrow {
    return format(cast(char[]) fmt, args);
}

/// Returns c-style pointer to string
char* stringz(string s) @nogc nothrow {
    return cast(char*) s.ptr;
}
