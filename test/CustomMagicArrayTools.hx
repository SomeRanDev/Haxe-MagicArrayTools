package;

import MagicArrayTools.MagicIterableExprOf;
import MagicArrayTools.MagicCallbackExprOf;
import mat.generation.LoopBuilder;

import haxe.macro.Expr;

using mat.extension_functions.ExprEx;

/**
	Generates the expression for inserting via sort.
**/
function generateSortExpr(operationExpression: Expr): Expr {
	return macro @:mergeBlock {
		if(result.length == 0) {
			// If `result` empty, just add the element.
			result.push(_);
		} else {
			// If not empty, find where to inject the element.
			var found = false;
			for(i in 0...result.length) {
				if($operationExpression) {
					found = true;
					result.insert(i, _);
					break;
				}
			}
			if(!found) {
				result.push(_);
			}
		}
	};
}

/**
	Returns the elements in ascending order, injecting once `newElement < currentElement`.
**/
macro function ascending<T>(ethis: MagicIterableExprOf<T>): MagicIterableExprOf<Bool> {
	final loopBuilder = LoopBuilder.findLoopBuilderFromPreviousExpr(ethis) ?? return ethis;
	loopBuilder.setAction(generateSortExpr(macro _ < result[i]), true);
	return loopBuilder.build();
}

/**
	Returns the elements in descending order, injecting once `newElement > currentElement`.
**/
macro function descending<T>(ethis: MagicIterableExprOf<T>): MagicIterableExprOf<Bool> {
	final loopBuilder = LoopBuilder.findLoopBuilderFromPreviousExpr(ethis) ?? return ethis;
	loopBuilder.setAction(generateSortExpr(macro _ > result[i]), true);
	return loopBuilder.build();
}

/**
	Returns the elements sorted using the provided sorting algorithm.
**/
macro function sort<T>(ethis: MagicIterableExprOf<T>, callbackArgument: MagicCallbackExprOf<(T, T) -> T>): MagicIterableExprOf<T> {
	final loopBuilder = LoopBuilder.findLoopBuilderFromPreviousExpr(ethis) ?? return ethis;

	final callbackData = loopBuilder.makeMagicCallback(callbackArgument, "sort", 2);
	loopBuilder.setAction(generateSortExpr(macro @:mergeBlock {
		final current = result[i];
		${callbackData.expr.replaceNumberedUnderscores(["_", "current"])}
	}), true);

	return loopBuilder.build();
}
