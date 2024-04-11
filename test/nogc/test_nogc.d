import clib;

import core.stdc.stdio;

extern(C) __gshared string[] rt_options = [ "gcopt=disable:1" ];
void main(string[] args) @nogc nothrow {
    // { import core.memory; GC.disable(); }

    printf("Starting NOGC tests\n\n");
    class TestParent {}
    interface ITest {}
    class TestClass: TestParent, ITest { this() @nogc nothrow {} int i = 2; }

    __gshared TestClass tc = new TestClass();
    CppObject cp = _new!CppObject();
    TestClass s = _new!TestClass();
    printf("%i\n", s.i);
    TypeInfo ti = typeid(tc);
    _free(cp);
    _free(s);
    printf("%s\n", typeid(tc).name.ptr);
    printf("%s\n", _typeid(cp).name);
    printf("\n");

    printf("No need to test type_info since it's GC compatible\n");
    printf("Ending tests\n");
}

immutable(char)[] asString(bool val) {
    return val ? "true" : "false";
}
