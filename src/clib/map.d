/++
betterC compatible associative array.
+/
module clib.map;

// import core.stdc.stdlib: free, malloc, calloc, realloc;
import core.stdc.string: memcpy;

import clib.memory;

/// betterC compatible dynamic size container
struct map(T, S, A: IAllocator!T = allocator!T) if (!is(S == bool)) {

}

