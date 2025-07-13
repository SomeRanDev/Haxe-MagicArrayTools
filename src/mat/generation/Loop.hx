package mat.generation;

#if (macro || mat_runtime)

import haxe.macro.Expr;

using mat.extension_functions.ExprEx;

/**
	The `mat.generation.LoopBuilder` may generate multiple loops, but this class represents an
	individual `for` or `while` loop.
**/
class Loop {
	var iterated: Expr;
	var iteratedOriginalType: Null<ComplexType>;
	var preActions: Array<Expr>;
	var action: Expr;

	var currentName: String;
	var currentNameId: Int;

	public function new(expression: Expr, expressionType: Null<ComplexType>) {
		iterated = preprocessIteratedExpression(expression, expressionType);
		iteratedOriginalType = expressionType;
		preActions = [];
		action = macro result.push(_);
		currentName = "it";
		currentNameId = 1;
	}

	static function preprocessIteratedExpression(
		expression: Expr,
		expressionType: Null<ComplexType>
	) {
		return switch(expressionType) {
			case (macro : Int) | (macro : StdTypes.Int): macro 0...$expression;
			case _: expression;
		};
	}

	public function addPreAction(a: Expr, incrementMainVar: Bool) {
		preActions.push(if(incrementMainVar) {
			final newName = "it" + (++currentNameId);
			final result = a.replaceUnderscore(currentName, newName);
			currentName = newName;
			result;
		} else {
			a.replaceUnderscore(currentName);
		});
	}

	public function setAction(a: Expr) {
		action = a.replaceUnderscore(currentName);
	}

	public function clearResult() {
		setAction(macro @:mergeBlock {});
	}

	public function build(indexTracking: Bool): Expr {
		final indexTrackingIncrement = indexTracking ? (macro i++) : (macro @:mergeBlock {});
		return macro @:mergeBlock {
			for(it in $iterated) {
				@:mergeBlock $b{preActions}
				${ action.replaceUnderscore(currentName) };
				$indexTrackingIncrement;
			}
		}
	}
}

#end
