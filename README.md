# Magic Array Tools (Haxe)
Extension functions for `Array`s/`Iterable`s that are compile-time converted to a single, optimal for-loop.

```haxe
// Place at top of file or in import.hx
using MagicArrayTools;

// ---

var arr = [1, 2, 3, 4];

arr.filter(n -> n % 2 == 0)
   .map(n -> "This is even number: " + n)
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
| # | What to do | What to write |
| - | ------ | ------ |
| 1 | Install via haxelib. | <pre>haxelib install magic-array-tools</pre> |
| 2 | Add the lib to your `.hxml` file or compile command. | <pre lang="hxml">-lib magic-array-tools</pre> |
| 3 | Add this top of your source file or `import.hx`. | <pre lang="haxe">using MagicArrayTools;</pre> |

---

# [Core Quirks/Features]

### Inline Mode

While local functions can be passed as an argument, for short/one-line operations it is recommended "inline mode" is used. This resolves any issues that comes from Haxe type inferences, and it helps apply the exact expression where desired.

Any function that takes a callback as an argument can accept an expression (`Expr`) that's just the callback body. Use a single underscore identifier (`_`) to represent the argument that would normally be passed to the callback (usually the processed array item). This expression will be placed and typed directly in the resuling for-loop.
```haxe
[1, 2, 3].map(i -> "" + i); // Error:
                            // Int should be String
                            // ... For function argument 'i'

[1, 2, 3].map("" + _);      // Works!
[1, 2, 3].map((i:Int) -> "" + i); // (This would also work)
```

&nbsp;

---

# [Array/Iterable Functions]

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
