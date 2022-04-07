# Lazy Array Tools (Haxe)
Extension functions for `Array`s/`Iterable`s that are compile-time converted to a single, optimal for-loop.

```haxe
// Place at top of file or in import.hx
using LazyArrayTools;

// ---

var arr = [1, 2, 3, 4];

arr.filter((n) -> n % 2 == 0)
   .map((n) -> "This is even number: " + n)
   .forEach(trace);
//    |
//    |   at compile-time is
//    V   converted to:
for(it in arr) {
    if(it % 2 != 0) continue;
    final it2 = "This is even number: " + it;
    trace(it2);
}
```

---

# [Installation]
Install via haxelib.
```
haxelib install lazy-array-tools
```

Add this top of the file or `import.hx`.
```haxe
using LazyArrayTools;
```

---

# [Features]

### Even Lazier Mode

Feeling even lazier? Any function that takes a callback as an argument can accept an expression (`Expr`) that's just the callback body. Use a single underscore identifier (`_`) to represent the argument that would normally be passed to the callback (usually the processed array item).
```haxe
arr.filter(_ % 2 == 0)
   .map("This is even number: " + _);
```

&nbsp;

### `map` and `filter`

These functions work exactly like the `Array`'s `map` and `filter` functions.
```haxe
var arr = [1, 2, 3, 4, 5];

var len = arr.filter(_ < 2).length;
assert(len == 1);


var spaces = arr.map(StringTools.lpad("", " ", _));
assert(spaces[2] == "   ");
```

&nbsp;

### `forEach` and `forEachThen`

Calls the provided function/expression on each element in the `Array`/`Iterable`. `forEachThen` will return the array without modifying the elements. On the other hand, `forEach` returns `Void` and should be used in cases where the iterable object is not needed afterwards.
```haxe
// do something 10 times
0...10.forEach({
    test(_);
});

// add arbitrary behavior within for-loop
["i", "a", "bug", "hello"]
    .filter(_.length == 1)
    .forEachThen(trace("Letter is: " + _))
    .map(_.charCodeAt(0));
```

&nbsp;
