package mat.extension_functions;

#if (macro || mat_runtime)

import mat.utils.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

var iterableType: Null<Type> = null;
var iteratorType: Null<Type> = null;

/**
	Returns `true` if `t` is an `Iterable` or `Iterator`.
**/
function isTypeIterable(self: Null<Type>) {
	if(self == null) {
		return false;
	}
	if(iterableType == null) {
		final complexIterableType = macro : Iterable<Any>;
		final complexIteratorType = macro : Iterator<Any>;
		iterableType = Context.resolveType(complexIterableType, Context.currentPos());
		iteratorType = Context.resolveType(complexIteratorType, Context.currentPos());
	}
	if(iterableType != null && iteratorType != null) {
		return Context.unify(self, iterableType) || Context.unify(self, iteratorType);
	}
	return false;
}

#end
