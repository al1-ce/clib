import cpp;

import core.stdc.stdio;

extern(C++) {

    class CppClass {
        this(int p_a, char* p_b) {
            a = p_a;
            b = p_b;
        }

        int a;
        char* b;
        bool c = true;

        int get() { return a; }
    }

    class CppClassSecond: CppClass {
        this() { super(2, cast(char*) "a".ptr); }
        bool e = true;
    }

    interface L {
        void testLFunc();
    }

    class Base: L {
        this() {
            puts("base construct");
        }

        override void testLFunc() {
            puts("call override function");
        }

        void testBaseFunc() {
            puts("call Base function");
        }

        ~this() {
            puts("base close");
        }
    }

    class Test: Base {
        int i;
        int y;

        this(int i, int y) {
            this.i= i;
            this.y = y;
        }

        ~this() {
            puts("hello world");
        }
    }

}

void testLFunc(L base) {
    base.testLFunc();
}

/// Does not work
void testLCase(L base) {
    reinterpretCast!L(base).testLFunc();
}

extern(C) void main(int argc, char** argv) {
    printf("Starting tests\n\n");

    printf("Testing extern(C++) class\n");
    CppClass cppClass = _new!CppClass(2, cast(char*) "Hello world".ptr);
    CppClassSecond cppClassSecond = _new!CppClassSecond();

    printf("%s, %i, %i, %i\n", cppClass.b, cppClass.a, cppClass.c, cppClassSecond.get());

    _free(cppClass);
    _free(cppClassSecond);
    printf("\n");

    Test t = _new!Test(20, 40);
    printf("t.i is => %d\n", t.i);
    t.testLFunc();
    (cast(L) cast(void*) t).testLFunc();
    reinterpretCast!L(t).testLFunc();
    testLFunc(t.reinterpretCast!L);
    t.reinterpretCast!L().testLCase();
    // testLCase(t);
    _free(t);
    printf("\n");

    printf("Initializing vector!int\n");
    vector!int v =  vector!int(1, 2, 3, 4, 5, 6);

    vectorInfo(&v);
    printf("\n");

    size_t v_newsize = v.capacity + 2;
    printf("v.reserve(%llu)\n", v_newsize);
    v.reserve(v_newsize);
    vectorInfo(&v);
    printf("\n");

    v_newsize = v.capacity - 2;
    printf("v.resize(%llu)\n", v_newsize);
    v.resize(v_newsize);
    vectorInfo(&v);
    printf("\n");

    v_newsize = v.capacity + 4;
    printf("v.resize(%llu)\n", v_newsize);
    v.resize(v_newsize);
    vectorInfo(&v);
    printf("\n");

    printf("v.clear()\n");
    v.clear();
    vectorInfo(&v);
    printf("\n");

    v_newsize = v.capacity + 2;
    printf("v.resize(%llu, 12)\n", v_newsize);
    v.resize(v_newsize, 12);
    vectorInfo(&v);
    printf("\n");

    import core.stdc.stdlib: malloc;
    int[6] arr = [6, 5, 4, 3, 2, 1];
    // arr.reserve(20);
    // arr.resize(2);
    vector!int c = arr;
    printf("vector from array\n");
    vectorInfo(&c);
    printf("\n");

    v = arr;
    printf("v = arr\n");
    vectorInfo(&v);
    printf("\n");

    v.assign(&arr[2], 3);
    printf("v.assign()\n");
    vectorInfo(&v);
    printf("\n");

    v.push(20);
    v.pushFront(arr);
    v.erase(2);
    printf("v.push(20)\n");
    printf("v.pushFront(arr)\n");
    printf("v.erase(2)\n");
    vectorInfo(&v);
    printf("\n");

    v.shrink();
    printf("v.shrink()\n");
    vectorInfo(&v);
    printf("\n");

    v = arr;
    v.erase(1, 2);
    v.insert(2, 42);
    printf("v = [6, 5, 4, 3, 2, 1]\n");
    printf("v.erase(1, 2)\n");
    printf("v.insert(2, 42)\n");
    vectorInfo(&v);
    printf("\n");

    v = vector!int(22, 15, 0, 4);
    v.reserve(20);
    v.swap(&c);
    printf("v = [22, 15, 0, 4]\n");
    printf("v.reserve(20)\n");
    printf("v.swap(c)\n");
    printf("v info:\n");
    vectorInfo(&v);
    printf("c info:\n");
    vectorInfo(&c);
    printf("\n");

    printf("v info:\n");
    vectorInfo(&v);
    v.erase(1);
    printf("v.erase(1)\n");
    printf("v.pop() - %i\n", v.pop());
    printf("v.popFront() - %i\n", v.popFront());
    vectorInfo(&v);
    printf("\n");

    optional!int opt;
    printf("optional() - %s %i\n", opt.hasValue.asString.ptr, opt.value);
    opt = optional!int(null);
    printf("optional(null) - %s %i\n", opt.hasValue.asString.ptr, opt.value);
    opt = optional!int(20);
    printf("optional(int) - %s %i\n", opt.hasValue.asString.ptr, opt.value);

    bool revFunc(int a, int b) {return a < b;}
    printf("\n");
    set!(int, revFunc) s;
    setInfo(s.data, s.size);
    printf("Assigning set [6, 5, 4, 3, 2, 1]\n");
    s ~= arr;
    setInfo(s.data, s.size);
    printf("Adding [1, 12, 4, 5, 61, 2]\n");
    s.insert(1, 12, 4, 5, 61, 2);
    setInfo(s.data, s.size);

    import core.stdc.string: strcmp;

    set!(char*) s2;
    printf("Assigning set [abcd, cbda, dcba, add, remove]\n");
    s2.insert(cast(char*)"abcd".ptr,
              cast(char*)"cbda".ptr,
              cast(char*)"dcba".ptr,
              cast(char*)"add".ptr,
              cast(char*)"remove".ptr);
    setstrInfo(s2.data, s2.size);

    printf("\n");
    printf("v[1..$] = 3 2\n");
    vector!int vz = v[1..$];
    vectorInfo(&vz);
    printf("slice len - %llu\n", v[1..$].length);
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
