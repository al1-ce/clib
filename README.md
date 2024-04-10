# clib
c++ stdlib and utils for D with betterC

## Why
D's standard library isn't really noGC and especially betterC friendly, so, why not make somewhat of a -betterC compatible runtime.

And why it's called clib? Because it's a better**CLib**rary

## Modules (mostly from c++ std)
- allocator (own) - Minimal allocator to allow custom allocators to be used with other modules (currently just a wrapper over malloc)
- classes (own) - Just a small amout of utilities to make classes work with betterC (which you would use with extern(C++) classes)
- optional (std::optional) - TypeInfo is not noGC compatible
- vector (std::vector) - Because apparently D arrays are very much relying on GC, for example you wouldn't be able to go about and @nogc array.reserve(size) because it suddenly needs TypeInfo!
- set (std::set) - Once again, D arrays are heavily GC so gotta have this 

## Other
Modules that are copied from c++ STL are close to what you'd have in c++, meaning you'd usually will be able to translate c++ code to D + cpp code without any problem

## On classes
D's keyword `new` can't be used with -betterC since it uses TypeInfo and to "fix" that there's a module named `classes`. As of now it contains three functions: `_new`, `_free` and `_cast` which can be used to use classes with -betterC.

### IMPORTANT 1:
There's a way to use classes without `classes` module. Instantiate your classes as:
```d
__gshared CppClass c = new CppClass();
```

### IMPORTANT 2:
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

### _new
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

## C++ STL implementation list
- [ ] algorithm
- [ ] bitset
- [ ] complex
- [ ] deque
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
- [ ] list
- [ ] locale
- [ ] map
- [ ] memory (""partially implemented"" with ""allocator"")
- [ ] new
- [ ] numeric
- [ ] ostream
- [ ] queue
- [x] set
- [ ] sstream
- [ ] stack
- [ ] stdexcept
- [ ] streambuf
- [ ] string
- [ ] strstream
- [ ] typeinfo (requires hacks due to linkage errors)
- [ ] utility
- [ ] valarray
- [x] vector

## C++ utils implementation
- [x] optional

## C++ containers implementation
TODO: separate STL into own libs
