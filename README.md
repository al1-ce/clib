# clib
c++ stdlib and utils for D with noGC

## Why
D's standard library isn't really noGC friendly, so, why not make somewhat of a noGC compatible runtime.

And why it's called clib? Because it's a better**CLib**rary. But, despite the name it's mainly noGC library.

<!--TODO: wiki --> TODO: a Wiki or something like it.

## Most of clib's C++ STL features are PRE C++11
I consider those features to be most essential. C++11 features will probably come after base features. Same for later C++ versions.

## C++ STL implementation list
- [ ] algorithm
- [ ] complex
- [-] exception (partially implemented, but more as release-compatible asserts)
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
- [-] memory (partially implemented, has Mallocator, `_new` and `_free`)
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
- [-] deque (do not plan to implement it, not sure how to be completely honest, PR's are welcome though)
- [ ] list
- [ ] map
- [x] queue
- [x] set
- [x] stack
- [x] string (technically is an alias to `vector!char` with static if shenanigans. WIP)
- [-] valarray (same as deque)
- [x] vector

# Custom modules
- [-] format (exists in C++20 specs, but my version currently is for emulating c's format function)
- [-] conv (just your normal type conversion)

## On classes
D's keyword `new` can't be used with noGC and to "fix" that there's two functions: `_new` and `_free` in `clib.memory` which can be used to create classes with noGC.

`clib.memory._new` can be used to construct class and allocate memory for it and `_free` can be used to forcefully free class.
```d
import clib.memory;
class Class {}

void main() @nogc {
    Class c = _new!Class();
    _free(c);
}
```

## extern(C++)
### TypeInfo (only use for extern(C++) classes)
To enable add `versions "CLIB_USE_TYPEINFO"` to `dub.sdl` or `-version=CLIB_USE_TYPEINFO` as compiler flag. 

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

`clib.typeinfo.reinterpret_cast` can be used to work around [known bug](https://issues.dlang.org/show_bug.cgi?id=21690).
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

## Development
- [dmd / ldc / gdc](https://dlang.org/) - D compiler
- [dub](https://code.dlang.org/) - D package manager
- [just](https://github.com/casey/just) - Make system
- [valgrind](https://valgrind.org/) - Memory checker
- [reuse](https://reuse.software/) - See [License](#license)

## Contributing
See [CONTRIBUTING.md](CONTRIBUTING.md).

## License
- Copy of used licenses can be found in `LICENSES` folder. Main license can be found in [LICENSE](LICENSE) file.
- List of authors can be found in [AUTHORS.md](/AUTHORS.md).

This project is [REUSE](https://reuse.software/) compliant.

