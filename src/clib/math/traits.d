// SPDX-FileCopyrightText: (C) 2023 Alisa Lain <al1-ce@null.net>
// SPDX-License-Identifier: GPL-3.0-or-later

/// Math traits
module clib.math.traits;

import clib.traits : isFloatingPoint, isIntegral, isNumeric, isSigned;

/// Determines if X is NaN
bool isNaN(X)(X x) @nogc @trusted pure nothrow if (isFloatingPoint!(X)) {
    return x != x;
}

// TODO: math!

