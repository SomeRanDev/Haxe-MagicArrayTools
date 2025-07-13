package mat.generation;

#if (macro || mat_runtime)

import MagicArrayTools.MagicIterableExprOf;
import mat.generation.MagicIterable;
import mat.utils.Error;

import mat.utils.Context;
import haxe.macro.Expr.ComplexType;
import haxe.macro.Expr.Expr;
import haxe.macro.Type;

using mat.extension_functions.ExprEx;
using mat.extension_functions.TypeEx;
using haxe.macro.ExprTools;
using haxe.macro.TypeTools;
using haxe.macro.ComplexTypeTools;

/**
	Once an iteration has been "completed", subsequent iterations build off of the resulting value.
	This enum keeps track of the state of the next iteration.
**/
enum LoopBuilderNextState {
	Single;
	QueueNext;
	HasNext(nextLoopBuilder: LoopBuilder);
}

/**
	This class is used to construct the iteration expressions.

	The structure of a buildable-loop is as follows:

	```haxe
	// (1...10).magiter().filter(_ % 2 == 0).count(_ < 3)
	{
		// INIT
		var result = 0;

		// LOOPS
		for (it in @:storedTypedExpr 178) {
			// PRE-ACTIONS
			if(!(it % 2 == 0)) continue;

			// ACTION
			if (it < 3) {
				result++;
			};
		};

		// RESULT
		result;
	}
	```

	1) INIT
		This is a single expression that initializes the `result` variable. This can be modified
		using `setInit`. By default this is `final result = [];`

	2) INIT_VARS
		This is a list of additional expressions typically used to add additional variables to the
		generated expression. Expressions can be added here using `pushInitVar`.

	3) INDEX_TRACKING_INIT
		If "index trackoing" is enabled, this is where the index variable will be initialized.
		"Index tracking" can be enabled by calling `enableIndexTracking`.

	4) LOOPS
		This is where all the loops go. Within a loop, you have:

		1) PRE-ACTIONS
			These are expressions that are executed before "ACTION". These are used to modify the
			variable provided to ACTION or prevent ACTION from happening (by using `continue`).

			`addPreAction` can be used to add a pre-action. Use `__` in the expression to represent
			the "current" variable, and pass `true` to generate a new variable for usage.

		2) ACTION
			This is a single expression that runs at the end of the loop. By default this is 
			`result.push(__)`. This should be modified for things that don't return an array.

			For example, `isEmpty` will simply do: `{ result = false; break; }`, since if ACTION
			is executed, that means at least one element made it through all the potential filters
			placed in PRE-ACTIONS.

		3) INDEX_TRACKING_INCREMENT
			If "index trackoing" is enabled, this is where the index variable is incremented.

	5) RESULT
	This will always just be `result;` in order to return the value from the block-expression. The
	only exception is if `clearResult` is called, and the chain should have a "void return".
**/
class LoopBuilder {
	static var builders: Array<LoopBuilder> = [];

	public static function findLoopBuilderFromPreviousExpr<T>(previous: MagicIterableExprOf<T>, generateErrorOnFail: Bool = true): Null<LoopBuilder> {
		final index = MagicIterableUtils.extractDataFromWrapped(previous);
		if(index >= 0 && index < builders.length) {
			return builders[index];
		}
		if(generateErrorOnFail) {
			Error.InvalidIterateSubject.currentPos();
		}
		return null;
	}

	// ---

	var id: Int;

	var init: Expr = macro final result = [];
	var initVars: Array<Expr> = [];
	var loops: Array<Loop> = [];
	var result: Expr = macro result;
	var hasResult: Bool = true;
	var subsequentLoopsCondition: Null<Expr> = null;

	var nextState: LoopBuilderNextState = Single;

	var initVarNames: Map<String,Int> = [];

	var complete: Bool = false;
	var indexTracking: Bool = false;

	// ---

	public function new() {
		id = builders.length;
		builders.push(this);
	}

	/**
		Gets the ID for this `mat.generation.LoopBuilder`. This is its index in
		`mat.generation.LoopBuilder.builders`.
	**/
	public function getId() {
		return id;
	}

	/**
		Adds a new loop to the generated expression.

		`expr` is the expression this loop will iterate over.
	**/
	public function pushNewLoop(expr: Expr) {
		final exprType = try {
			Context.typeExpr(expr).t;
		} catch(_) {
			null;
		};
		pushNewLoopImpl(expr, exprType != null ? exprType.toComplexType() : null);
	}

	/**
		Works like `mat.generation.LoopBuilder.pushNewLoop`, but the user can provide their own
		`haxe.macro.Type` to skip a call to `haxe.macro.Context.typeExpr`.
	**/
	public function pushNewLoopWithType(e: Expr, t: Type) {
		pushNewLoopImpl(e, t.toComplexType());
	}

	inline function pushNewLoopImpl(expression: Expr, expressionType: Null<ComplexType>) {
		loops.push(new Loop(expression, expressionType));
	}

	/**
		Sets the initial expression for the generated block. This should be used to initiate the
		`result` variable. Therefore, this should be used on functions that are changing the type
		of the `result`.

		For example, `isEmpty` would change it to `Bool` and `size` would change it to `Int`.
	**/
	public function setInit(a: Expr) {
		final next = getNextIfExists();
		if(next != null) {
			next.setInit(a);
			return;
		}

		init = a;
	}

	/**
		Appends an expression to the start of the generated expression block before the loops. This 
		is typically used for initializing additional variables to be used in the loops.
	**/
	public function pushInitVar(initVarExpr: Expr) {
		initVars.push(initVarExpr);
	}

	/**
		Adds an expression to execute before "ACTION" for all current loops.

		The `_` identifier used in `a` will be replaced with the most recently generated variable
		identifier from previous pre-actions.
		
		If `incrementMainVar` is `true`, a new variable name will be generated with the intent to
		replace the current variable used to represent this iteration's current item. The `__`
		identifier used in `a` will replaced with the name of this new variable.
	**/
	public function addPreAction(a: Expr, incrementMainVar: Bool = false) {
		final next = getNextIfExists();
		if(next != null) {
			next.addPreAction(a, incrementMainVar);
			return;
		}

		for(l in loops) {
			l.addPreAction(a, incrementMainVar);
		}
	}

	/**
		Sets the ACTION expression for all current loops. By default, this is `result.push(_)`, but
		should be changed depending on the desired `result` type.

		The `_` identifier used in `a` will be replaced with the most recently generated variable
		identifier from the pre-actions.
	**/
	public function setAction(a: Expr, isCompleted: Bool) {
		final next = getNextIfExists();
		if(next != null) {
			next.setAction(a, isCompleted);
			return;
		}

		for(l in loops) {
			l.setAction(a);
		}

		if(isCompleted) {
			complete = true;
			nextState = QueueNext;
		}
	}

	/**
		Sets the final `result` expression that returns the value from the block. This can be
		modified to convert `result` to something else at the last second.
	**/
	public function setResult(e: Expr) {
		result = e;
		complete = true;
		nextState = QueueNext;
	}

	/**
		Add a condition expression to wrap loops with after the first one. This is useful for 
		circumstances where the loops should be ended pre-emptively like `find` or `isEmpty`.
	**/
	public function setSubsequentLoopsCondition(c: Expr) {
		final next = getNextIfExists();
		if(next != null) {
			next.setSubsequentLoopsCondition(c);
			return;
		}

		subsequentLoopsCondition = c;
	}

	/**
		Appends the loops from another `mat.generation.LoopBuilder` into this one.
	**/
	public function mergeSubsequentLoopBuilder(otherBuilder: LoopBuilder) {
		if(otherBuilder.complete) {
			Error.CannotMergeCompleteLoopBuilder.here();
		}
		for(l in otherBuilder.loops) {
			loops.push(l);
		}
	}

	/**
		Removes the returning `result` expression from this builder's final block expression. Useful
		for methods that do not need to accumulate a `result` value.
	**/
	public function clearResult() {
		init = macro @:mergeBlock {};
		for(l in loops) l.clearResult();
		result = macro @:mergeBlock {};
		hasResult = false;
	}

	/**
		Returns the `next` `mat.generation.LoopBuilder` if `nextState` is `HasNext`. If it's
		`QueueNext`, the next `mat.generation.LoopBuilder` will be generated and returned, and the
		`nextState` will be switched to `HasNext`.
	**/
	function getNextIfExists() {
		return switch(nextState) {
			case Single: null;
			case QueueNext: {
				final next = new LoopBuilder();
				next.pushNewLoop(buildInternal());
				nextState = HasNext(next);
				next;
			}
			case HasNext(next): next;
		}
	}

	/**
		If called, the generated expression will include a variable that tracks the index of the
		current element.
	**/
	public function enableIndexTracking() {
		indexTracking = true;
	}

	/**
		Builds the expression.
	**/
	function buildInternal(): Expr {
		final indexTrackingInit = indexTracking ? (macro var i = 0) : (macro @:mergeBlock {});
		final exprs = loops.map(loop -> loop.build(indexTracking));
		if(subsequentLoopsCondition != null) {
			for(i in 1...exprs.length) {
				final e = exprs[i];
				exprs[i] = macro if($subsequentLoopsCondition) {
					$e;
				}
			}
		}

		return macro {
			$init;
			@:mergeBlock $b{initVars};
			$indexTrackingInit;
			@:mergeBlock $b{exprs};
			$result;
		};
	}

	/**
		Builds the expression.

		If `HasNext`, the next `mat.generation.LoopBuilder.build` will be called and returned
		instead.

		If `wrap` is set to `false`, the resulting expression won't be wrapped with
		`mat.generation.MagicIterable.MagicIterableWithData`.
	**/
	public function build(wrap: Bool = true): Expr {
		switch(nextState) {
			case HasNext(forLoop): {
				return forLoop.build();
			}
			case _:
		}

		final resultingExpression = buildInternal();

		// If no resuling value, it cannot be chained.
		// Just return the expression without wrapping anything.
		if(!hasResult || !wrap) {
			return resultingExpression;
		}

		final resultingComplexType = Context.typeExpr(resultingExpression).t.toComplexType();
		return MagicIterableUtils.wrapExprWithData(
			resultingExpression,
			resultingComplexType ?? macro : Any,
			id
		);
	}

	/**
		Prints the resulting expression at this point at compile-time.
	**/
	public function displayResult() {
		switch(nextState) {
			case HasNext(nextLoopBuilder): {
				nextLoopBuilder.displayResult();
				return;
			}
			case _:
		}

		final e = buildInternal();
		final newExpr = e.removeMergeBlocks();
		Context.info(newExpr.toString(), Context.currentPos());
	}

	/**
		Converts an input "magic callback" expression into a `mat.generation.MagicCallback` object.
	**/
	public function makeMagicCallback(e: Expr, name: String, argumentCount: Int = 1) {
		final callbackData = new MagicCallback(e, genName(name), argumentCount);
		if(callbackData.usedName) {
			usedName(name);
		}
		if(callbackData.init != null) {
			initVars.push(callbackData.init);
		}
		return callbackData;
	}

	/**
		Generates a new unique variable name by appending a number to `str`.
	**/
	public function genName(str: String) {
		if(!initVarNames.exists(str)) {
			initVarNames[str] = 1;
		}
		final id = initVarNames[str];
		return str + id;
	}

	/**
		Marks that a name prefix was used.
	**/
	public function usedName(str: String) {
		initVarNames[str] = (initVarNames[str] ?? 1) + 1;
	}
}

#end
