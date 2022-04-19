# Magic Array Tools (Haxe)
Extension functions for `Array`s/`Iterable`s that are compile-time converted to a single, optimal for-loop. Never again be concerned about performance when you need to throw on a couple `map`s and `filter`s. Any number of array modifications is guarenteed to run through just one loop at runtime!

```haxe
// Place at top of file or in import.hx
using MagicArrayTools;

// ---

var arr = ["a", "i", "the", "and"];

// At compile-time this code is
// converted into a single for-loop.
arr.filter(s -> s.length == 1)
   .map(s -> s.charCodeAt(0))
   .filter(s -> s != null)
   .count(s -> s == 105);

//    |
//    V

// This is what is generated and replaces 
// the expression at compile-time.
{
    var result = 0;
    for(it in arr) {
        if(it.length != 1) continue;
        final it2 = it.charCodeAt(0);
        if(it2 == null) continue;
        if(it2 == 105) {
            result++;
        }
    }
    result;
}
```

---

# [Installation]
| # | What to do | What to write |
| - | ------ | ------ |
| 1 | Install via haxelib. | <pre>haxelib install magic-array-tools</pre> |
| 2 | Add the lib to your `.hxml` file or compile command. | <pre lang="hxml">-lib magic-array-tools</pre> |
| 3 | Add this top of your source file or `import.hx`. | <pre lang="haxe">using MagicArrayTools;</pre> |

Now use this library's functions on an `Array`, `Iterable`, or `Iterator` and let the magic happen!

---

# [Feature Index]

| Feature | Description |
| --- | --- |
| [Inline Mode](https://github.com/RobertBorghese/Haxe-MagicArrayTools#inline-mode) | A shorter, faster syntax for callbacks |
| [Disable Auto For-Loop](https://github.com/RobertBorghese/Haxe-MagicArrayTools#disable-auto-for-loop) | Temporarily or permanently disable the automatic for-loop creation |
| [Display For-Loop](https://github.com/RobertBorghese/Haxe-MagicArrayTools#display-for-loop) | Stringifies and traces the for-loop code that will be generated for debugging purposes |
| [`map` and `filter`](https://github.com/RobertBorghese/Haxe-MagicArrayTools#map-and-filter) | Remapping and filtering functions |
| [`forEach` and `forEachThen`](https://github.com/RobertBorghese/Haxe-MagicArrayTools#foreach-and-foreachthen) | Iterate and run an expression or callback |
| [`size` and `isEmpty`](https://github.com/RobertBorghese/Haxe-MagicArrayTools#size-and-isempty) | Finds the number of elements |
| [`count`](https://github.com/RobertBorghese/Haxe-MagicArrayTools#count) | Counts the number of elements that match the condition |
| [`find`](https://github.com/RobertBorghese/Haxe-MagicArrayTools#find) | Finds the first element that matches the condition |
| [`indexOf`](https://github.com/RobertBorghese/Haxe-MagicArrayTools#indexOf) | Returns the index of the provided element |
| [`asList` and `asVector`](https://github.com/RobertBorghese/Haxe-MagicArrayTools#aslist-and-asvector) | Provides the result as a `haxe.ds.List` or `haxe.ds.Vector` |
| [`concat`](https://github.com/RobertBorghese/Haxe-MagicArrayTools#concat) | Appends another `Array`, `Iterable`, or even separate for-loop |
---

# [Features]

### Inline Mode

While local functions can be passed as an argument, for short/one-line operations it is recommended "inline mode" is used. This resolves any issues that comes from Haxe type inferences, and it helps apply the exact expression where desired.

Any function that takes a callback as an argument can accept an expression (`Expr`) that's just the callback body. Use a single underscore identifier (`_`) to represent the argument that would normally be passed to the callback (usually the processed array item). This expression will be placed and typed directly in the resuling for-loop.
```haxe
[1, 2, 3].map(i -> "" + i); // Error:
                            // Int should be String
                            // ... For function argument 'i'

[1, 2, 3].map("" + _);            // Fix using inline mode!
[1, 2, 3].map((i:Int) -> "" + i); // (Explicit-typing also works)
```

&nbsp;

### Disable Auto For-Loop

In certain circumstances, one may want to disable the automatic for-loop building. Using the `@disableAutoForLoop` metadata will disable this for all subexpressions. However, for-loops can still be manually constructed by appending `.buildForLoop()`.

If manually building for-loops using `buildForLoop()` is preferred, defining the compilation flag (`-D disableAutoForLoop`) will disable the automatic building for the entire project.
```haxe
class ConflictTester {
    public function new() {}
    public function map(c: (Int) -> Int) return 1234;
    public function iterator(): Iterator<Int> { return 0...5; }
}

// ---

final obj = new ConflictTester();

// This generates a for-loop.
obj.map(i -> i);

// Unable to call "map" function on this
// Iterable unless auto for-loops are disabled.
@disableAutoForLoop {
    obj.map(i -> i);                // 1234
    obj.map(i -> i).buildForLoop(); // [0, 1, 2, 3, 4]
}
```

&nbsp;

### Display For-Loop

Curious about the code that will be generated? Simply append `.displayForLoop()` to the method chain, and the generated for-loop expression will be traced/printed to the console.
```haxe
["a", "b", "c"]
    .map(_.indexOf("b"))
    .filter(_ >= 0)
    .asList()
    .displayForLoop();

// -- OUTPUT --
//
// Main.hx:1: {
//     final result = new haxe.ds.List();
//     for(it in ["a", "b", "c"]) {
//         final it2 = it.indexOf("b");
//         if(!(it2 >= 0)) continue;
//         result.add(it2);
//     }
//     result;
// }
// 
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
(0...10).forEach(test);

//    |
//    V

for(it in 0...10) {
    test(it);
}
```

```haxe
// add arbitrary behavior within for-loop
["i", "a", "bug", "hello"]
    .filter(_.length == 1)
    .forEachThen(trace("Letter is: " + _))
    .map(_.charCodeAt(0));

//    |
//    V

{
    final result = [];
    for(it in ["i", "a", "bug", "hello"]) {
        if(it.length != 1) continue;
        trace("Letter is: " + it);
        final it2 = it.charCodeAt(0);
                                                                    
        result.push(it2);
    }
    result;
}
```

&nbsp;

### `size` and `isEmpty`

`size` counts the number of elements after the other modifiers are applied. `isEmpty` is an optimized version that immediately returns `false` upon the first element found and returns `true` otherwise.
```haxe
(0...5).filter(_ % 2 == 0).size();

//    |
//    V

{
    var result = 0;
    for(it in 0...5) {
        if(it % 2 != 0) continue;
        result++;
    }
    result;
}
```

```haxe
(10...20).filter(_ == 0).isEmpty();

//    |
//    V

{
    var result = true;
    for(it in 10...20) {
        if(it != 0) continue;
        result = false;
        break;
    }
    result;
}
```

&nbsp;

### `count`

`count` counts the number of elements that match the condition.
```haxe
(0...20).count(_ > 10);

//    |
//    V

{
    var result = 0;
    for(it in 0...20) {
        if(it > 10) {
            result++;
        }
    }
    result;
}
```

&nbsp;

### `find`

`find` returns the first element that matches the condition.
```haxe
["ab", "a", "b", "cd"].find(_.length <= 1);

//    |
//    V

{
    var result = null;
    for(it in ["ab", "a", "b", "cd"]) {
        if(it.length <= 1) {
            result = it;
            break;
        }
    }
    result;
}
```

&nbsp;

### `indexOf`

`indexOf` returns the index of the first element that equals the provided argument.
```haxe
[22, 33, 44].indexOf(33);

//    |
//    V

{
    var result = -1;
    var i = 0;
    for(it in [22, 33, 44]) {
        if(it == 33) {
            result = i;
            break;
        }
        i++;
    }
    result;
}
```

&nbsp;

### `asList` and `asVector`

These functions change the resulting data-structure to either be a `haxe.ds.List` or `haxe.ds.Vector`.
```haxe
(0...10).filter(_ % 3 != 0).asList();

//    |
//    V

{
    var result = new haxe.ds.List();
    for(it in 0...10) {
        if(it % 3 == 0) continue;
        result.add(it);
    }
    result;
}
```

```haxe
(0...10).filter(_ % 3 != 0).asVector();

//    |
//    V

{
    var result = [];
    for(it in 0...10) {
        if(it % 3 == 0) continue;
        result.push(it);
    }
    haxe.ds.Vector.fromArrayCopy(result);
}
```

&nbsp;

### `concat`

Appends the provided array/elements to the current array. The output generates an additional for-loop to iterate over the new elements. This library's functions can be called on the first argument to this function, and the modifiers will be recursively flattened and applied exclusively to the new loop.
```haxe
(0...10).concat([100, 1000, 9999]);

//    |
//    V

{
    var result = [];
    for(it in 0...10) {
        result.push(it);
    }
    for(it in [100, 1000, 9999]) {
        result.push(it);
    }
    result;
}
```

```haxe
// Pass a "for-loop" as an argument and it will be merged.
(0...10).filter(_ % 2 == 0).concat( (0...10).filter(_ % 3 == 0) );

//    |
//    V

{
    var result = [];
    for(it in 0...10) {
        if(it % 2 != 0) continue;
        result.push(it);
    }
    for(it in 0...10) {
        if(it % 3 != 0) continue;
        result.push(it);
    }
    result;
}
```

&nbsp;
