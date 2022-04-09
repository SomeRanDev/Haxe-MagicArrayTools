package mat.generation;

#if macro

import haxe.macro.Type;
import haxe.macro.Context;
import haxe.macro.Expr;

var iterableType: Null<Type> = null;
var iteratorType: Null<Type> = null;

function isTypeIterable(t: Null<Type>) {
	if(t == null) {
		return false;
	}
	if(iterableType == null) {
		final complexIterableType = macro : Iterable<Dynamic>;
		final complexIteratorType = macro : Iterator<Dynamic>;
		iterableType = Context.resolveType(complexIterableType, Context.currentPos());
		iteratorType = Context.resolveType(complexIteratorType, Context.currentPos());
	}
	return Context.unify(t, iterableType) || Context.unify(t, iteratorType);
}

#end
