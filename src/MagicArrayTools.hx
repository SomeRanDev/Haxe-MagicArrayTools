package;

#if macro
import mat.generation.ForLoop;
import mat.generation.ExprHelpers.removeMergeBlocks;
import mat.generation.MagicParser.parseStaticCalls;

import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Compiler;

using haxe.macro.ExprTools;
#end

macro function stringifyAndTrace(ethis: Expr): Expr {
	final fl = parseStaticCalls(ethis);
	final e = fl.build();

	final newExpr = removeMergeBlocks(e);
	if(newExpr == null) return macro $ethis;

	final str = newExpr.toString();
	final p = Context.currentPos();
	return macro {
		@:pos(p) trace($v{str});
		$e;
	}
}

macro function map(ethis: Expr, callback: Expr) {
	final fl = parseStaticCalls(macro MagicArrayTools.map($ethis, $callback));
	final e = fl.build();
	return e;
}

macro function filter(ethis: Expr, callback: Expr) {
	final fl = parseStaticCalls(macro MagicArrayTools.filter($ethis, $callback));
	final e = fl.build();
	return e;
}
