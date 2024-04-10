import clib;

import core.stdc.stdio;

extern(C++) {
    class CppClass: cppObject {
        mixin RTTI!cppObject;
        this(int p_a, char* p_b) @nogc nothrow {
            a = p_a;
            b = p_b;
        }

        ~this() @nogc nothrow {
            destroy!false(b);
        }

        int a;
        char* b;
        bool c = true;

        int get() { return a; }
    }

    class CppClassSecond: CppClass {
        mixin RTTI!CppClass;
        this() @nogc nothrow { super(2, cast(char*) "a".ptr); }
        bool e = true;
    }

    interface L {
        void testLFunc();
    }

    class Base: L {
        this() @nogc nothrow {
            puts("base construct");
        }

        override void testLFunc() {
            puts("call override function");
        }

        void testBaseFunc() {
            puts("call Base function");
        }

        ~this() @nogc nothrow  {
            puts("base close");
        }
    }

    class Test: Base {
        int i;
        int y;

        this(int i, int y) @nogc nothrow {
            this.i= i;
            this.y = y;
        }

        ~this() @nogc nothrow  {
            puts("hello world");
        }
    }

}

void testLFunc(L base) {
    base.testLFunc();
}

/// Does not work
void testLCase(L base) {
    reinterpret_cast!L(base).testLFunc();
}

extern(C) __gshared string[] rt_options = [ "gcopt=disable:1" ];
// extern(C) void main(int argc, char** argv) {
void main(string[] args) {

    // { import core.memory; GC.disable(); }
    printf("Starting tests\n\n");

    printf("Testing extern(C++) class\n");
    CppClass cppClass = _new!CppClass(2, cast(char*) "Hello world".ptr);
    CppClassSecond cppClassSecond = _new!CppClassSecond();

    CppClass co = new CppClass(2, cast(char*) "a".ptr);
    import core.stdc.stdlib: free;
    printf("%s, %i, %i, %i\n", cppClass.b, cppClass.a, cppClass.c, cppClassSecond.get());

    _free(cppClass);
    _free(cppClassSecond);
    printf("\n");

    Test t = _new!Test(20, 40);
    printf("t.i is => %d\n", t.i);
    t.testLFunc();
    (cast(L) cast(void*) t).testLFunc();
    reinterpret_cast!L(t).testLFunc();
    testLFunc(t.reinterpret_cast!L);
    t.reinterpret_cast!L().testLCase();
    // testLCase(t);
    _free(t);
    printf("\n");

    printf("TESTING TYPEINFO\n");
    import core.internal.traits;

    cppObject c = _new!cppObject;
    CppClass cp = _new!CppClass(1, cast(char*) "t".ptr);
    cppObject cn = _new!CppClass(1, cast(char*) "t".ptr);
    printf("hasMember - %s\n", __traits(hasMember, cppObject, "___type_info_identifier").asString.ptr);
    printf("typeid.c.name - %s\n", _typeid(c).name);
    printf("typeid.cp.name - %s\n", _typeid(cp).name);
    printf("c.toString - %s\n", c.toString());
    printf("c == cp - %s\n", (c == cp).asString.ptr);
    printf("typeid eq - %s\n", (_typeid(cn) == _typeid!CppClass).asString.ptr);
    printf("typeid eq c - %s\n", (_typeid(cn) == c).asString.ptr);
    printf("is child - %s\n", (__traits(compiles, cast(Base) cp)).asString.ptr);
    _free(c);
    _free(cp);
    _free(cn);
    printf("asString.typeid.name - %s\n", _typeid(&asString).name);
    int* testPtr;
    printf("testPtr.typeid.name - %s\n", _typeid(testPtr).name);
    printf("cptr.typeid.name - %s\n", _typeid((&c)).name);

    __gshared cppObject cv = new cppObject();

    printf("%s\n",
        __traits(hasMember, CppClass, "__clib_typeinfo_cppObject_clib_parent").asString.ptr
    );

    foreach (e; __traits(allMembers, CppClass)) {
        printf("%s\n", e.ptr);
    }

    printf("%s\n", _typeid!cppObject.isBaseOf!CppClass().asString.ptr);
    printf("%s\n", _typeid!CppClass.isBaseOf!cppObject().asString.ptr);

    printf("\n");
    printf("Ending tests\n");
}

void setInfo(T)(T* _data, size_t size ){
    printf("set.data        = ");
    for (int i = 0; i < size; ++i) { printf("%i ", _data[i]); }
    printf("\n");
}

void setstrInfo(T)(T* _data, size_t size ){
    printf("set.data        = ");
    for (int i = 0; i < size; ++i) { printf("%s ", _data[i]); }
    printf("\n");
}

void vectorInfo(T)(vector!T* vec) {
    printf("vector.capacity = %llu\n", vec.capacity);
    printf("vector.size     = %llu\n", vec.size);
    printf("vector.data     = ");
    for (int i = 0; i < vec.size; ++i) { printf("%i ", vec.data()[i]); }
    printf("\n");
}

immutable(char)[] asString(bool val) {
    return val ? "true" : "false";
}
