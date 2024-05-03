// SPDX-FileCopyrightText: (C) 2023 Alisa Lain <al1-ce@null.net>
// SPDX-License-Identifier: GPL-3.0-or-later

module clib;

// Interesting article indeed
// LINK: https://www.auburnsounds.com/blog/2016-11-10_Running-D-without-its-runtime.html

// C++ STL
public import
    // clib.algorithm,
    // clib.bitset,
    // clib.complex,
    // clib.deque, // nope
    clib.exception,
    // clib.fstream,
    // clib.functional,
    // clib.iomanip,
    // clib.ios,
    // clib.iosfwd,
    // clib.iostream,
    // clib.iterator,
    // clib.limits,
    clib.list,
    // clib.locale,
    clib.map,
    clib.memory,
    // clib.numeric,
    clib.optional,
    // clib.ostream,
    clib.queue,
    clib.set,
    // clib.sstream,
    clib.stack,
    // clib.stdexcept,
    // clib.streambuf,
    clib.string,
    // clib.strstream,
    clib.typeinfo, // with custom version only
    // clib.utility,
    // clib.valarray, // nope
    clib.vector
    ;

// Own additions to STL
public import
    clib.format,
    clib.math
    // clib.iterator // internal no public import
    ;


