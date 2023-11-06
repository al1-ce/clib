# cppd
c++ stdlib and utils for D with betterC

## Modules (mostly from c++ std) and why
- vector (std::vector) - Because apparently D arrays are very much relying on GC, for example you wouldn't be able to go about and @nogc array.reserve(size) because it suddenly needs TypeInfo!
- set (std::set) - D doesn't really have this kind of concept, so, why not 
- betterc (own) - Just a small amout of utilities to make classes work with betterC (which you would use with extern(C++) classes)

