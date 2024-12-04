// SPDX-FileCopyrightText: (C) 2023 Alisa Lain <al1-ce@null.net>
// SPDX-License-Identifier: OSL-3.0

/++
noGC compatible associative array.
+/
module clib.map;

// import clib.stdlib: free, malloc, calloc, realloc;
import clib.string: memcpy;
import clib.memory;
import clib.iterator;

/++
noGC compatible dynamic size container

`map!(int, char)` is equivalent to `int[char]`
+/
struct map(K, V, A: IAllocator!V = allocator!V) {
    alias Node = TreeNode!(K, V);
    alias Pair = TreePair!(K, V);
    Node* root = null;
    A _allocator;
    size_t _size = 0;

    void insert(K key, V value) @nogc nothrow {
        if (root is null) {
            root = alloc_node();
            if (root is null) return;
            root.filled = 1;
            root.pairs[0] = Pair(key, value);
            _size++;
            return;
        }

        // Check if key exists before insertion
        bool keyExists = contains(key);

        Pair newPair = Pair(key, value);
        insert_impl(root, newPair, null);

        // Only increment size if this is a new key
        if (!keyExists) {
            _size++;
        }
    }

    private Node* insert_impl(Node* node, Pair pair, Node* parent) @nogc nothrow {
        if (node is null) return null;

        // Root is empty we can safely insert
        if (node.filled == 0) {
            node.filled = 1;
            node.pairs[0] = pair;
            return node;
        }

        // Check if key already exists
        for (size_t i = 0; i < node.filled; ++i) {
            if (node.pairs[i].key == pair.key) {
                node.pairs[i].val = pair.val;
                return node;
            }
        }

        if (node.is_leaf) {
            // Node is leaf and not full
            if (node.filled < Node.N - 1) {
                size_t pos = 0;
                // Find position to insert
                while (pos < node.filled && node.pairs[pos].key < pair.key) {
                    pos++;
                }
                // Shift elements right
                for (size_t i = node.filled; i > pos; --i) {
                    node.pairs[i] = node.pairs[i - 1];
                }
                node.pairs[pos] = pair;
                node.filled++;
                return node;
            }
            // Node is full, need to split
            return split_node(node, pair, parent);
        } else {
            // Find child to recurse into
            size_t pos = 0;
            while (pos < node.filled && node.pairs[pos].key < pair.key) {
                pos++;
            }
            // Safety check
            if (pos > node.N - 1) return null;

            Node* child = node.children[pos];
            if (child is null) {
                child = alloc_node();
                if (child is null) return null;
                node.children[pos] = child;
                child.parent = node;
            }
            return insert_impl(child, pair, node);
        }
    }

    private Node* split_node(Node* node, Pair pair, Node* parent) @nogc nothrow {
        Node* left = alloc_node();
        Node* right = alloc_node();
        if (left is null || right is null) return null;

        Pair[Node.N] temp;
        size_t pos = 0;
        size_t j = 0;

        // Insert new pair in sorted position
        while (j < node.filled && node.pairs[j].key < pair.key) {
            temp[pos++] = node.pairs[j++];
        }
        temp[pos++] = pair;
        while (j < node.filled) {
            temp[pos++] = node.pairs[j++];
        }

        // Split point
        size_t mid = (Node.N - 1) / 2;

        // Fill left node
        for (size_t i = 0; i < mid; ++i) {
            left.pairs[i] = temp[i];
            left.filled++;
        }

        // Fill right node
        for (size_t i = mid + 1; i < Node.N; ++i) {
            right.pairs[i - (mid + 1)] = temp[i];
            right.filled++;
        }

        // Handle parent
        if (parent is null) {
            // Root split
            node.pairs[0] = temp[mid];
            node.children[0] = left;
            node.children[1] = right;
            node.filled = 1;
            node.is_leaf = false;
            left.parent = node;
            right.parent = node;
            return node;
        } else {
            // Insert median into parent
            Pair median = temp[mid];
            if (parent.filled < Node.N - 1) {
                // Find position in parent
                pos = 0;
                while (pos < parent.filled && parent.pairs[pos].key < median.key) {
                    pos++;
                }
                // Shift parent elements and children
                for (size_t i = parent.filled; i > pos; --i) {
                    parent.pairs[i] = parent.pairs[i - 1];
                    parent.children[i + 1] = parent.children[i];
                }
                parent.pairs[pos] = median;
                parent.children[pos] = left;
                parent.children[pos + 1] = right;
                parent.filled++;
                left.parent = parent;
                right.parent = parent;
                return parent;
            } else {
                // Parent is full, need to split parent
                return split_node(parent, median, parent.parent);
            }
        }
    }

    void remove(K key) @nogc nothrow {
        if (root is null) return;

        // Find the node containing the key
        Node* node = root;
        while (node !is null) {
            size_t i;
            for (i = 0; i < node.filled; ++i) {
                if (node.pairs[i].key == key) {
                    // Found the key to remove
                    if (node.is_leaf) {
                        remove_from_leaf(node, i);
                    } else {
                        remove_from_internal(node, i);
                    }
                    _size--;
                    return;
                } else if (node.pairs[i].key > key) {
                    break;
                }
            }
            node = node.next_node(key);
        }
    }

    private void remove_from_leaf(Node* node, size_t idx) @nogc nothrow {
        // Shift remaining elements left
        for (size_t i = idx + 1; i < node.filled; ++i) {
            node.pairs[i - 1] = node.pairs[i];
        }
        node.filled--;

        if (node == root && node.filled == 0) {
            _allocator.deallocate_vptr(cast(void*)root);
            root = null;
            return;
        }

        // If node has too few elements, rebalance
        if (node != root && node.filled < (Node.N - 1) / 2) {
            rebalance_node(node);
        }
    }

    private void remove_from_internal(Node* node, size_t idx) @nogc nothrow {
        // Find predecessor (rightmost node in left subtree)
        Node* pred = node.children[idx];
        while (!pred.is_leaf) {
            pred = pred.children[pred.filled];
        }

        // Replace the removed key with predecessor
        node.pairs[idx] = pred.pairs[pred.filled - 1];

        remove_from_leaf(pred, pred.filled - 1);
    }

    private void rebalance_node(Node* node) @nogc nothrow {
        if (node is null || node.parent is null) return;

        Node* parent = node.parent;
        size_t node_idx = 0;

        // Find node's index in parent
        while (node_idx <= parent.filled &&
               parent.children[node_idx] != node) {
            node_idx++;
        }

        // Try to borrow from left sibling
        if (node_idx > 0) {
            Node* left = parent.children[node_idx - 1];
            if (left.filled > (Node.N - 1) / 2) {
                // Shift node's elements right
                for (size_t i = node.filled; i > 0; --i) {
                    node.pairs[i] = node.pairs[i - 1];
                }

                // Move parent's key down
                node.pairs[0] = parent.pairs[node_idx - 1];

                // Move rightmost key from left sibling up
                parent.pairs[node_idx - 1] = left.pairs[left.filled - 1];

                // Handle children if not a leaf
                if (!node.is_leaf) {
                    for (size_t i = node.filled + 1; i > 0; --i) {
                        node.children[i] = node.children[i - 1];
                    }
                    node.children[0] = left.children[left.filled];
                    if (node.children[0] !is null) {
                        node.children[0].parent = node;
                    }
                }

                node.filled++;
                left.filled--;
                return;
            }
        }

        // Try to borrow from right sibling
        if (node_idx < parent.filled) {
            Node* right = parent.children[node_idx + 1];
            if (right.filled > (Node.N - 1) / 2) {
                // Move parent's key down
                node.pairs[node.filled] = parent.pairs[node_idx];

                // Move leftmost key from right sibling up
                parent.pairs[node_idx] = right.pairs[0];

                // Shift right sibling's elements left
                for (size_t i = 0; i < right.filled - 1; ++i) {
                    right.pairs[i] = right.pairs[i + 1];
                }

                // Handle children if not aleaf
                if (!node.is_leaf) {
                    node.children[node.filled + 1] = right.children[0];
                    if (node.children[node.filled + 1] !is null) {
                        node.children[node.filled + 1].parent = node;
                    }
                    for (size_t i = 0; i < right.filled; ++i) {
                        right.children[i] = right.children[i + 1];
                    }
                }

                node.filled++;
                right.filled--;
                return;
            }
        }

        if (node_idx > 0) {
            // Merge with left sibling
            merge_nodes(parent.children[node_idx - 1], node, parent, node_idx - 1);
        } else {
            // Merge with right sibling
            merge_nodes(node, parent.children[node_idx + 1], parent, node_idx);
        }
    }

    private void merge_nodes(Node* left, Node* right, Node* parent, size_t parent_idx) @nogc nothrow {
        // Move parent's key down to left node
        left.pairs[left.filled] = parent.pairs[parent_idx];

        // Copy right node's elements to left node
        for (size_t i = 0; i < right.filled; ++i) {
            left.pairs[left.filled + 1 + i] = right.pairs[i];
        }

        // Handle children if not a leaf
        if (!left.is_leaf) {
            for (size_t i = 0; i <= right.filled; ++i) {
                left.children[left.filled + 1 + i] = right.children[i];
                if (left.children[left.filled + 1 + i] !is null) {
                    left.children[left.filled + 1 + i].parent = left;
                }
            }
        }

        // Update filled count
        left.filled = left.filled + 1 + right.filled;

        // Remove parent key and adjust parent's children
        for (size_t i = parent_idx + 1; i < parent.filled; ++i) {
            parent.pairs[i - 1] = parent.pairs[i];
            parent.children[i] = parent.children[i + 1];
        }
        parent.filled--;

        _allocator.deallocate_vptr(cast(void*)right);

        // If parent is root and empty, make left the new root
        if (parent == root && parent.filled == 0) {
            _allocator.deallocate_vptr(cast(void*)parent);
            root = left;
            left.parent = null;
        } else if (parent != root && parent.filled < (Node.N - 1) / 2) {
            rebalance_node(parent);
        }
    }

    V search(K key) @nogc nothrow {
        Node* node = root;
        while (node !is null) {
            foreach (i; 0..node.filled) {
                if (node.pairs[i].key == key) {
                    return node.pairs[i].val;
                }
            }
            node = node.next_node(key);
        }
        return V.init;
    }

    @property bool empty() const @nogc nothrow {
        return root is null || root.filled == 0;
    }

    @property size_t size() const @nogc nothrow {
        return _size;
    }

    bool contains(K key) const @nogc nothrow {
        if (empty) return false;
        return find_node(root, key) !is null;
    }

    private const(Node)* find_node(const Node* node, K key) const @nogc nothrow {
        if (node is null) return null;
        foreach (i; 0..node.filled) {
            if (node.pairs[i].key == key) {
                return node;
            } else if (node.pairs[i].key > key) {
                return find_node(node.children[i], key);
            }
        }
        return find_node(node.children[node.filled], key);
    }

    const(V) opIndex(K key) const @nogc nothrow {
        const(Node)* node = root;
        while (node !is null) {
            foreach (i; 0..node.filled) {
                if (node.pairs[i].key == key) {
                    return node.pairs[i].val;
                }
            }
            node = node.next_node(key);
        }
        return V.init;
    }

    ref V opIndex(K key) @nogc nothrow {
        Node* node = root;
        while (node !is null) {
            foreach (i; 0..node.filled) {
                if (node.pairs[i].key == key) {
                    return node.pairs[i].val;
                }
            }
            node = node.next_node(key);
        }

        // Create new entry if not found
        insert(key, V.init);

        // Find the newly inserted value and return a reference to it
        node = root;
        while (node !is null) {
            foreach (i; 0..node.filled) {
                if (node.pairs[i].key == key) {
                    return node.pairs[i].val;
                }
            }
            node = node.next_node(key);
        }
        assert(0, "Internal error: newly inserted key not found");
    }

    void opIndexAssign(V value, K key) @nogc nothrow {
        insert(key, value);
    }

    /// Returns the first element in the map
    @property TreePair!(K, V) front() @nogc nothrow {
        if (empty) return TreePair!(K, V).init;
        auto it = begin();
        return it.front;
    }

    @property const(TreePair!(K, V)) front() const @nogc nothrow {
        if (empty) return TreePair!(K, V).init;
        auto it = begin();
        return it.front;
    }

    /// Returns the last element in the map
    @property TreePair!(K, V) back() @nogc nothrow {
        if (empty) return TreePair!(K, V).init;
        auto it = rbegin();
        return it.front;
    }

    @property const(TreePair!(K, V)) back() const @nogc nothrow {
        if (empty) return TreePair!(K, V).init;
        auto it = rbegin();
        return it.front;
    }

    private Node* leftmost_node(Node* node) @nogc nothrow {
        if (node is null) return null;
        Node* current = node;
        while (current.children[0] !is null) {
            current = current.children[0];
        }
        return current;
    }

    private const(Node)* leftmost_node(const Node* node) const @nogc nothrow {
        if (node is null) return null;
        const(Node)* current = node;
        while (current.children[0] !is null) {
            current = current.children[0];
        }
        return current;
    }

    private Node* rightmost_node(Node* node) @nogc nothrow {
        if (node is null) return null;
        Node* current = node;
        while (current.children[current.filled] !is null) {
            current = current.children[current.filled];
        }
        return current;
    }

    private const(Node)* rightmost_node(const Node* node) const @nogc nothrow {
        if (node is null) return null;
        const(Node)* current = node;
        while (current.children[current.filled] !is null) {
            current = current.children[current.filled];
        }
        return current;
    }

    private const(Node)* next_inorder_node(const Node* node) const @nogc nothrow {
        if (node is null) return null;

        // If has right child, go to leftmost node of right subtree
        if (node.children[node.filled] !is null) {
            return leftmost_node(node.children[node.filled]);
        }

        // Otherwise, go up until we find a parent where we came from a left child
        const(Node)* parent = node.parent;
        const(Node)* current = node;
        while (parent !is null) {
            foreach (i; 0..parent.filled + 1) {
                if (parent.children[i] == current && i < parent.filled) {
                    return parent;
                }
            }
            current = parent;
            parent = parent.parent;
        }
        return null;
    }

    private Node* next_inorder_node(Node* node) @nogc nothrow {
        if (node is null) return null;

        // If has right child, go to leftmost node of right subtree
        if (node.children[node.filled] !is null) {
            return leftmost_node(node.children[node.filled]);
        }

        // Otherwise, go up until we find a parent where we came from a left child
        Node* parent = node.parent;
        Node* current = node;
        while (parent !is null) {
            foreach (i; 0..parent.filled + 1) {
                if (parent.children[i] == current && i < parent.filled) {
                    return parent;
                }
            }
            current = parent;
            parent = parent.parent;
        }
        return null;
    }

    ref const(TreePair!(K, V)) opIndex(size_t idx) const @nogc nothrow {
        if (empty || idx >= _size) {
            static const TreePair!(K, V) dummy;
            return dummy;
        }

        size_t current = 0;
        const(Node)* node = leftmost_node(root);
        while (node !is null) {
            foreach (i; 0..node.filled) {
                if (current == idx) {
                    return node.pairs[i];
                }
                current++;
            }
            node = next_inorder_node(node);
        }
        static const TreePair!(K, V) dummy;
        return dummy;
    }

    ref TreePair!(K, V) opIndex(size_t idx) @nogc nothrow {
        if (empty || idx >= _size) {
            static TreePair!(K, V) dummy;
            return dummy;
        }

        size_t current = 0;
        Node* node = leftmost_node(root);
        while (node !is null) {
            foreach (i; 0..node.filled) {
                if (current == idx) {
                    return node.pairs[i];
                }
                current++;
            }
            node = next_inorder_node(node);
        }
        static TreePair!(K, V) dummy;
        return dummy;
    }

    MapIterator!(K, V) begin() @nogc nothrow {
        return MapIterator!(K, V)(&this, false);
    }

    ConstMapIterator!(K, V) begin() const @nogc nothrow {
        return ConstMapIterator!(K, V)(&this, false);
    }

    MapIterator!(K, V) end() @nogc nothrow {
        return MapIterator!(K, V)(&this, true);
    }

    ConstMapIterator!(K, V) end() const @nogc nothrow {
        return ConstMapIterator!(K, V)(&this, true);
    }

    /// Returns backward iterator to beginning (for reverse iteration)
    ReverseMapIterator!(K, V) rbegin() @nogc nothrow {
        return ReverseMapIterator!(K, V)(&this, false);
    }

    ConstReverseMapIterator!(K, V) rbegin() const @nogc nothrow {
        return ConstReverseMapIterator!(K, V)(&this, false);
    }

    /// Returns backward iterator to end (for reverse iteration)
    ReverseMapIterator!(K, V) rend() @nogc nothrow {
        return ReverseMapIterator!(K, V)(&this, true);
    }

    ConstReverseMapIterator!(K, V) rend() const @nogc nothrow {
        return ConstReverseMapIterator!(K, V)(&this, true);
    }

    int opApply(scope int delegate(ref TreePair!(K, V)) @nogc nothrow dg) @nogc nothrow {
        if (empty) return 0;

        auto it = begin();
        while (!it.empty) {
            if (int result = dg(it.front)) {
                return result;
            }
            it.popFront();
        }
        return 0;
    }

    int opApply(scope int delegate(ref const TreePair!(K, V)) @nogc nothrow dg) const @nogc nothrow {
        if (empty) return 0;

        auto it = begin();
        while (!it.empty) {
            if (int result = dg(it.front)) {
                return result;
            }
            it.popFront();
        }
        return 0;
    }

    int opApply(scope int delegate(ref K key, ref V value) @nogc nothrow dg) @nogc nothrow {
        return opApply((ref TreePair!(K, V) pair) {
            return dg(pair.key, pair.val);
        });
    }

    int opApply(scope int delegate(ref const K key, ref const V value) @nogc nothrow dg) const @nogc nothrow {
        return opApply((ref const TreePair!(K, V) pair) {
            return dg(pair.key, pair.val);
        });
    }

    int opApplyReverse(scope int delegate(ref TreePair!(K, V)) @nogc nothrow dg) @nogc nothrow {
        if (empty) return 0;

        auto it = rbegin();
        while (!it.empty) {
            if (int result = dg(it.front)) {
                return result;
            }
            it.popFront();
        }
        return 0;
    }

    int opApplyReverse(scope int delegate(ref const TreePair!(K, V)) @nogc nothrow dg) const @nogc nothrow {
        if (empty) return 0;

        auto it = rbegin();
        while (!it.empty) {
            if (int result = dg(it.front)) {
                return result;
            }
            it.popFront();
        }
        return 0;
    }

    int opApplyReverse(scope int delegate(ref K key, ref V value) @nogc nothrow dg) @nogc nothrow {
        return opApplyReverse((ref TreePair!(K, V) pair) {
            return dg(pair.key, pair.val);
        });
    }

    int opApplyReverse(scope int delegate(ref const K key, ref const V value) @nogc nothrow dg) const @nogc nothrow {
        return opApplyReverse((ref const TreePair!(K, V) pair) {
            return dg(pair.key, pair.val);
        });
    }

    private size_t count_nodes(Node* node) @nogc nothrow {
        if (node is null) return 0;
        size_t count = node.filled;
        foreach (i; 0..node.N) {
            if (node.children[i] !is null) {
                count += count_nodes(node.children[i]);
            }
        }
        return count;
    }

    private Node* alloc_node() @nogc nothrow {
        if (_allocator is null) _allocator = _new!A();
        Node* node = cast(Node*) _allocator.allocate_vptr(Node.sizeof);
        if (node !is null) {
            node.filled = 0;
            node.is_leaf = true;
            node.parent = null;
            foreach(i; 0..Node.N) {
                node.children[i] = null;
            }
        }
        return node;
    }

    // Iterator structs
    private struct MapIterator(K, V) {
        map!(K, V)* container;
        Node* current;
        size_t index;
        bool isEnd;

        this(map!(K, V)* c, bool end) @nogc nothrow {
            container = c;
            isEnd = end;
            if (!end && container.root !is null) {
                current = container.root;
                while (current.children[0] !is null) {
                    current = current.children[0];
                }
                index = 0;
            } else {
                current = null;
                index = 0;
            }
        }

        ref TreePair!(K, V) front() @nogc nothrow {
            assert(!empty, "Attempting to fetch the front of an empty range");
            return current.pairs[index];
        }

        ref MapIterator popFront() @nogc nothrow {
            assert(!empty, "Attempting to popFront an empty range");
            if (index + 1 < current.filled) {
                index++;
            } else {
                const(Node)* next = container.next_inorder_node(current);
                if (next is null) {
                    isEnd = true;
                    current = null;
                } else {
                    current = cast(Node*)next;
                    index = 0;
                }
            }
            return this;
        }

        bool empty() const @nogc nothrow {
            return isEnd || current is null || container.root is null;
        }

        @property MapIterator save() @nogc nothrow {
            return this;
        }
    }

    private struct ConstMapIterator(K, V) {
        const map!(K, V)* container;
        const(Node)* current;
        size_t index;
        bool isEnd;

        this(const map!(K, V)* c, bool end) @nogc nothrow {
            container = c;
            isEnd = end;
            if (!end && container.root !is null) {
                current = container.root;
                while (current.children[0] !is null) {
                    current = current.children[0];
                }
                index = 0;
            } else {
                current = null;
                index = 0;
            }
        }

        ref const(TreePair!(K, V)) front() const @nogc nothrow {
            assert(!empty, "Attempting to fetch the front of an empty range");
            return current.pairs[index];
        }

        ref ConstMapIterator popFront() @nogc nothrow {
            assert(!empty, "Attempting to popFront an empty range");
            if (index + 1 < current.filled) {
                index++;
            } else {
                auto next = container.next_inorder_node(current);
                if (next is null) {
                    isEnd = true;
                    current = null;
                } else {
                    current = next;
                    index = 0;
                }
            }
            return this;
        }

        bool empty() const @nogc nothrow {
            return isEnd || current is null || container.root is null;
        }

        @property ConstMapIterator save() @nogc nothrow {
            return this;
        }
    }

    private struct ReverseMapIterator(K, V) {
        map!(K, V)* container;
        Node* current;
        size_t index;
        bool isEnd;

        this(map!(K, V)* c, bool end) @nogc nothrow {
            container = c;
            isEnd = end;
            if (!end && container.root !is null) {
                current = container.root;
                while (current.children[current.filled] !is null) {
                    current = current.children[current.filled];
                }
                index = current.filled - 1;
            } else {
                current = null;
                index = 0;
            }
        }

        ref TreePair!(K, V) front() @nogc nothrow {
            assert(!empty, "Attempting to fetch the front of an empty range");
            return current.pairs[index];
        }

        ref ReverseMapIterator popFront() @nogc nothrow {
            assert(!empty, "Attempting to popFront an empty range");
            if (index > 0) {
                index--;
            } else {
                const(Node)* prev = container.prev_inorder_node(current);
                if (prev is null) {
                    isEnd = true;
                    current = null;
                } else {
                    current = cast(Node*)prev;
                    index = current.filled - 1;
                }
            }
            return this;
        }

        bool empty() const @nogc nothrow {
            return isEnd || current is null || container.root is null;
        }

        @property ReverseMapIterator save() @nogc nothrow {
            return this;
        }
    }

    private struct ConstReverseMapIterator(K, V) {
        const map!(K, V)* container;
        const(Node)* current;
        size_t index;
        bool isEnd;

        this(const map!(K, V)* c, bool end) @nogc nothrow {
            container = c;
            isEnd = end;
            if (!end && container.root !is null) {
                current = container.rightmost_node(container.root);
                index = current.filled - 1;
            } else {
                current = null;
                index = 0;
            }
        }

        @property bool empty() const @nogc nothrow {
            return isEnd || current is null;
        }

        ref const(TreePair!(K, V)) front() const @nogc nothrow {
            assert(!empty, "Attempting to fetch the front of an empty range");
            return current.pairs[index];
        }

        ref ConstReverseMapIterator popFront() @nogc nothrow {
            assert(!empty, "Attempting to popFront an empty range");
            if (index > 0) {
                index--;
            } else {
                current = container.prev_inorder_node(current);
                if (current !is null) {
                    index = current.filled - 1;
                } else {
                    isEnd = true;
                }
            }
            return this;
        }
    }

    private const(Node)* prev_inorder_node(const Node* node) const @nogc nothrow {
        if (node is null) return null;

        // If has left child, go to rightmost node of left subtree
        if (node.children[0] !is null) {
            return rightmost_node(node.children[0]);
        }

        // Otherwise, go up until we find a parent where we came from a right child
        const(Node)* current = node;
        const(Node)* parent = node.parent;
        while (parent !is null) {
            foreach_reverse (i; 0..parent.filled + 1) {
                if (parent.children[i] == current) {
                    if (i > 0) return parent;
                    break;
                }
            }
            current = parent;
            parent = parent.parent;
        }
        return parent;
    }
}

private struct TreePair(K, V) {
    K key;
    V val;

    this(K k, V v) @nogc nothrow {
        key = k;
        val = v;
    }
}

private struct TreeNode(K, V) {
    static const size_t N = 6; // Keep it even

    TreePair!(K, V)[N - 1] pairs;
    TreeNode!(K, V)* parent = null;
    TreeNode!(K, V)*[N] children = null;
    bool is_leaf = false;
    size_t filled;

    ref TreePair!(K, V) opIndex(size_t i) @nogc nothrow {
        return pairs[i];
    }

    ref const(TreePair!(K, V)) opIndex(size_t i) const @nogc nothrow {
        return pairs[i];
    }

    const(TreeNode!(K, V))* next_node(K key) const @nogc nothrow {
        if (filled == 0) return null;

        foreach (i; 0..filled) {
            if (key < pairs[i].key) return children[i];
            if (key == pairs[i].key) return children[i + 1];
        }
        return children[filled];
    }

    TreeNode!(K, V)* next_node(K key) @nogc nothrow {
        if (filled == 0) return null;

        foreach (i; 0..filled) {
            if (key < pairs[i].key) return children[i];
            if (key == pairs[i].key) return children[i + 1];
        }
        return children[filled];
    }

    void free(A: IAllocator!T, T)(A alloc) @nogc nothrow {
        for (size_t i = 0; i < N; ++i) {
            if (children[i] !is null) {
                children[i].free(alloc);
                alloc.deallocate_vptr(cast(void*) children[i]);
            }
        }
    }
}

// Unittests
@nogc nothrow {
    unittest {
        // Basic insertion and lookup
        map!(int, string) m;
        m[1] = "one";
        m[2] = "two";
        assert(!m.empty);
        assert(m.size == 2);
        assert(m[1] == "one");
        assert(m[2] == "two");
        assert(m.contains(1));
        assert(!m.contains(3));
    }

    unittest {
        // Test node splitting
        map!(int, int) m;
        // Fill a node to force splitting
        foreach(i; 0..5) {
            m[i] = i * 10;
        }
        // Verify all values are still accessible
        foreach(i; 0..5) {
            assert(m[i] == i * 10);
        }
        assert(m.size == 5);
    }

    unittest {
        // Test more complex tree structure
        map!(int, string) m;

        // Insert enough elements to force multiple splits
        m[5] = "five";
        m[3] = "three";
        m[7] = "seven";
        m[1] = "one";
        m[2] = "two";
        m[4] = "four";
        m[6] = "six";
        m[8] = "eight";
        m[9] = "nine";
        m[10] = "ten";

        // Verify size
        assert(m.size == 10);

        // Verify all elements are accessible
        assert(m[1] == "one");
        assert(m[2] == "two");
        assert(m[3] == "three");
        assert(m[4] == "four");
        assert(m[5] == "five");
        assert(m[6] == "six");
        assert(m[7] == "seven");
        assert(m[8] == "eight");
        assert(m[9] == "nine");
        assert(m[10] == "ten");

        assert(m.contains(5));
        assert(!m.contains(11));

        // Test overwriting existing values
        m[5] = "FIVE";
        assert(m[5] == "FIVE");
        assert(m.size == 10);
    }

    unittest {
        // Test memory management
        map!(int, int) m;

        // Insert and verify
        foreach(i; 0..20) {
            m[i] = i;
        }

        foreach(i; 0..20) {
            assert(m[i] == i);
        }

        assert(m.size == 20);
    }

    unittest {
        // Test array-like access
        map!(int, string) m;
        m[1] = "one";
        m[2] = "two";
        m[3] = "three";

        // Test iterator traversal
        auto it = m.begin();
        assert(!it.empty);
        assert(it.front.val == "one");

        it.popFront();
        assert(!it.empty);
        assert(it.front.val == "two");

        it.popFront();
        assert(!it.empty);
        assert(it.front.val == "three");

        it.popFront();
        assert(it.empty);

        // Test iteration
        size_t idx = 0;
        foreach(ref pair; m) {
            idx++;
        }
        assert(idx == 3);
    }

    unittest {
        // Test range functionality
        map!(int, string) m;
        m[1] = "one";
        m[2] = "two";
        m[3] = "three";

        assert(m.front.key == 1);
        assert(m.front.val == "one");
        assert(m.back.key == 3);
        assert(m.back.val == "three");

        int sum = 0;
        foreach (ref pair; m) {
            sum += pair.key;
        }
        assert(sum == 6);

        foreach (ref k, ref v; m) {
            if (k == 2) v = "TWO";
        }
        assert(m[2] == "TWO");
    }

    unittest {
        // Test empty range behavior
        map!(int, string) m;
        assert(m.front == TreePair!(int, string).init);
        assert(m.back == TreePair!(int, string).init);

        int count = 0;
        foreach (pair; m) {
            count++;
        }
        assert(count == 0);
    }

    unittest {
        // Test iterator edge cases
        map!(int, int) m;

        // Empty map iteration
        auto it = m.begin();
        assert(it.empty);

        // Single element iteration
        m[1] = 1;
        it = m.begin();
        assert(!it.empty);
        assert(it.front.key == 1);
        it.popFront();
        assert(it.empty);

        // Test iterator stability during modifications
        m[2] = 2;
        m[3] = 3;
        it = m.begin();
        m.remove(2);

        // Iterator should still be valid for remaining elements
        int count = 0;
        foreach (pair; m) {
            count++;
            assert(pair.key != 2);
        }
        assert(count == 2);
    }

    unittest {
        // Test memory management edge cases
        map!(int, int) m;

        // Rapid insert/remove cycles
        foreach(cycle; 0..5) {
            foreach(i; 0..20) {
                m[i] = i;
            }
            foreach_reverse(i; 0..20) {
                m.remove(i);
            }
            assert(m.empty);
        }

        // Alternating insert/remove
        foreach(i; 0..20) {
            m[i] = i;
            if (i > 0) m.remove(i-1);
        }
        assert(m.size == 1);
        assert(m.contains(19));
    }

    unittest {
        // Test const iteration
        map!(int, string) m;
        m[1] = "one";
        m[2] = "two";
        m[3] = "three";
        m[4] = "four";
        m[5] = "five";

        const(map!(int, string)) cm = m;

        // Test forward iteration
        int count = 0;
        int prev_key = 0;
        auto it = m.begin();
        while (!it.empty) {
            assert(it.front.key > prev_key, "Keys should be in ascending order");
            prev_key = it.front.key;
            count++;
            it.popFront();
        }
        assert(count == 5, "Should iterate over all elements");

        // Test reverse iteration
        count = 0;
        prev_key = 6;
        auto rit = m.rbegin();
        while (!rit.empty) {
            assert(rit.front.key < prev_key, "Keys should be in descending order");
            prev_key = rit.front.key;
            count++;
            rit.popFront();
        }
        assert(count == 5, "Should iterate over all elements in reverse");

        // Test const forward iteration
        count = 0;
        prev_key = 0;
        auto cit = cm.begin();
        while (!cit.empty) {
            assert(cit.front.key > prev_key, "Keys should be in ascending order");
            prev_key = cit.front.key;
            count++;
            cit.popFront();
        }
        assert(count == 5, "Should iterate over all elements");

        // Test const reverse iteration
        count = 0;
        prev_key = 6;
        auto crit = cm.rbegin();
        while (!crit.empty) {
            assert(crit.front.key < prev_key, "Keys should be in descending order");
            prev_key = crit.front.key;
            count++;
            crit.popFront();
        }
        assert(count == 5, "Should iterate over all elements in reverse");

        // Test foreach iteration
        count = 0;
        prev_key = 0;
        foreach (ref pair; m) {
            assert(pair.key > prev_key, "Keys should be in ascending order");
            prev_key = pair.key;
            count++;
        }
        assert(count == 5, "Should iterate over all elements");

        // Test foreach_reverse iteration
        count = 0;
        prev_key = 6;
        foreach_reverse (ref pair; m) {
            assert(pair.key < prev_key, "Keys should be in descending order");
            prev_key = pair.key;
            count++;
        }
        assert(count == 5, "Should iterate over all elements in reverse");
    }

    unittest {
        // Test iteration
        map!(int, string) m;
        m[1] = "one";
        m[2] = "two";
        m[3] = "three";

        // Test begin/end iteration
        auto it = m.begin();
        assert(!it.empty);
        assert(it.front.key == 1);
        assert(it.front.val == "one");
        it.popFront();
        assert(!it.empty);
        assert(it.front.key == 2);
        assert(it.front.val == "two");
        it.popFront();
        assert(!it.empty);
        assert(it.front.key == 3);
        assert(it.front.val == "three");
        it.popFront();
        assert(it.empty);

        // Test rbegin/rend iteration
        auto rit = m.rbegin();
        assert(!rit.empty);
        assert(rit.front.key == 3);
        assert(rit.front.val == "three");
        rit.popFront();
        assert(rit.front.key == 2);
        assert(rit.front.val == "two");
        rit.popFront();
        assert(rit.front.key == 1);
        assert(rit.front.val == "one");
        rit.popFront();
        assert(rit.empty);

        // Test foreach
        int[3] expected_keys = [1, 2, 3];
        string[3] expected_vals = ["one", "two", "three"];
        size_t idx = 0;
        foreach (ref pair; m) {
            assert(pair.key == expected_keys[idx]);
            assert(pair.val == expected_vals[idx]);
            idx++;
        }
        assert(idx == 3);

        // Test foreach_reverse
        idx = 0;
        int[3] expected_rev_keys = [3, 2, 1];
        string[3] expected_rev_vals = ["three", "two", "one"];
        foreach_reverse (ref pair; m) {
            assert(pair.key == expected_rev_keys[idx]);
            assert(pair.val == expected_rev_vals[idx]);
            idx++;
        }
        assert(idx == 3);
    }

    unittest {
        // Test const iteration
        map!(int, string) m;
        m[1] = "one";
        m[2] = "two";
        m[3] = "three";

        const(map!(int, string)) cm = m;

        // Test const begin/end iteration
        auto it = cm.begin();
        assert(!it.empty);
        assert(it.front.key == 1);
        assert(it.front.val == "one");
        it.popFront();
        assert(!it.empty);
        assert(it.front.key == 2);
        assert(it.front.val == "two");
        it.popFront();
        assert(!it.empty);
        assert(it.front.key == 3);
        assert(it.front.val == "three");
        it.popFront();
        assert(it.empty);

        // Test const rbegin/rend iteration
        auto rit = cm.rbegin();
        assert(!rit.empty);
        assert(rit.front.key == 3);
        assert(rit.front.val == "three");
        rit.popFront();
        assert(rit.front.key == 2);
        assert(rit.front.val == "two");
        rit.popFront();
        assert(rit.front.key == 1);
        assert(rit.front.val == "one");
        rit.popFront();
        assert(rit.empty);

        // Test const foreach
        int[3] expected_keys = [1, 2, 3];
        string[3] expected_vals = ["one", "two", "three"];
        size_t idx = 0;
        foreach (const ref pair; cm) {
            assert(pair.key == expected_keys[idx]);
            assert(pair.val == expected_vals[idx]);
            idx++;
        }
        assert(idx == 3);

        // Test const foreach_reverse
        idx = 0;
        int[3] expected_rev_keys = [3, 2, 1];
        string[3] expected_rev_vals = ["three", "two", "one"];
        foreach_reverse (const ref pair; cm) {
            assert(pair.key == expected_rev_keys[idx]);
            assert(pair.val == expected_rev_vals[idx]);
            idx++;
        }
        assert(idx == 3);
    }
}
