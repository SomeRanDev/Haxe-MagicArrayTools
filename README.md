<img src="img/Logo.png" /> 

Extension functions for `Array`s/`Iterable`s that are compile-time converted to a single, optimal for-loop. Never again be concerned about performance when you need to throw on a couple `map`s and `filter`s. Any number of array modifications is guarenteed to run through just one loop at runtime!

```haxe
// Place at top of file or in import.hx
using MagicArrayTools;

// ---

var arr = ["a", "i", "the", "and"];

// At compile-time this code is
// converted into a single for-loop.
arr.magiter()
   .filter(s -> s.length == 1)
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
| [Inline Mode](https://github.com/SomeRanDev/Haxe-MagicArrayTools#inline-mode) | A shorter, faster syntax for callbacks |
| [Display Generated Loop](https://github.com/SomeRanDev/Haxe-MagicArrayTools#display-generated-result) | Stringifies and traces the code that will be generated for debugging purposes |
| [`map` and `filter`](https://github.com/SomeRanDev/Haxe-MagicArrayTools#map-and-filter) | Remapping and filtering functions |
| [`forEach` and `forEachThen`](https://github.com/SomeRanDev/Haxe-MagicArrayTools#foreach-and-foreachthen) | Iterate and run an expression or callback |
| [`size` and `isEmpty`](https://github.com/SomeRanDev/Haxe-MagicArrayTools#size-and-isempty) | Finds the number of elements |
| [`count`](https://github.com/SomeRanDev/Haxe-MagicArrayTools#count) | Counts the number of elements that match the condition |
| [`find` and `findIndex`](https://github.com/SomeRanDev/Haxe-MagicArrayTools#find-and-findindex) | Finds the first element that matches the condition |
| [`indexOf`](https://github.com/SomeRanDev/Haxe-MagicArrayTools#indexOf) | Returns the index of the provided element |
| [`every` and `some`](https://github.com/SomeRanDev/Haxe-MagicArrayTools#every-and-some) | Check if some or all elements match the condition |
| [`reduce`](https://github.com/SomeRanDev/Haxe-MagicArrayTools#reduce) | Reduce to single value summed together using function |
| [`asList` and `asVector`](https://github.com/SomeRanDev/Haxe-MagicArrayTools#aslist-and-asvector) | Provides the result as a `haxe.ds.List` or `haxe.ds.Vector` |
| [`concat`](https://github.com/SomeRanDev/Haxe-MagicArrayTools#concat) | Appends another `Array`, `Iterable`, or even separate for-loop |
| [`fill`](https://github.com/SomeRanDev/Haxe-MagicArrayTools#fill) | Fill a subsection or the entire `Array` with a value |
---

# [Features]

### Inline Mode

While local functions can be passed as an argument, for short/one-line operations it is recommended "inline mode" is used. This resolves any issues that comes from Haxe type inferences, and it helps apply the exact expression where desired.

Any function that takes a callback as an argument can accept an expression (`Expr`) that's just the callback body. Use a single underscore identifier (`_`) to represent the argument that would normally be passed to the callback (usually the processed array item). This expression will be placed and typed directly in the resuling for-loop.
```haxe
[1, 2, 3].magiter().map(i -> "" + i); // Error:
                                      // Int should be String
                                      // ... For function argument 'i'

[1, 2, 3].magiter().map("" + _);            // Fix using inline mode!
[1, 2, 3].magiter().map((i:Int) -> "" + i); // (Explicit-typing also works)
```

&nbsp;

### Display Generated Loop

Curious about the code that will be generated? Simply append `.displayResult()` to the method chain, and the generated for-loop expression will be traced/printed to the console at compile-time! You can even place it between calls to debug up to a certain point in the chain.
```haxe
["a", "b", "c"]
    .magiter()
    .map(_.indexOf("b"))
    .filter(_ >= 0)
    .asList()
    .displayResult();

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
function map(callback: (T) -> U): Array<U>;
function filter(callback: (T) -> Bool): Array<T>;
```
```haxe
var arr = [1, 2, 3, 4, 5];

var len = arr.magiter().filter(_ < 2).length;
assert(len == 1);


var spaces = arr.magiter().map(StringTools.lpad("", " ", _));
assert(spaces[2] == "   ");
```

&nbsp;

### `forEach` and `forEachThen`

Calls the provided function/expression on each element in the `Array`/`Iterable`. `forEachThen` will return the array without modifying the elements. On the other hand, `forEach` returns `Void` and should be used in cases where the iterable object is not needed afterwards.
```haxe
function forEach(callback: (T) -> Void): Void;
function forEachThen(callback: (T) -> Void): Array<T>;
```
```haxe
// do something 10 times
(0...10).magiter().forEach(test);

//    |
//    V

for(it in 0...10) {
    test(it);
}
```

```haxe
// add arbitrary behavior within for-loop
["i", "a", "bug", "hello"]
    .magiter()
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
function size(): Int;
function isEmpty(): Bool;
```
```haxe
(0...5).magiter().filter(_ % 2 == 0).size();

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
(10...20).magiter().filter(_ == 0).isEmpty();

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
function count(callback: (T) -> Bool): Int;
```
```haxe
(0...20).magiter().count(_ > 10);

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

### `find` and `findIndex`

`find` returns the first element that matches the condition. `findIndex` does the same thing, but it returns the index of the element instead.
```haxe
function find(callback: (T) -> Bool): Null<T>;
function findIndex(callback: (T) -> Bool): Int;
```
```haxe
["ab", "a", "b", "cd"].magiter().find(_.length <= 1);

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
```haxe
vectorIterator.magiter().findIndex(_.magnitude > 3);

//    |
//    V

{
    var result = -1;
    var i = 0;
    for(it in vectorIterator) {
        if(it.magnitude > 3) {
            result = i;
            break;
        }
        i++;
    }
    result;
}
```

&nbsp;

### `indexOf`

`indexOf` returns the index of the first element that equals the provided argument. This function has three arguments, but only the first one is required.
```haxe
function indexOf(item: T, startIndex: Int = 0, inlineItemExpr: Bool = false): Int;
```

`startIndex` dictates the number of elements that must be processed before initiating the search. This functionality will not be generated at all as long as the argument is not provided or the argument is assigned a `0` literal.

`inlineItemExpr` is a compile-time argument that must either a `true` or `false` literal. It defines how the `item` expression will be used in the generated for-loop. If `true`, the expression will be inserted into the for-loop exactly as passed. If not provided or `false`, the expression will be assigned to a variable, and this variable will be used within the for-loop. Single identifiers and numbers will be automatically inlined since there is no additional runtime cost.
```haxe
[22, 33, 44].magiter().indexOf(33);

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

```haxe
// If the third argument was "true", the "_value" variable would not be generated.
// Instead, the comparison would be: if(it == World.FindPlayer())
// FindPlayer might be an expensive operation, so this is not the default behavior.
entitiesIterator.magiter().indexOf(World.FindPlayer(), 1, false);

//    |
//    V

{
    var result = -1;
    var i = 0;
    final _value = World.FindPlayer();
    var _indexOfCount: Int = 1;
    for(it in entitiesIterator) {
        if(_indexOfCount > 0) {
            _indexOfCount--;
        } else if(it == _value) {
            result = i;
            break;
        }
        i++;
    }
    result;
}
```

&nbsp;

### `every` and `some`

`every` returns `true` if every element returns `true` when passed to the provided callback. On the other hand, `some` returns `true` as long as at least one element passes.
```haxe
function every(callback: (T) -> Bool): Bool;
function some(callback: (T) -> Bool): Bool;
```
```haxe
[75, 7, 12, 93].magiter().every(_ > 0);

//    |
//    V

{
    var result = true;
    for(it in [75, 7, 12, 93]) {
        if(it <= 0) {
            result = false;
            break;
        }
    }
    result;
}
```

```haxe
(1...10).magiter().some(_ == 4);

//    |
//    V

{
    var result = false;
    for(it in 1...10) {
        if(it == 4) {
            result = true;
            break;
        }
    }
    result;
}
```

&nbsp;

### `reduce`

`reduce` calls a function on every element to accumulate all the values. The returned value of the previous call is passed as the first argument; the second argument is the element being iterated on. The returned value of the final call is what `reduce` returns.
```haxe
function reduce(callback: (T, T) -> T): T;
```
```haxe
["a", "b", "c", "d"].magiter().reduce(_1 + _2);

//    |
//    V

{
    var result = null;
    var _hasFoundValue = false;
    for(it in ["a", "b", "c", "d"]) {
        if(!_hasFoundValue) {
            _hasFoundValue = true;
            result = it;
        } else {
            result = result + it;
        };
    };
    result;
}
```

&nbsp;

### `asList` and `asVector`

These functions change the resulting data-structure to either be a `haxe.ds.List` or `haxe.ds.Vector`.
```haxe
function asList(): haxe.ds.List<T>;
function asVector(): haxe.ds.Vector<T>;
```
```haxe
(0...10).magiter().filter(_ % 3 != 0).asList();

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
(0...10).magiter().filter(_ % 3 != 0).asVector();

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
function concat(other: Array<T> | Iterable<T> | Iterator<T>): Array<T>;
```
```haxe
(0...10).magiter().concat([100, 1000, 9999]);

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
(0...10).magiter().filter(_ % 2 == 0).concat( (0...10).filter(_ % 3 == 0) );

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

### `fill`

`fill` fills the resulting `Array` with the provided value. A subsection can be filled using the second and third arguments.
```haxe
function fill(value: T, startIndex: Int = 0, endIndex: Int = this.length): Array<T>;
```
```haxe
[1, 2, 3].magiter().fill(10);

//    |
//    V

{
    var result = [];
    for(it in [1, 2, 3]) {
        var it2 = 10;
        result.push(it2);
    };
    result;
}
```
```haxe
(0...10).magiter().fill(999, 2, 8);

//    |
//    V

{
    var result = [];
    var i = 0;
    for(it in (0 ... 10)) {
        var it2 = if((i >= 2) && (i < 8)) {
            999;
        } else {
            it;
        };
        result.push(it2);
        i++;
    };
    result;
}
```

&nbsp;
