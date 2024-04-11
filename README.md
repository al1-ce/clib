# clib
c++ stdlib and utils for D with NoGC and BetterC

## Why
D's standard library isn't really NoGC and betterC friendly, so, why not make somewhat of a -betterC compatible runtime.

And why it's called clib? Because it's a better**CLib**rary. But, despite the name it's mainly NoGC library with small amount betterC utilities.

<!--TODO: wiki --> TODO: a Wiki or something like it.

## Most of clib's C++ STL features are PRE C++11
I consider those features to be most essential. C++11 features will probably come after base features. Same for later C++ versions.

## C++ STL implementation list
- [ ] algorithm
- [ ] complex
- [ ] exception
- [ ] fstream
- [ ] functional
- [ ] iomanip
- [ ] ios
- [ ] iosfwd
- [ ] iostream
- [ ] istream
- [ ] iterator
- [ ] limits
- [ ] locale
- [ ] memory ("partially implemented")
- [ ] numeric
- [ ] ostream
- [ ] sstream
- [ ] stdexcept
- [ ] streambuf
- [ ] strstream
- [x] typeinfo (used only for extern(C++) classes)
- [ ] utility

## C++ utils implementation
- [ ] bitset
- [x] optional

## C++ containers implementation
- [ ] deque
- [ ] list
- [ ] map
- [ ] queue
- [x] set
- [ ] stack
- [x] string (technically is an alias to `vector!char` with static if shenanigans. WIP)
- [ ] valarray
- [x] vector

## On classes
D's keyword `new` can't be used with NoGC and to "fix" that there's two functions: `_new` and `_free` in `clib.memory` which can be used to create classes with NoGC (and -betterC).

`clib.memory._new` can be used to construct class and allocate memory for it and `_free` can be used to forcefully free class.
```d
import clib.memory;
class Class {}

void main() @nogc {
    Class c = _new!Class();
    _free(c);
}
```

## BetterC (EVERYTHING BELOW IS RELATED TO BETTERC)
Can be enabled when using `clib:betterc` as dependency instead of `clib`. Everything is same with exception of that `clib:betterc` compiles with `-betterC` flag, which will prevent linkage errors.

### Typecast
`clib.typecast` can be used to work around [known bug](https://issues.dlang.org/show_bug.cgi?id=21690).
```d
import core.stdc.stdio;
import clib.typecast;
import clib.memory;

extern(C++) class ICpp: CppObject {
    void baseFunc() @nogc nothrow { printf("ICpp func\n"); }
}

extern(C++) class CppClass: ICpp {
    mixin RTTI!ICpp;
    override void baseFunc() @nogc nothrow { printf("CppClass func\n"); }
}

extern(C) int main() @nogc nothrow {
    CppClass c = _new!CppClass();

    void testBaseFunc(ICpp base) {
        base.baseFunc();
        reinterpret_cast!ICpp(base).baseFunc(); // doesn't matter as it's already ICpp
    }

    testBaseFunc(c); // will case segfault!!!
    testBaseFunc(reinterpret_cast!ICpp(c)); // must be a cast
    reinterpret_cast!ICpp(c).testBaseFunc(); // or treat it as member
}
```

### TypeInfo
If you want some alternative to D's `typeid` and `TypeInfo` on `extern(C++)` classes then import `clib.typeinfo` and derive all your classes from `CppObject`. Albeit `type_info` can't provide with everything that `TypeInfo` provides since D does not provide any RTTI for C++ classes. Example of usage:
```d
import clib.typeinfo;

// D way:
class DClass {}
class DChild: DClass{}
DChild dprt;
if (typeid(dprt) != typeid(DClass)) printf("Not same\n");
if (typeid(DClass).isBaseOf(typeid(DChild))) printf("Is child\n");

// Clib way:

class CClass: CppObject {
    // No need to do it for CppObject!
    // mixin RTTI!CppObject;
}
class CChild: CClass{
    // Must be done for each parent, including interfaces
    // but excluding CppObject
    mixin RTTI!CClass;
}

CChild cprt;
if (_typeid(cprt) != _typeid!CClass) printf("Not same\n");
if (_typeid!CClass().isBaseOf(cprt)) printf("Is child\n");
```

