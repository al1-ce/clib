import cppd;

import core.stdc.stdio;

extern(C++) class CppClass {
    this(int p_a, char* p_b) {
        a = p_a;
        b = p_b;
    }

    int a;
    char* b;
    bool c = true;

    void get() {}
}

extern(C++) class CppClassSecond: CppClass {
    this() { super(2, cast(char*) "a".ptr); }
    bool e = true;
}

void vectorInfo(T)(vector!T* vec) {
    printf("vector.capacity = %i\n", vec.capacity);
    printf("vector.size     = %i\n", vec.size);
    printf("vector.data     = ");
    for (int i = 0; i < vec.size; ++i) { printf("%i ", vec.data()[i]); }
    printf("\n");

}

extern(C) void main(int argc, char** argv) {
    printf("Starting tests\n\n");

    printf("Testing extern(C++) class\n");
    CppClass cppClass = _new!CppClass(2, cast(char*) "Hello world".ptr);
    scope(exit) _free(cppClass);

    printf("%s, %i, %i\n", cppClass.b, cppClass.a, cppClass.c);

    _free(cppClass);
    printf("\n");

    printf("Initializing vector!int\n");
    vector!int v =  vector!int(1, 2, 3, 4, 5, 6);

    vectorInfo(&v);
    printf("\n");

    size_t v_newsize = v.capacity + 2;
    printf("v.reserve(%i)\n", v_newsize);
    v.reserve(v_newsize);
    vectorInfo(&v);
    printf("\n");

    v_newsize = v.capacity - 2;
    printf("v.resize(%i)\n", v_newsize);
    v.resize(v_newsize);
    vectorInfo(&v);
    printf("\n");

    v_newsize = v.capacity + 4;
    printf("v.resize(%i)\n", v_newsize);
    v.resize(v_newsize);
    vectorInfo(&v);
    printf("\n");

    printf("v.clear()\n");
    v.clear();
    vectorInfo(&v);
    printf("\n");

    v_newsize = v.capacity + 2;
    printf("v.resize(%i, 12)\n", v_newsize);
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

    set!int s;

    printf("Ending tests\n");
}
