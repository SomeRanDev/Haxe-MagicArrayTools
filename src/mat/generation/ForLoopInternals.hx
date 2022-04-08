package mat.generation;

#if macro

using mat.generation.ExprHelpers;

import haxe.macro.Expr;

class ForLoopInternals {
	var iterated: Expr;
	var preActions: Array<Expr>;
	var action: Expr;

	var currentName: String;
	var currentNameId: Int;

	public function new(e: Expr) {
		iterated = e;
		preActions = [];
		action = macro result.push(_);
		currentName = "it";
		currentNameId = 1;
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
		action = a;
	}

	public function build(): Expr {
		return macro @:mergeBlock {
			for(it in $iterated) {
				@:mergeBlock $b{preActions}
				${ action.replaceUnderscore(currentName) };
			}
		}
	}
}

#end
