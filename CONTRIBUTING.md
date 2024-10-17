# Contributing Guidelines

#### Bug reporting 

Open an issue at [GitHub issue tracker](https://github.com/al1-ce/clib/issues). Before doing that, ensure the bug was not already reported or fixed in `master` branch. Describe a problem and, if necessary, provide minimal code needed to reproduce it.

#### Bug fixing 

Open a new GitHub pull request with your patch. Provide a description of the problem and solution. Follow our [code style](#code-style-and-standards).

#### Implementing new features

New code should at least:
* work under Windows and POSIX systems and provide platform-agnostic API
* support x86 and x86_64 targets
* be `@nogc nothrow` compatible
* not use any external dependencies or have them as optional dependencies
* follow our [code style](#code-style-and-standards)
* not violate copyright/licensing. When adapting third-party code, make sure that it is compatible with [GNU GPL 3.0](https://www.gnu.org/licenses/gpl-3.0.en.html).

#### Branching strategy

`master` branch is a development branch for the next release. When release is ready, `master` branch will be pushed into `release` branch and release will be made from it.

#### Code style and standards 

clib mostly follows [D style](https://dlang.org/dstyle.html). Essential rules are the following:
* Use spaces instead of tabs. Each indentation level is 4 spaces
* There's always a space after control statements (`if`, `while`, `for`, etc...)
* Opening curly bracket should be on a **same** line
* Functions and variables should be in `snake_case`
* Classes, structs and enums should be in `PascalCase`
* Enum members, consts and macro-like templates and functions can be in `SCREAMING_SNAKE_CASE`
* Module names should be in lowercase
* `if () else if ()` can be split as `if () else\n if ()`
* If method or function is used as property parenthesis can be dropped
* Prefer explicitly importing methods instead of importing whole module when only several methods from this module are needed. Exception is when imported module declares only one thing (i.e vector and aliases for it)
* Also prefer explicitly importing sub-modules. I.e `import std.algorithm.searching;` instead of `import std.algorithm;`
* Imports are ordered separated by single space. First normal, then static and finally public:
    1. std
    2. core
    3. other libraries (with version specifier)
    4. clib
* Preferred order of declarations for classes or structs is:
    1. Public properties and one-line setters/getters
    2. Private properties
    3. Constructors
    4. Public methods
    5. Private methods
* Property name prefixes are (does not apply to methods):
    - ` ` - none for any kind of properties except ones below (`public static const int normal_property`)
    - `_` - for private/protected properties (`private int _private_property`)
    - `s_` - for private/protected static properties (`private static int s_static_int`)
    - `t_` - for private/protected thread static properties (`private shared int t_static_int`)
    - `_` - as postfix when name is a keyword (`bool bool_`)
* Function signature preferred to be in order:
    1. attributes (@property)
    2. visibility (public, private...), `public` can be dropped since everything is default public
    3. isStatic (static)
    4. misc
    5. isOverride (override)
    6. type qualifiers and type (int, bool...)
    7. name and params
    8. attributes (const, nothrow, pure, @nogc, @safe)
    9. i.e `@property private static override int my_method(int* ptr) @safe @nogc nothrow {}`
* Interfaces must be prefixed with `I`, i.e. `IEntity`
* When declaring properties, methods, etc... visibility modifier can be dropped in favor of global visibility modifier, i.e `private:`. This type of declaration is valid but should be avoided since it's considered implicit
    - Example:
    ```
    class MyClass {
        public:
        int my_public_int;
        string my_public_string;
        
        private:
        int _my_private_int;

        public:
        int my_public_int_method() {}
        ...
    }
    ```
* Always describe symbols with ddoc unless name is self-descriptive (for properties)
* **Avoid exceptions at all costs.** Prefer status return checks and if needed to return `clib.optional`
* Include copyright line at top of source file or in `REUSE.toml` for resource files or meta files
* Copyright line is subject to change!

Example of how a module would look like when adhering to those rules:
```d
// SPDX-FileCopyrightText: (C) 2024 Alisa Lain <al1-ce@null.net>
// SPDX-License-Identifier: OSL-3.0

/++
Custom clib module.
Currently an example of style to use in clib source code.
+/
module clib.custom;

import std.stdio: stdout, stdin, writeln;

import core.stdc: FILE;

import clib.string;

static import clib.vector;

public import clib.queue;

/// CustomStruct isCustom type enum
enum CustomEnum {
    ENUM_KEY_1,
    ENUM_KEY_1
}

/// Structure to do custom things
struct CustomStruct {
    /// Is custom struct
    CustomEnum is_custom;
    /// Struct index
    static int index;
    
    private int _private_index;
    private shared bool t_is_init;
    
    /// Returns private name
    @property cstring get_name() const {
        return private_name();
    }

    /// Ditto
    private cstring private_name() const {
        return cstring("my private name");
    }
}
```



