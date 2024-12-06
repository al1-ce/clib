// SPDX-FileCopyrightText: (C) 2023 Alisa Lain <al1-ce@null.net>
// SPDX-License-Identifier: OSL-3.0

/// Iterator/Range for internal use
module clib.iterator;

import clib.traits;

/// Forward iterator implementation that traverses elements from start to end.
/// Supports method chaining and follows D's range protocol.

/// Params:
///     I = The iterable type (must support opIndex)
///     T = The element type
struct forward_iterator(I, T) if (IS_VALID_ITERABLE!I) {
    private I iterable;
    private size_t size = 0;
    private size_t index = 0;

    this(ref I _iterable, size_t _size) @nogc nothrow {
        iterable = _iterable;
        size = _size;
    }

    @property bool empty() @nogc nothrow => index >= size;
    @property T front() @nogc nothrow => iterable[index];

    ref forward_iterator!(I, T) popFront() @nogc nothrow { ++index; return this; }
}

/// Const forward iterator implementation.
/// Provides read-only access to elements.
struct const_forward_iterator(I, T) if (IS_VALID_ITERABLE!I) {
    private const I iterable;
    private const size_t size;
    private size_t index;  // Mutable even in const objects

    this(ref const I _iterable, size_t _size) @nogc nothrow {
        iterable = _iterable;
        size = _size;
        index = 0;
    }

    @property bool empty() const @nogc nothrow => index >= size;
    @property const(T) front() const @nogc nothrow => iterable[index];

    ref const_forward_iterator!(I, T) popFront() @nogc nothrow { ++index; return this; }
}

/// Backward iterator implementation that traverses elements from end to start.
/// Supports method chaining and follows D's range protocol.

/// Params:
///     I = The iterable type (must support opIndex)
///     T = The element type
struct backward_iterator(I, T) if (IS_VALID_ITERABLE!I) {
    private I iterable;
    private size_t size = 0;
    private size_t index = 0;

    this(ref I _iterable, size_t _size) @nogc nothrow {
        iterable = _iterable;
        size = _size;
    }

    @property bool empty() @nogc nothrow => index >= size;
    @property T back() @nogc nothrow => iterable[size - index - 1];
    @property T front() @nogc nothrow => back(); // Alias to back for consistency

    ref backward_iterator!(I, T) popBack() @nogc nothrow { ++index; return this; }
    ref backward_iterator!(I, T) popFront() @nogc nothrow { return popBack(); } // Alias popBack()
}

/// Const backward iterator implementation.
/// Provides read-only access to elements.
struct const_backward_iterator(I, T) if (IS_VALID_ITERABLE!I) {
    private const I iterable;
    private const size_t size;
    private size_t index;  // Mutable even in const objects

    this(ref const I _iterable, size_t _size) @nogc nothrow {
        iterable = _iterable;
        size = _size;
        index = 0;
    }

    @property bool empty() const @nogc nothrow => index >= size;
    @property const(T) back() const @nogc nothrow => iterable[size - index - 1];
    @property const(T) front() const @nogc nothrow => back(); // Alias to back for consistency

    ref const_backward_iterator!(I, T) popBack() @nogc nothrow { ++index; return this; }
    ref const_backward_iterator!(I, T) popFront() @nogc nothrow { return popBack(); } // Alias popBack()
}

private bool IS_VALID_ITERABLE(T)() @nogc nothrow {
    static if (IS_ARRAY!T) {
        return true;
    } else {
        return __traits(hasMember, T, "opIndex");
    }
}

@nogc nothrow {
    unittest {
        // Test forward iteration with array
        int[12] arr = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
        auto f = forward_iterator!(typeof(arr), int)(arr, arr.length);

        // Test basic iteration
        int i = 0;
        foreach (int el; f) {
            assert(el == i + 1);
            ++i;
        }

        // Test method chaining
        auto iter = forward_iterator!(typeof(arr), int)(arr, arr.length);
        assert(iter.front == 1);
        assert(iter.popFront().front == 2);
        assert(iter.popFront().front == 3);
    }

    unittest {
        // Test forward iteration with cstring
        import clib.string;
        cstring s = "testing my patience";
        string t = "testing my patience";

        // Test basic iteration
        int i = 0;
        foreach (char c; forward_iterator!(cstring, char)(s, s.size)) {
            assert(c == t[i]);
            ++i;
        }

        // Test method chaining
        auto iter = forward_iterator!(cstring, char)(s, s.size);
        assert(iter.front == 't');
        assert(iter.popFront().front == 'e');
    }

    unittest {
        // Test backward iteration with cstring
        import clib.string;
        cstring s = "testing my patience";
        string t = "testing my patience";

        // Test basic iteration
        int i = cast(int) s.size - 1;
        foreach_reverse (char c; backward_iterator!(cstring, char)(s, s.size)) {
            assert(c == t[i]);
            --i;
        }

        // Test method chaining
        auto iter = backward_iterator!(cstring, char)(s, s.size);
        assert(iter.back == 'e');
        assert(iter.popBack().back == 'c');

        // Test front/popFront aliases
        iter = backward_iterator!(cstring, char)(s, s.size);
        assert(iter.front == 'e');
        assert(iter.popFront().front == 'c');
    }

    unittest {
        // Test const forward iteration
        const int[5] arr = [1, 2, 3, 4, 5];
        auto iter = const_forward_iterator!(typeof(arr), int)(arr, arr.length);

        // Test basic iteration
        int i = 1;
        while (!iter.empty) {
            assert(iter.front == i);
            iter.popFront();
            ++i;
        }

        // Test fresh iterator for method chaining
        auto iter2 = const_forward_iterator!(typeof(arr), int)(arr, arr.length);
        assert(iter2.front == 1);
        assert(iter2.popFront().front == 2);
    }

    unittest {
        // Test const backward iteration
        const int[5] arr = [1, 2, 3, 4, 5];
        auto iter = const_backward_iterator!(typeof(arr), int)(arr, arr.length);

        // Test basic iteration
        int i = 5;
        while (!iter.empty) {
            assert(iter.back == i);
            iter.popBack();
            --i;
        }

        // Test fresh iterator for method chaining
        auto iter2 = const_backward_iterator!(typeof(arr), int)(arr, arr.length);
        assert(iter2.back == 5);
        assert(iter2.popBack().back == 4);

        // Test front/popFront aliases with fresh iterator
        auto iter3 = const_backward_iterator!(typeof(arr), int)(arr, arr.length);
        assert(iter3.front == 5);
        assert(iter3.popFront().front == 4);
    }
}