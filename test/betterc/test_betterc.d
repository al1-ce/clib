import clib;

import core.stdc.stdio;

extern(C++) {
    class CppClass: CppObject {
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

    class Base: CppObject, L {
        mixin RTTI!L;
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
        mixin RTTI!Base;
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

extern(C) void main(int argc, char** argv) {
    printf("Starting BETTERC tests\n\n");

    printf("Testing extern(C++) class\n");
    CppClass cppClass = _new!CppClass(2, cast(char*) "Hello world".ptr);
    CppClassSecond cppClassSecond = _new!CppClassSecond();

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

    CppClass cp = _new!CppClass(1, cast(char*) "t".ptr);
    CppObject cn = _new!CppClass(1, cast(char*) "t".ptr);
    printf("hasMember - %s\n",        __traits(hasMember, CppObject, "___type_info_identifier").asString.ptr);
    printf("typeid.cp.name - %s\n", _typeid(cp).name);
    printf("typeid eq - %s\n", (_typeid(cn) == _typeid!CppClass).asString.ptr);
    printf("is child - %s\n", (__traits(compiles, cast(Base) cp)).asString.ptr);
    _free(cp);
    _free(cn);
    printf("asString.typeid.name - %s\n", _typeid(&asString).name);
    int* testPtr;
    printf("testPtr.typeid.name - %s\n", _typeid(testPtr).name);

    printf("%s\n",
        __traits(hasMember, CppClass, "__clib_typeinfo_CppObject_clib_parent").asString.ptr
    );

    foreach (e; __traits(allMembers, CppClass)) {
        printf("%s\n", e.ptr);
    }

    printf("%s\n", _typeid!CppObject.isBaseOf!CppClass().asString.ptr);
    printf("%s\n", _typeid!CppClass.isBaseOf!CppObject().asString.ptr);

    extern(C++) interface ICppe {}
    extern(C++) class Cppe: CppObject, ICppe {
        mixin RTTI!ICppe;
    }
    printf("child?false: %s\n", isAChild!(ICppe, Cppe).asString.ptr);
    printf("child?true: %s\n", isAChild!(Cppe, ICppe).asString.ptr);
    printf("child?true: %s\n", isAChild!(CppClass, CppObject).asString.ptr);
    printf("child?false: %s\n", isAChild!(Cppe, CppClass).asString.ptr);
    printf("sizeof Cppe: %llu\n", Cppe.sizeof);

    printf("\n");
    version(D_BetterC) { printf("Test BetterC autoversion\n"); }

    extern(C++) class ICppd: CppObject {
        void baseFunc() @nogc nothrow { printf("ICpp func\n"); }
    }

    extern(C++) class CppClassd: ICppd {
        mixin RTTI!ICppd;
        override void baseFunc() @nogc nothrow { printf("CppClass func\n"); }
    }

    CppClassd c = _new!CppClassd();
    ICppd i = _new!ICppd();

    c.baseFunc();
    (reinterpret_cast!ICppd(c)).baseFunc();

    i.baseFunc();
    (dynamic_cast!CppClassd(i)).baseFunc();


    printf("Ending tests\n");
}

bool isAChild(T, U)() {
    return _typeid!U.isBaseOf!T;
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

