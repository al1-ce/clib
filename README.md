# cppd
c++ stdlib and utils for D with betterC

## Modules (mostly from c++ std) and why
- allocator (own) - Minimal allocator to allow custom allocators to be used with other modules (currently just a wrapper over malloc)
- betterc (own) - Just a small amout of utilities to make classes work with betterC (which you would use with extern(C++) classes)
- optional (std::optional) - TypeInfo is not noGC compatible
- set (std::set) - Once again, D arrays are heavily GC so gotta have this 
- vector (std::vector) - Because apparently D arrays are very much relying on GC, for example you wouldn't be able to go about and @nogc array.reserve(size) because it suddenly needs TypeInfo!

## Other
Modules that are copied from c++ STL are close to what you'd have in c++, meaning you'd usually will be able to translate c++ code to D + cppd code without any problem

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
