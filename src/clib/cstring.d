/++
betterC compatible string.
Technically it is simply an alias to vector!char
because vector!char already includes everything
that cstring needs (using static if)
+/
module clib.cstring;

import clib.vector;

alias cstring = vector!char;

// TODO: actually move everything to vector
// TODO: and add static if (T == char)
// size_t find(cstring str, size_t pos = 0) @nogc nothrow {}
// size_t find(char* str, size_t strSize, size_t pos = 0) @nogc nothrow {}
// size_t find(char, size_t pos = 0) @nogc nothrow {}
// rfind
// substr -> alias to opIndex
// TODO: compare


