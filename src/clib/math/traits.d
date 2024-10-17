// SPDX-FileCopyrightText: (C) 2023 Alisa Lain <al1-ce@null.net>
// SPDX-License-Identifier: OSL-3.0

/// Math traits
module clib.math.traits;

import clib.traits : IS_FLOATING_POINT;

/// Determines if X is NaN
bool is_nan(X)(X x) @nogc @trusted pure nothrow if (IS_FLOATING_POINT!(X)) {
    return x != x;
}

// TODO: math!

