# cppd
c++ stdlib and utils for D with betterC

## Modules (mostly from c++ std) and why
- allocator (own) - Minimal allocator to allow custom allocators to be used with other modules (currently just a wrapper over malloc)
- vector (std::vector) - Because apparently D arrays are very much relying on GC, for example you wouldn't be able to go about and @nogc array.reserve(size) because it suddenly needs TypeInfo!
- set (std::set) - Once again, D arrays are heavily GC so gotta have this (NOT YET IMPLEMENTED) 
- betterc (own) - Just a small amout of utilities to make classes work with betterC (which you would use with extern(C++) classes)

