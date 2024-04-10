# clib
c++ stdlib and utils for D with betterC

<!--toc:start-->
- [Why](#why)
- [C++ STL implementation list](#c-stl-implementation-list)
- [C++ utils implementation](#c-utils-implementation)
- [C++ containers implementation](#c-containers-implementation)
- [BetterC](#betterc)
<!--toc:end-->

## Why
D's standard library isn't really noGC and betterC friendly, so, why not make somewhat of a -betterC compatible runtime.

And why it's called clib? Because it's a better**CLib**rary. But, despite the name it's mainly noGC library with small amount betterC utilities.

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
- [ ] memory (""partially implemented"" with ""allocator"")
- [ ] numeric
- [ ] ostream
- [ ] sstream
- [ ] stdexcept
- [ ] streambuf
- [ ] strstream
- [x] typeinfo (requires hacks due to angry TypeInfo)
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

## BetterC
Can be enabled when using `clib:betterc` as dependency instead of `clib`. Everything is same with exception of that `clib:betterc` compiles with `-betterC` flag, which will prevent linkage errors.

### On classes
D's keyword `new` can't be used with -betterC since it uses TypeInfo and to "fix" that there's a module named `classes`. As of now it contains three functions: `_new`, `_free` and `_cast` which can be used to use classes with -betterC.

#### IMPORTANT 1:
There's a way to use classes without `classes` module. Instantiate your classes as:
```d
__gshared CppClass c = new CppClass();
```

#### IMPORTANT 2:
If you want some alternative to D's `typeid` and `TypeInfo` then import `clib.typeinfo` and derive all your classes from `cppObject`. Albeit `type_info` can't provide with everything that `TypeInfo` provides since D does not provide any RTTI for C++ classes. Example of usage:
```d
import clib.typeinfo;

class CppRTTI: cppObject {
    mixin RTTI!cppObject;
}
class ChildCppRTTI: CppRTTI {
    mixin RTTI!CppRTTI;
}

ChildCppRTTI cprt;
if (_typeid(cprt) != _typeid!CppRTTI) printf("Not same\n");
if (_typeid!CppRTTI().isBaseOf(cprt)) printf("Is child\n");
```

#### new
`_new` can be used to construct class and allocate memory for it
```d
extern(C++) interface ICpp {  }
extern(C++) class CppClass: ICpp {  }

CppClass c = _new!CppClass();
```

`_free` can be used to forcefully free class
```d
/// Any of those will work
_free(c);
c._free();
```

`clib.typecast` can be used to work around [known bug](https://issues.dlang.org/show_bug.cgi?id=21690)
```d
import clib.typecast;
reinterpret_cast!ICpp(t).icppFunc();
somefunc( t.reinterpret_cast!ICpp );
```

It is important to know that -betterC places a lot of contraints. Most important ones are `new` keyword and no dynamic casts. `new` can be easily replaced with `_new!` or `__gshared ...`, but for dynamic casts you have to work around it unless `#21690` will be fixed
```d
void testBaseFunc(ICpp base) {
    base.baseFunc();
    reinterpret_cast!ICpp(base).baseFunc(); // doesn't matter as it's already ICpp
}

testBaseFunc(c); // will case segfault!!!
testBaseFunc(reinterpret_cast!ICpp(base)); // must be a reinterpret cast
reinterpret_cast!ICpp(base).testBaseFunc(); // or treat it as member
```

