// SPDX-FileCopyrightText: (C) 2023 Alisa Lain <al1-ce@null.net>
// SPDX-License-Identifier: GPL-3.0-or-later

/++
NoGC traits

Taken directly from std.traits

Contains only things that I've deemed necessary and ensures that no
std is used because nogc

However normally it's safe to use std.traits and std.meta with nogc
+/
module clib.traits;

auto assume_nogc_nothrow(T)(T t) if (isFunctionPointer!T || isDelegate!T) {
    import std.traits;
    enum attrs = functionAttributes!T
               | FunctionAttribute.nogc
               | FunctionAttribute.nothrow_;
    return cast(SetFunctionAttributes!(T, functionLinkage!T, attrs)) t;
}

@nogc nothrow:

/**
 * Detect whether `T` is a built-in boolean type or enum of boolean base type.
 */
enum bool isBoolean(T) = __traits(isUnsigned, T) && is(T : bool);

/**
 * Detect whether `T` is a built-in integral type.
 * Integral types are `byte`, `ubyte`, `short`, `ushort`, `int`, `uint`, `long`, `ulong`, `cent`, `ucent`,
 * and enums with an integral type as its base type.
 * Params:
 *      T = type to test
 * Returns:
 *      `true` if `T` is an integral type
 * Note:
 *      this is not the same as $(LINK2 https://dlang.org/spec/traits.html#isIntegral, `__traits(isIntegral)`)
 */
template isIntegral(T)
{
    static if (!__traits(isIntegral, T))
        enum isIntegral = false;
    else static if (is(T U == enum))
        enum isIntegral = isIntegral!U;
    else
        enum isIntegral = __traits(isZeroInit, T) // Not char, wchar, or dchar.
            && !is(immutable T == immutable bool) && !is(T == __vector);
}

/**
 * Detect whether `T` is a built-in floating point type.
 *
 * See also: $(DDSUBLINK spec/traits, isFloating, `__traits(isFloating, T)`)
 */
// is(T : real) to discount complex types
enum bool isFloatingPoint(T) = __traits(isFloating, T) && is(T : real);

/**
 * Detect whether `T` is a built-in numeric type (integral or floating
 * point).
 */
template isNumeric(T)
{
    static if (!__traits(isArithmetic, T))
        enum isNumeric = false;
    else static if (__traits(isFloating, T))
        enum isNumeric = is(T : real); // Not __vector, imaginary, or complex.
    else static if (is(T U == enum))
        enum isNumeric = isNumeric!U;
    else
        enum isNumeric = __traits(isZeroInit, T) // Not char, wchar, or dchar.
            && !is(immutable T == immutable bool) && !is(T == __vector);
}

/**
 * Detect whether `T` is a scalar type (a built-in numeric, character or
 * boolean type).
 *
 * See also: $(DDSUBLINK spec/traits, isScalar, `__traits(isScalar, T)`)
 */
// is(T : real) to discount complex types
enum bool isScalarType(T) = __traits(isScalar, T) && is(T : real);

/**
 * Detect whether `T` is a basic type (scalar type or void).
 */
enum bool isBasicType(T) = isScalarType!T || is(immutable T == immutable void);

/**
 * Detect whether `T` is a built-in unsigned numeric type.
 */
template isUnsigned(T)
{
    static if (!__traits(isUnsigned, T))
        enum isUnsigned = false;
    else static if (is(T U == enum))
        enum isUnsigned = isUnsigned!U;
    else
        enum isUnsigned = __traits(isZeroInit, T) // Not char, wchar, or dchar.
            && !is(immutable T == immutable bool) && !is(T == __vector);
}

/**
 * Detect whether `T` is a built-in signed numeric type.
 */
enum bool isSigned(T) = __traits(isArithmetic, T) && !__traits(isUnsigned, T)
                                                  && is(T : real);

/**
 * Detect whether `T` is one of the built-in character types.
 *
 * The built-in char types are any of `char`, `wchar` or `dchar`, with
 * or without qualifiers.
 */
template isSomeChar(T)
{
    static if (!__traits(isUnsigned, T))
        enum isSomeChar = false;
    else static if (is(T U == enum))
        enum isSomeChar = isSomeChar!U;
    else
        enum isSomeChar = !__traits(isZeroInit, T);
}

/**
Detect whether `T` is one of the built-in string types.

The built-in string types are `Char[]`, where `Char` is any of `char`,
`wchar` or `dchar`, with or without qualifiers.

Static arrays of characters (like `char[80]`) are not considered
built-in string types.
 */
enum bool isSomeString(T) = is(immutable T == immutable C[], C) && (is(C == char) || is(C == wchar) || is(C == dchar));

/**
 * Detect whether type `T` is a narrow string.
 *
 * All arrays that use char, wchar, and their qualified versions are narrow
 * strings. (Those include string and wstring).
 */
enum bool isNarrowString(T) = is(immutable T == immutable C[], C) && (is(C == char) || is(C == wchar));

/**
 * Detects whether `T` is a comparable type. Basic types and structs and
 * classes that implement opCmp are ordering comparable.
 */
enum bool isOrderingComparable(T) = is(typeof((ref T a) => a < a ? 1 : 0));

/// ditto
enum bool isEqualityComparable(T) = is(typeof((ref T a) => a == a ? 1 : 0));

/**
 * Detect whether type `T` is a static array.
 *
 * See also: $(DDSUBLINK spec/traits, isStaticArray, `__traits(isStaticArray, T)`)
 */
enum bool isStaticArray(T) = __traits(isStaticArray, T);

/**
 * Detect whether type `T` is a dynamic array.
 */
template isDynamicArray(T)
{
    static if (is(T == U[], U))
        enum bool isDynamicArray = true;
    else static if (is(T U == enum))
        // BUG: isDynamicArray / isStaticArray considers enums
        // with appropriate base types as dynamic/static arrays
        // Retain old behaviour for now, see
        // https://github.com/dlang/phobos/pull/7574
        enum bool isDynamicArray = isDynamicArray!U;
    else
        enum bool isDynamicArray = false;
}

/**
 * Detect whether type `T` is an array (static or dynamic; for associative
 *  arrays see $(LREF isAssociativeArray)).
 */
enum bool isArray(T) = isStaticArray!T || isDynamicArray!T;

/**
 * Detect whether `T` is an associative array type
 *
 * See also: $(DDSUBLINK spec/traits, isAssociativeArray, `__traits(isAssociativeArray, T)`)
 */
enum bool isAssociativeArray(T) = __traits(isAssociativeArray, T);

/**
 * Detect whether type `T` is a builtin type.
 */
enum bool isBuiltinType(T) = is(BuiltinTypeOf!T) && !isAggregateType!T;

/**
 * Detect whether type `T` is a pointer.
 */
enum bool isPointer(T) = is(T == U*, U);

/**
Returns the target type of a pointer.
*/
alias PointerTarget(T : T*) = T;

/**
 * Detect whether type `T` is an aggregate type.
 */
enum bool isAggregateType(T) = is(T == struct) || is(T == union) ||
                               is(T == class) || is(T == interface);

/**
 * Returns `true` if T can be iterated over using a `foreach` loop with
 * a single loop variable of automatically inferred type, regardless of how
 * the `foreach` loop is implemented.  This includes ranges, structs/classes
 * that define `opApply` with a single loop variable, and builtin dynamic,
 * static and associative arrays.
 */
enum bool isIterable(T) = is(typeof({ foreach (elem; T.init) {} }));

/**
 * Returns true if T is not const or immutable.  Note that isMutable is true for
 * string, or immutable(char)[], because the 'head' is mutable.
 */
enum bool isMutable(T) = !is(T == const) && !is(T == immutable) && !is(T == inout);

/**
 * Returns true if T is an instance of the template S.
 */
enum bool isInstanceOf(alias S, T) = is(T == S!Args, Args...);
/// ditto
template isInstanceOf(alias S, alias T)
{
    enum impl(alias T : S!Args, Args...) = true;
    enum impl(alias T) = false;
    enum isInstanceOf = impl!T;
}

/**
 * Check whether the tuple T is an expression tuple.
 * An expression tuple only contains expressions.
 *
 * See_Also: $(LREF isTypeTuple).
 */
template isExpressions(T...)
{
    static foreach (Ti; T)
    {
        static if (!is(typeof(isExpressions) == bool) && // not yet defined
                   (is(Ti) || !__traits(compiles, { auto ex = Ti; })))
        {
            enum isExpressions = false;
        }
    }
    static if (!is(typeof(isExpressions) == bool)) // if not yet defined
    {
        enum isExpressions = true;
    }
}

/**
 * Check whether the tuple `T` is a type tuple.
 * A type tuple only contains types.
 *
 * See_Also: $(LREF isExpressions).
 */
enum isTypeTuple(T...) =
{
    static foreach (U; T)
        static if (!is(U))
            if (__ctfe)
                return false;
    return true;
}();

/**
Detect whether symbol or type `T` is a function pointer.
 */
enum bool isFunctionPointer(alias T) = is(typeof(*T) == function);

/**
Detect whether symbol or type `T` is a delegate.
*/
enum bool isDelegate(alias T) = is(typeof(T) == delegate) || is(T == delegate);

/**
Detect whether symbol or type `T` is a function, a function pointer or a delegate.

Params:
    T = The type to check
Returns:
    A `bool`
 */
enum bool isSomeFunction(alias T) =
    is(T == return) ||
    is(typeof(T) == return) ||
    is(typeof(&T) == return); // @property

/**
Detect whether `T` is a callable object, which can be called with the
function call operator `$(LPAREN)...$(RPAREN)`.
 */
template isCallable(alias callable)
{
    static if (is(typeof(&callable.opCall) == delegate))
        // T is a object which has a member function opCall().
        enum bool isCallable = true;
    else static if (is(typeof(&callable.opCall) V : V*) && is(V == function))
        // T is a type which has a static member function opCall().
        enum bool isCallable = true;
    else static if (is(typeof(&callable.opCall!()) TemplateInstanceType))
    {
        enum bool isCallable = isCallable!TemplateInstanceType;
    }
    else static if (is(typeof(&callable!()) TemplateInstanceType))
    {
        enum bool isCallable = isCallable!TemplateInstanceType;
    }
    else
    {
        enum bool isCallable = isSomeFunction!callable;
    }
}

/**
Detect whether `S` is an abstract function.

See also: $(DDSUBLINK spec/traits, isAbstractFunction, `__traits(isAbstractFunction, S)`)
Params:
    S = The symbol to check
Returns:
    A `bool`
 */
enum isAbstractFunction(alias S) = __traits(isAbstractFunction, S);

/**
 * Detect whether `S` is a final function.
 *
 * See also: $(DDSUBLINK spec/traits, isFinalFunction, `__traits(isFinalFunction, S)`)
 */
enum isFinalFunction(alias S) = __traits(isFinalFunction, S);

/**
Determines if `f` is a function that requires a context pointer.

Params:
    f = The type to check
Returns
    A `bool`
*/
template isNestedFunction(alias f)
{
    enum isNestedFunction = __traits(isNested, f) && isSomeFunction!(f);
}

/**
 * Detect whether `S` is an abstract class.
 *
 * See also: $(DDSUBLINK spec/traits, isAbstractClass, `__traits(isAbstractClass, S)`)
 */
enum isAbstractClass(alias S) = __traits(isAbstractClass, S);

/**
 * Detect whether `S` is a final class.
 *
 * See also: $(DDSUBLINK spec/traits, isFinalClass, `__traits(isFinalClass, S)`)
 */
enum isFinalClass(alias S) = __traits(isFinalClass, S);

//::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::://
// General Types
//::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::://

import core.internal.traits : CoreUnconst = Unconst;
alias Unconst = CoreUnconst;

/++
    Removes `shared` qualifier, if any, from type `T`.

    Note that while `immutable` is implicitly `shared`, it is unaffected by
    Unshared. Only explict `shared` is removed.
  +/
template Unshared(T)
{
    static if (is(T == shared U, U))
        alias Unshared = U;
    else
        alias Unshared = T;
}

import core.internal.traits : CoreUnqual = Unqual;
alias Unqual = CoreUnqual;

/**
Returns the inferred type of the loop variable when a variable of type T
is iterated over using a `foreach` loop with a single loop variable and
automatically inferred return type.  Note that this may not be the same as
`std.range.ElementType!Range` in the case of narrow strings, or if T
has both opApply and a range interface.
*/
template ForeachType(T)
{
    alias ForeachType = typeof(
    (inout int x = 0)
    {
        foreach (elem; T.init)
        {
            return elem;
        }
        assert(0);
    }());
}

/**
 * Strips off all `enum`s from type `T`.
 */
template OriginalType(T)
{
    import core.internal.traits : _OriginalType = OriginalType;
    alias OriginalType = _OriginalType!T;
}

/**
Params:
    T = A built in integral or vector type.

Returns:
    The corresponding unsigned numeric type for `T` with the
    same type qualifiers.

    If `T` is not a integral or vector, a compile-time error is given.
 */
template Unsigned(T)
{
    template Impl(T)
    {
        static if (is(T : __vector(V[N]), V, size_t N))
            alias Impl = __vector(Impl!V[N]);
        else static if (isUnsigned!T)
            alias Impl = T;
        else static if (isSigned!T && !isFloatingPoint!T)
        {
            static if (is(T == byte )) alias Impl = ubyte;
            static if (is(T == short)) alias Impl = ushort;
            static if (is(T == int  )) alias Impl = uint;
            static if (is(T == long )) alias Impl = ulong;
            static if (is(ucent) && is(T == cent )) alias Impl = ucent;
        }
        else
            static assert(false, "Type " ~ T.stringof ~
                                 " does not have an Unsigned counterpart");
    }

    alias Unsigned = ModifyTypePreservingTQ!(Impl, OriginalType!T);
}

/**
Returns the largest type, i.e. T such that T.sizeof is the largest.  If more
than one type is of the same size, the leftmost argument of these in will be
returned.
*/
template Largest(T...)
if (T.length >= 1)
{
    alias Largest = T[0];
    static foreach (U; T[1 .. $])
        Largest = Select!(U.sizeof > Largest.sizeof, U, Largest);
}

/**
Returns the corresponding signed type for T. T must be a numeric integral type,
otherwise a compile-time error occurs.
 */
template Signed(T)
{
    template Impl(T)
    {
        static if (is(T : __vector(V[N]), V, size_t N))
            alias Impl = __vector(Impl!V[N]);
        else static if (isSigned!T)
            alias Impl = T;
        else static if (isUnsigned!T)
        {
            static if (is(T == ubyte )) alias Impl = byte;
            static if (is(T == ushort)) alias Impl = short;
            static if (is(T == uint  )) alias Impl = int;
            static if (is(T == ulong )) alias Impl = long;
            static if (is(ucent) && is(T == ucent )) alias Impl = cent;
        }
        else
            static assert(false, "Type " ~ T.stringof ~
                                 " does not have an Signed counterpart");
    }

    alias Signed = ModifyTypePreservingTQ!(Impl, OriginalType!T);
}

/**
Returns the most negative value of the numeric type T.
*/
template mostNegative(T)
if (isNumeric!T || isSomeChar!T || isBoolean!T)
{
    static if (is(typeof(T.min_normal)))
        enum mostNegative = -T.max;
    else static if (T.min == 0)
        enum byte mostNegative = 0;
    else
        enum mostNegative = T.min;
}

/**
Get the type that a scalar type `T` will $(LINK2 $(ROOT_DIR)spec/type.html#integer-promotions, promote)
to in multi-term arithmetic expressions.
*/
template Promoted(T)
if (isScalarType!T)
{
    alias Promoted = CopyTypeQualifiers!(T, typeof(T.init + T.init));
}

/++
    Determine if a symbol has a given
    $(DDSUBLINK spec/attribute, uda, user-defined attribute).

    See_Also:
        $(LREF getUDAs)
  +/
enum hasUDA(alias symbol, alias attribute) = getUDAs!(symbol, attribute).length != 0;

/++
    Gets the matching $(DDSUBLINK spec/attribute, uda, user-defined attributes)
    from the given symbol.

    If the UDA is a type, then any UDAs of the same type on the symbol will
    match. If the UDA is a template for a type, then any UDA which is an
    instantiation of that template will match. And if the UDA is a value,
    then any UDAs on the symbol which are equal to that value will match.

    See_Also:
        $(LREF hasUDA)
  +/
template getUDAs(alias symbol, alias attribute)
{
    import std.meta : Filter;

    alias getUDAs = Filter!(isDesiredUDA!attribute, __traits(getAttributes, symbol));
}

private template isDesiredUDA(alias attribute)
{
    template isDesiredUDA(alias toCheck)
    {
        static if (is(typeof(attribute)) && !__traits(isTemplate, attribute))
        {
            static if (__traits(compiles, toCheck == attribute))
                enum isDesiredUDA = toCheck == attribute;
            else
                enum isDesiredUDA = false;
        }
        else static if (is(typeof(toCheck)))
        {
            static if (__traits(isTemplate, attribute))
                enum isDesiredUDA =  isInstanceOf!(attribute, typeof(toCheck));
            else
                enum isDesiredUDA = is(typeof(toCheck) == attribute);
        }
        else static if (__traits(isTemplate, attribute))
            enum isDesiredUDA = isInstanceOf!(attribute, toCheck);
        else
            enum isDesiredUDA = is(toCheck == attribute);
    }
}

/**
Params:
    symbol = The aggregate type or module to search
    attribute = The user-defined attribute to search for

Returns:
    All symbols within `symbol` that have the given UDA `attribute`.

Note:
    This is not recursive; it will not search for symbols within symbols such as
    nested structs or unions.
 */
template getSymbolsByUDA(alias symbol, alias attribute)
{
    alias membersWithUDA = getSymbolsByUDAImpl!(symbol, attribute, __traits(allMembers, symbol));

    // if the symbol itself has the UDA, tack it on to the front of the list
    static if (hasUDA!(symbol, attribute))
        alias getSymbolsByUDA = AliasSeq!(symbol, membersWithUDA);
    else
        alias getSymbolsByUDA = membersWithUDA;
}

private template getSymbolsByUDAImpl(alias symbol, alias attribute, names...)
{
    import std.meta : Alias, AliasSeq, Filter;
    static if (names.length == 0)
    {
        alias getSymbolsByUDAImpl = AliasSeq!();
    }
    else
    {
        alias tail = getSymbolsByUDAImpl!(symbol, attribute, names[1 .. $]);

        // Filtering inaccessible members.
        static if (!__traits(compiles, __traits(getMember, symbol, names[0])))
        {
            alias getSymbolsByUDAImpl = tail;
        }
        else
        {
            alias member = __traits(getMember, symbol, names[0]);

            // Filtering not compiled members such as alias of basic types.
            static if (isAliasSeq!member ||
                       (isType!member && !isAggregateType!member && !is(member == enum)))
            {
                alias getSymbolsByUDAImpl = tail;
            }
            // If a symbol is overloaded, get UDAs for each overload (including templated overlaods).
            else static if (__traits(getOverloads, symbol, names[0], true).length > 0)
            {
                enum hasSpecificUDA(alias member) = hasUDA!(member, attribute);
                alias overloadsWithUDA = Filter!(hasSpecificUDA, __traits(getOverloads, symbol, names[0]));
                alias getSymbolsByUDAImpl = AliasSeq!(overloadsWithUDA, tail);
            }
            else static if (hasUDA!(member, attribute))
            {
                alias getSymbolsByUDAImpl = AliasSeq!(member, tail);
            }
            else
            {
                alias getSymbolsByUDAImpl = tail;
            }
        }
    }
}

/**
   Returns: `true` iff all types `Ts` are the same.
*/
enum bool allSameType(Ts...) =
{
    static foreach (T; Ts[Ts.length > 1 .. $])
        static if (!is(Ts[0] == T))
            if (__ctfe)  // Dodge the "statement is unreachable" warning
                return false;
    return true;
}();

/**
 * Detect whether `X` is a type. Analogous to `is(X)`. This is useful when used
 * in conjunction with other templates, e.g. `allSatisfy!(isType, X)`.
 *
 * Returns:
 *      `true` if `X` is a type, `false` otherwise
 */
enum isType(alias X) = is(X);

/**
 * Detect whether symbol or type `X` is a function. This is different that finding
 * if a symbol is callable or satisfying `is(X == function)`, it finds
 * specifically if the symbol represents a normal function declaration, i.e.
 * not a delegate or a function pointer.
 *
 * Returns:
 *     `true` if `X` is a function, `false` otherwise
 *
 * See_Also:
 *     Use $(LREF isFunctionPointer) or $(LREF isDelegate) for detecting those types
 *     respectively.
 */
template isFunction(alias X)
{
    static if (is(typeof(&X) U : U*) && (is(U == function) ||
               is(typeof(&X) U == delegate)))
    {
        // x is a (nested) function symbol.
        enum isFunction = true;
    }
    else static if (is(X T))
    {
        // x is a type.  Take the type of it and examine.
        enum isFunction = is(T == function);
    }
    else
        enum isFunction = false;
}

/**
 * Detect whether `X` is a final method or class.
 *
 * Returns:
 *     `true` if `X` is final, `false` otherwise
 */
template isFinal(alias X)
{
    static if (is(X == class))
        enum isFinal = __traits(isFinalClass, X);
    else static if (isFunction!X)
        enum isFinal = __traits(isFinalFunction, X);
    else
        enum isFinal = false;
}

/++
 + Determines whether the type `S` can be copied.
 + If a type cannot be copied, then code such as `MyStruct x; auto y = x;` will fail to compile.
 + Copying for structs can be disabled by using `@disable this(this)`.
 +
 + See also: $(DDSUBLINK spec/traits, isCopyable, `__traits(isCopyable, S)`)
 + Params:
 +  S = The type to check.
 +
 + Returns:
 +  `true` if `S` can be copied. `false` otherwise.
 +/
enum isCopyable(S) = __traits(isCopyable, S);

