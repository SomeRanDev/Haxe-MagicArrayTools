package;

import mat.generation.LoopBuilder;
import mat.generation.StoredExprData;
import mat.generation.MagicIterable;

import mat.utils.Context;
import haxe.macro.Expr.Expr;
import haxe.macro.Expr.ExprOf;

using haxe.macro.ExprTools;
using haxe.macro.TypeTools;
using mat.extension_functions.ExprEx;
using mat.utils.Error;

/**
	A wrapper type used to represent something that was generated from `magiter`.

	This ensures Magic Array Tools' static extension functions don't interfere with other functions
	that use the same names.
**/
typedef MagicIterableExprOf<T> = ExprOf<MagicIterable<T>>;

/**
	A wrapped of `haxe.macro.Expr` used to represent expressions compatible with the "magic
	callback" system.

	This expression must either be a traditional function object:
		- `function` expression
		- Arrow function expression
		- Function identifier or dot-path.

	OR a direct expression that uses `_` to represent the function argument:
	```haxe
	[1, 2, 3].magiter().map(i -> i + 100);

	// Equivalent of the above:
	[1, 2, 3].magiter().map(_ + 100);
	```
**/
typedef MagicCallbackExprOf<T: haxe.Constraints.Function> = haxe.macro.Expr;

/**
	This function must be called on a `Iterator`, `Iterable`, or other compatible expression before
	calling any of Magic Array Tools' other functions.
**/
macro function magiter<T>(ethis: ExprOf<T>): MagicIterableExprOf<T> {
	final storedExprData = StoredExprDataUtils.fromExpr(ethis) ?? {
		Error.StoredExprCouldNotBeObtained.at(ethis.pos);
		return null;
	};

	// Create new `LoopBuilder` that iterates over `ethis`.
	final loopBuilder = new LoopBuilder();
	loopBuilder.pushNewLoopWithType(storedExprData.placeholder, storedExprData.typedExpr.t);

	// Generate an expression that notifies the user the `magiter` call went unused.
	// If it IS used, this expression will be replaced due to the usage.
	final ethisWithWarningMessage = macro {
		@:pos(ethis.pos) trace("Unused `MagicArrayTools.magiter` call.");
		$ethis;
	};

	// If `type` is `null`, that means it is not inferrable at this point (i.e. `[]`).
	//
	// TODO:
	// Do I force users to explitily type expressions, or do I replace all `TMono`s with `Dynamic`?
	final type = storedExprData.typedExpr.t.toComplexType();
	if(type == null) {
		Error.MagiterRequiresKnownType.at(ethis.pos);
		return null;
	}

	// Wrap the expression with the `loopBuilder.getId()` stored as data so we can find
	// and continue using the builder in subsequent function calls.
	return MagicIterableUtils.wrapExprWithData(
		ethisWithWarningMessage,
		type ?? macro : Any,
		loopBuilder.getId()
	);
}

/**
	This generates a compiler print of Magic Array Tools code that will be generated on a chain of
	functions.
	
	It can be used multiple times within the same chain! It will show the code generation up until
	that point. Use at the very end of the chain to see the full code generation.

	This does not affect the generated for-loop.
**/
macro function displayResult<T>(ethis: MagicIterableExprOf<T>): MagicIterableExprOf<T> {
	final loopBuilder = LoopBuilder.findLoopBuilderFromPreviousExpr(ethis);
	if(loopBuilder != null) {
		loopBuilder.displayResult();
	}
	return ethis;
}

/**
	Works exactly like `Array.map`.
**/
macro function map<T, U>(
	ethis: MagicIterableExprOf<T>,
	callbackArgument: MagicCallbackExprOf<(T) -> U>
): MagicIterableExprOf<U> {
	final loopBuilder = LoopBuilder.findLoopBuilderFromPreviousExpr(ethis) ?? return ethis;

	final callback = loopBuilder.makeMagicCallback(callbackArgument, "map");
	final pre = macro @:pos(callbackArgument.pos) final __ = ${callback.expr};
	loopBuilder.addPreAction(pre, true);

	return loopBuilder.build();
}

/**
	Works exactly like `Array.filter`.
**/
macro function filter<T>(
	ethis: MagicIterableExprOf<T>,
	callbackArgument: MagicCallbackExprOf<(T) -> Bool>
): MagicIterableExprOf<T> {
	final loopBuilder = LoopBuilder.findLoopBuilderFromPreviousExpr(ethis) ?? return ethis;

	final callback = loopBuilder.makeMagicCallback(callbackArgument, "filter");
	final pre = macro @:pos(callbackArgument.pos) if(!(${callback.expr})) continue;
	loopBuilder.addPreAction(pre);

	return loopBuilder.build();
}

/**
	Works exactly like `Array.forEach`.

	Since it returns `Void`, other functions cannot be used after this one, but in return it does
	not allocate any resulting data.

	Use `MagicArrayTools.forEachThen` if you'd like to continue chaining afterwards.
**/
macro function forEach<T>(
	ethis: MagicIterableExprOf<T>,
	callbackArgument: MagicCallbackExprOf<(T) -> Void>
): MagicIterableExprOf<Void> {
	final loopBuilder = LoopBuilder.findLoopBuilderFromPreviousExpr(ethis) ?? return ethis;

	final callback = loopBuilder.makeMagicCallback(callbackArgument, "forEach");
	final pre = macro @:pos(callbackArgument.pos) ${callback.expr};
	loopBuilder.addPreAction(pre);
	loopBuilder.clearResult();

	return loopBuilder.build();
}

/**
	Works exactly like `Array.forEach`, but allows for functions to be chained aftwards.
**/
macro function forEachThen<T>(
	ethis: MagicIterableExprOf<T>,
	callbackArgument: MagicCallbackExprOf<(T) -> Void>
): MagicIterableExprOf<T> {
	final loopBuilder = LoopBuilder.findLoopBuilderFromPreviousExpr(ethis) ?? return ethis;

	final callback = loopBuilder.makeMagicCallback(callbackArgument, "forEachThen");
	final pre = macro @:pos(callbackArgument.pos) ${callback.expr};
	loopBuilder.addPreAction(pre);

	return loopBuilder.build();
}

/**
	Returns the number of elements in the iterator.
**/
macro function size<T>(ethis: MagicIterableExprOf<T>): MagicIterableExprOf<Int> {
	final loopBuilder = LoopBuilder.findLoopBuilderFromPreviousExpr(ethis) ?? return ethis;

	loopBuilder.setInit(macro var result = 0);
	loopBuilder.setAction(macro result++, true);

	return loopBuilder.build();
}

/**
	Returns the number of elements in the iterator that return `true` from `callbackArgument`.
**/
macro function count<T>(
	ethis: MagicIterableExprOf<T>,
	callbackArgument: MagicCallbackExprOf<(T) -> Bool>
): MagicIterableExprOf<Int> {
	final loopBuilder = LoopBuilder.findLoopBuilderFromPreviousExpr(ethis) ?? return ethis;

	final callbackData = loopBuilder.makeMagicCallback(callbackArgument, "count");
	loopBuilder.setInit(macro var result = 0);
	loopBuilder.setAction(macro @:mergeBlock {
		if(${callbackData.expr}) {
			result++;
		}
	}, true);

	return loopBuilder.build();
}

/**
	Returns `false` if there is at least one element in the iterator.
**/
macro function isEmpty<T>(ethis: MagicIterableExprOf<T>): MagicIterableExprOf<Bool> {
	final loopBuilder = LoopBuilder.findLoopBuilderFromPreviousExpr(ethis) ?? return ethis;

	loopBuilder.setInit(macro var result = true);
	loopBuilder.setSubsequentLoopsCondition(macro result);
	loopBuilder.setAction(macro @:mergeBlock {
		result = false;
		break;
	}, true);

	return loopBuilder.build();
}

/**
	Returns the first element of type `T` that returns `true` from `callbackArgument`.
**/
macro function find<T>(
	ethis: MagicIterableExprOf<T>,
	callbackArgument: MagicCallbackExprOf<(T) -> Bool>
): MagicIterableExprOf<T> {
	final loopBuilder = LoopBuilder.findLoopBuilderFromPreviousExpr(ethis) ?? return ethis;

	final callbackData = loopBuilder.makeMagicCallback(callbackArgument, "find");
	loopBuilder.setInit(macro var result = null);
	loopBuilder.setSubsequentLoopsCondition(macro result == null);
	loopBuilder.setAction(macro @:mergeBlock {
		if(${callbackData.expr}) {
			result = _;
			break;
		}
	}, true);

	return loopBuilder.build();
}

/**
	Returns the index of first element that returns `true` from `callbackArgument`.
**/
macro function findIndex<T>(
	ethis: MagicIterableExprOf<T>,
	callbackArgument: MagicCallbackExprOf<(T) -> Bool>
): MagicIterableExprOf<Int> {
	final loopBuilder = LoopBuilder.findLoopBuilderFromPreviousExpr(ethis) ?? return ethis;

	final callbackData = loopBuilder.makeMagicCallback(callbackArgument, "findIndex");
	loopBuilder.enableIndexTracking();
	loopBuilder.setInit(macro var result = -1);
	loopBuilder.setSubsequentLoopsCondition(macro result == -1);
	loopBuilder.setAction(macro @:mergeBlock {
		if(${callbackData.expr}) {
			result = i;
			break;
		}
	}, true);

	return loopBuilder.build();
}

/**
	Returns the index of element provided.
	If the iterator does not contain the element, `-1` is returned.

	If `startingIndex` is provided, the search is started from that index instead of `0`. This
	functionality will not be generated at all as long as the argument is not provided or the
	argument is assigned a `0` literal.

	`forceInline` is a compile-time argument that must either a `true` or `false` literal.
	It defines how the `element` expression will be used in the generated for-loop. If `true`, the
	expression will be inserted into the for-loop exactly as passed. If not provided or `false`, the
	expression will be assigned to a variable, and this variable will be used within the for-loop.
	Single identifiers and numbers will be automatically inlined since there is no additional
	runtime cost.
**/
macro function indexOf<T>(
	ethis: MagicIterableExprOf<T>,
	element: ExprOf<T>,
	startingIndex: Null<ExprOf<Int>> = null,
	forceInline: Bool = false
): MagicIterableExprOf<Int> {
	final loopBuilder = LoopBuilder.findLoopBuilderFromPreviousExpr(ethis) ?? return ethis;

	loopBuilder.setInit(macro var result = -1);
	loopBuilder.setSubsequentLoopsCondition(macro result == -1);
	loopBuilder.enableIndexTracking();

	var hasStartIndex = if(!startingIndex?.isNullLiteral()) {
		if(startingIndex.isZero()) {
			false;
		} else {
			loopBuilder.pushInitVar(
				macro @:pos(startingIndex.pos) var _indexOf_indexOfCount: Int = $startingIndex
			);
			true;
		}
	} else {
		false;
	}

	final actionExpr = if(!forceInline && element.isCostly()) {
		loopBuilder.pushInitVar(macro final _value = $element);
		if(hasStartIndex) {
			macro @:mergeBlock {
				if(_indexOf_indexOfCount > 0) {
					_indexOf_indexOfCount--;
				} else if(_ == _value) {
					result = i;
					break;
				}
			}
		} else {
			macro @:mergeBlock {
				if(_ == _value) {
					result = i;
					break;
				}
			}
		}
	} else {
		if(hasStartIndex) {
			macro @:mergeBlock {
				if(_indexOf_indexOfCount > 0) {
					_indexOf_indexOfCount--;
				} else if(_ == $element) {
					result = i;
					break;
				}
			}
		} else {
			macro @:mergeBlock {
				if(_ == $element) {
					result = i;
					break;
				}
			}
		}
	}

	loopBuilder.setAction(actionExpr, true);

	return loopBuilder.build();
}

/**
	Returns `true` if every element of the iterator returns `true` for `callbackArgument`.
**/
macro function every<T>(
	ethis: MagicIterableExprOf<T>,
	callbackArgument: MagicCallbackExprOf<(T) -> Bool>
): ExprOf<Bool> {
	final loopBuilder = LoopBuilder.findLoopBuilderFromPreviousExpr(ethis) ?? return ethis;

	final callbackData = loopBuilder.makeMagicCallback(callbackArgument, "every");
	loopBuilder.setInit(macro var result = true);
	loopBuilder.setSubsequentLoopsCondition(macro result);
	loopBuilder.setAction(macro @:mergeBlock {
		if(!(${callbackData.expr})) {
			result = false;
			break;
		}
	}, true);

	return loopBuilder.build();
}

/**
	Returns `true` if at least one element of the iterator returns `true` for `callbackArgument`.
**/
macro function some<T>(
	ethis: MagicIterableExprOf<T>,
	callbackArgument: MagicCallbackExprOf<(T) -> Bool>
): ExprOf<Bool> {
	final loopBuilder = LoopBuilder.findLoopBuilderFromPreviousExpr(ethis) ?? return ethis;

	final callbackData = loopBuilder.makeMagicCallback(callbackArgument, "some");
	loopBuilder.setInit(macro var result = false);
	loopBuilder.setSubsequentLoopsCondition(macro !result);
	loopBuilder.setAction(macro @:mergeBlock {
		if(${callbackData.expr}) {
			result = true;
			break;
		}
	}, true);

	return loopBuilder.build();
}

/**
	Returns the first element of type `T` that returns `true` from `callbackArgument`.
**/
macro function reduce<T>(
	ethis: MagicIterableExprOf<T>,
	callbackArgument: MagicCallbackExprOf<(T, T) -> T>
): MagicIterableExprOf<T> {
	final loopBuilder = LoopBuilder.findLoopBuilderFromPreviousExpr(ethis) ?? return ethis;

	final callbackData = loopBuilder.makeMagicCallback(callbackArgument, "reduce", 2);
	loopBuilder.setInit(macro var result = null);
	loopBuilder.pushInitVar(macro var _reduce_hasFoundValue = false);
	loopBuilder.setAction(macro @:mergeBlock {
		if(!_reduce_hasFoundValue) {
			_reduce_hasFoundValue = true;
			result = _;
		} else {
			@:pos(callbackArgument.pos)
			result = @:mergeBlock { ${callbackData.expr.replaceNumberedUnderscores(["result", "_"])} }
		}
	}, true);

	return loopBuilder.build();
}

/**
	Returns the iterator as an array.
**/
macro function asArray<T>(ethis: MagicIterableExprOf<T>): ExprOf<Array<T>> {
	final loopBuilder = LoopBuilder.findLoopBuilderFromPreviousExpr(ethis) ?? return ethis;
	return loopBuilder.build(false);
}

/**
	Returns the iterator as a `haxe.ds.List`.

	This will generate code that accumulates values using `haxe.ds.List` from the start, so there is
	no penalty using this.
**/
macro function asList<T>(ethis: MagicIterableExprOf<T>): ExprOf<haxe.ds.List<T>> {
	final loopBuilder = LoopBuilder.findLoopBuilderFromPreviousExpr(ethis) ?? return ethis;

	loopBuilder.setInit(macro final result = new haxe.ds.List());
	loopBuilder.setAction(macro result.add(_), true);

	return loopBuilder.build(false);
}

/**
	Returns the iterator as a `haxe.ds.Vector`.

	Since there is no way to know the exact number of elements from the start, this DOES require
	allocating an array that is then copied into a `haxe.ds.Vector` at the very end. This function
	exists more for convenience than performance.
**/
macro function asVector<T>(ethis: MagicIterableExprOf<T>): ExprOf<haxe.ds.Vector<T>> {
	final loopBuilder = LoopBuilder.findLoopBuilderFromPreviousExpr(ethis) ?? return ethis;

	loopBuilder.setResult(macro haxe.ds.Vector.fromArrayCopy(result));

	return loopBuilder.build(false);
}

/**
	Appends an iterable to the end of this one. This is achieved by adding a second loop after the
	first one WITHOUT the operations that occured prior to this call. Functions called after
	`concat` are applied to both the original and the new loop, simulating the effects of `concat`
	without any additional reallocations.

	`other` can be either a `MagicIterable` OR a valid `magiter`-usable type WITHOUT the need to use
	`magiter` on it. For example:
	```haxe
	// VALID. This is equivalent to `[-2, -1, 0, 1, 2]`.
	[-2, -1].magiter().concat(3);

	// VALID. This also works if you want to be more explicit.
	[-2, -1].magiter().concat(3.magiter());
	```

	However, using a `MagicIterable` is preferred as it inlines the operations into the subsequent
	loop.
	```haxe
	// Don't do this...
	(10...20)
		.magiter()
		.concat(
			// `magiter` will be applied after the `Array.map`.
			myStringArray.map(s -> Std.parseInt(s))
		);

	// Do this.
	(10...20)
		.magiter()
		.concat(
			myStringArray.magiter().map(s -> Std.parseInt(s))
		);
	```
**/
macro function concat<T>(ethis: MagicIterableExprOf<T>, other: Expr): MagicIterableExprOf<T> {
	final loopBuilder = LoopBuilder.findLoopBuilderFromPreviousExpr(ethis) ?? return ethis;
	final maybeOtherLoopBuilder = LoopBuilder.findLoopBuilderFromPreviousExpr(other, false);
	if(maybeOtherLoopBuilder != null) {
		loopBuilder.mergeSubsequentLoopBuilder(maybeOtherLoopBuilder);
	} else {
		loopBuilder.pushNewLoop(other);
	}
	return loopBuilder.build();
}

/**
	Fills the iterator with `value`.
	
	A subsection can be filled using the second and third arguments. If `startingIndex` is defined,
	only elements after the index are replaced with `value`. If both `startingIndex` and
	`endingIndex` are defined, only elements with that range will be replaced with `value`.
**/
macro function fill<T>(
	ethis: MagicIterableExprOf<T>,
	value: ExprOf<T>,
	startingIndex: Null<ExprOf<Int>> = null,
	endingIndex: Null<ExprOf<Int>> = null
): MagicIterableExprOf<T> {
	final loopBuilder = LoopBuilder.findLoopBuilderFromPreviousExpr(ethis) ?? return ethis;

	//trace(value, startingIndex, endingIndex);

	final valuePos = value.pos;
	final _fill_fillValue = if(value.isCostly()) {
		loopBuilder.pushInitVar(macro @:pos(valuePos) var _fill_fillValue = $value);
		macro _fill_fillValue;
	} else {
		value;
	}

	if(startingIndex?.isNullLiteral() && endingIndex?.isNullLiteral()) {
		loopBuilder.addPreAction(macro @:pos(valuePos) final __ = $_fill_fillValue, true);
		return loopBuilder.build();
	}

	loopBuilder.enableIndexTracking();

	final startingIndexPos = startingIndex.pos;
	final _fill_fillIndex = if(startingIndex.isCostly()) {
		loopBuilder.pushInitVar(macro @:pos(startingIndexPos) var _fill_fillIndex = $startingIndex);
		macro _fill_fillIndex;
	} else {
		startingIndex;
	}

	final preAction = if(endingIndex?.isNullLiteral()) {
		macro @:mergeBlock {
			final __ = if(@:pos(startingIndexPos) (i >= $_fill_fillIndex)) {
				@:pos(valuePos) $_fill_fillValue;
			} else {
				_;
			}
		};
	} else {
		final _fill_fillIndexEnd = if(endingIndex.isCostly()) {
			loopBuilder.pushInitVar(macro @:pos(endingIndex.pos) var _fill_fillIndexEnd = $endingIndex);
			macro _fill_fillIndexEnd;
		} else {
			endingIndex;
		}

		macro @:mergeBlock {
			final __ = if(@:pos(startingIndexPos) (i >= $_fill_fillIndex) && @:pos(endingIndex.pos) (i < $_fill_fillIndexEnd)) {
				@:pos(valuePos) $_fill_fillValue;
			} else {
				_;
			}
		};
	}

	loopBuilder.addPreAction(preAction, true);

	return loopBuilder.build();
}
