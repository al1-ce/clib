/++
betterC compatible associative array.
+/
module clib.map;

// import core.stdc.stdlib: free, malloc, calloc, realloc;
import core.stdc.string: memcpy;

import clib.allocator;
import clib.classes;

/// betterC compatible dynamic size container
struct map(T, S, A = allocator!T) if (!is(S == bool)) {

}

