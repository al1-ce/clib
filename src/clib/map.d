// SPDX-FileCopyrightText: (C) 2023 Alisa Lain <al1-ce@null.net>
// SPDX-License-Identifier: GPL-3.0-or-later

/++
noGC compatible associative array.
+/
module clib.map;

// import core.stdc.stdlib: free, malloc, calloc, realloc;
import core.stdc.string: memcpy;

import clib.memory;

/++
noGC compatible dynamic size container

`map!(int, char)` is equivalent to `int[char]`
+/
struct map(K, V, A: IAllocator!V = allocator!V) {
    alias Node = TreeNode!(K, V);
    alias Pair = TreePair!(K, V);
    Node* root = null;
    A _allocator;

    void insert(K key, V value) @nogc nothrow {
        if (root is null) { root = allocNode(); }

        insertImpl(root, pair, null);
    }

    private Node* insertImpl(Node* root, Pair pair, Node* parent) {
        // Root is empty can safely insert
        if (root.filled == 0) {
            root.filled = 1;
            root.pairs[0] = pair;
            return root;
        }

        if (root.isLeaf) {
            // Root is leaf, have to explore in
            // Check if any pairs are already there
            for (size_t i = 0; i < root.filled; ++i) {
                if (root.pairs[i].key == pair.key) {
                    root.pairs[i].val = pair.val;
                    return root;
                }
            }
            // No pairs found
            size_t i;
            for (i = 0; i < root.filled; ++i) {
                if (root.pairs[i].key > pair.key) {
                    // found leaf
                    insertImpl(root.children[i], pair, root);
                    // TODO: what to do if fails
                }
            }
            // TODO: check if root is full
            // TODO: if not may insert
        } else {
            // Root is not leaf, can insert
            // Root not full
            if (root.filled < Node.N - 1) {
                size_t i;
                for (i = 0; i < root.filled; ++i) {
                    if (root.pairs[i].key == pair.key) {
                        root.pairs[i].val = pair.val;
                        return root;
                    }
                    if (root.pairs[i].key > pair.key) {
                        // Insert left
                        for (size_t j = root.filled; j > i; ++j) {
                            root.pairs[j + 1] = root.pairs[j];
                            // TODO: move leafs right
                        }
                        root.pairs[i] = pair;
                        root.filled += 1;
                        return root;
                    }
                }
                // Insert right
                root.pairs[i] = pair;
                root.filled += 1;
                return root;
            }

            // Root is full
            Node* left = allocNode();
            Node* right = allocNode();
            const size_t split = (Node.N - 1) / 2;
            // TODO: move leafs LR
            // 0 .. N-1 / 2 go left
            for (size_t i = 0; i < split; ++i) {
                left.pairs[i] = root[i];
                left.filled += 1;
            }

            // N-1 / 2 + 1 .. N-1 go right
            for (size_t i = split + 1; i < Node.N - 1; ++i) {
                right.pairs[i - split - 1] = root[i];
                right.filled += 1;
            }

            if (parent is null) {
                // split itself
                // N-1 / 2 is new leaf
                root.pairs[0] = root.pairs[split];
                root.children[0] = left;
                root.children[1] = right;
                root.filled = 1;
                root.isLeaf = true;
                // TODO: insert pair into either left or right
            } else {
                if (parent.filled == Node.N - 1) {
                    // parent full
                    root.pairs[0] = root.pairs[split];
                    root.children[0] = left;
                    root.children[1] = right;
                    root.filled = 1;
                    root.isLeaf = true;
                    // TODO: same
                } else {
                    Node* n = allocNode();
                    // TODO: insert into parent and rearrange leafs
                }
            }
        }


        return null;
    }

    void remove(K key) @nogc nothrow {
        // if (_tree.root is null) return;
    }

    V search(K key) @nogc nothrow {
        // if (_tree.root is null) return T.init;
    }

    private Node* allocNode() @nogc nothrow {
        if (_allocator is null) _allocator = _new!A();
        return cast(Node*) _allocator.allocate_vptr(Node.sizeof);
    }
}

private struct TreeNode(K, V) {
    static const size_t N = 6; // Keep it even

    TreePair!(K, V)[N - 1] pairs;

    TreeNode!(K, V)* parent = null;
    TreeNode!(K, V)*[N] children = null;

    bool isLeaf = false;
    size_t filled;

    void free(A: IAllocator!T, T)(A alloc) @nogc nothrow {
        for (size_t i = 0; i < N; ++i) {
            children[i].free(alloc);
            alloc.deallocate_vptr(cast(void*) children[i]);
        }
    }
}

private struct TreePair(K, V) {
    K key;
    V val;
}

