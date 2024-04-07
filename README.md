# cppd
c++ stdlib and utils for D with betterC

## Modules (mostly from c++ std) and why
- allocator (own) - Minimal allocator to allow custom allocators to be used with other modules (currently just a wrapper over malloc)
- classes (own) - Just a small amout of utilities to make classes work with betterC (which you would use with extern(C++) classes)
- optional (std::optional) - TypeInfo is not noGC compatible
- set (std::set) - Once again, D arrays are heavily GC so gotta have this 
- vector (std::vector) - Because apparently D arrays are very much relying on GC, for example you wouldn't be able to go about and @nogc array.reserve(size) because it suddenly needs TypeInfo!

## Other
Modules that are copied from c++ STL are close to what you'd have in c++, meaning you'd usually will be able to translate c++ code to D + cppd code without any problem

## On classes
D's keyword `new` can't be used with -betterC since it uses TypeInfo and to "fix" that there's a module named `classes`. As of now it contains three functions: `_new`, `_free` and `_cast` which can be used to use classes with -betterC

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

`cppd.typecast.reinterpretCast` is used to work around [known bug](https://issues.dlang.org/show_bug.cgi?id=21690), inside it's actually just a reinterpret cast (`cast(T) cast(void*) t`)
```d
import cppd.typecast;
reinterpretCast!ICpp(t).icppFunc();
somefunc( t.reinterpretCast!ICpp );
```

It is important to know that -betterC places a lot of contraints. Most important ones are `new` keyword and no dynamic casts. `new` can be easily replaced with `_new!`, but for dynamic casts you have to work around it unless `#21690` will be fixed
```d
void testBaseFunc(ICpp base) {
    base.baseFunc();
    reinterpretCast!ICpp(base).baseFunc(); // doesn't matter as it's already ICpp
}

testBaseFunc(c); // will case segfault!!!
testBaseFunc(reinterpretCast!ICpp(base)); // must be a reinterpret cast
reinterpretCast!ICpp(base).testBaseFunc(); // or treat it as member
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
- [ ] typeinfo
- [ ] utility
- [ ] valarray
- [x] vector

## C++ utils implementation
- [x] optional

## C++ containers implementation
TODO: separate STL into own libs
