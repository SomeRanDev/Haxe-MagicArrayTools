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

macro function forEach(ethis: Expr, callback: Expr) {
	final fl = parseStaticCalls(macro MagicArrayTools.forEach($ethis, $callback));
	final e = fl.build();
	return e;
}

macro function forEachThen(ethis: Expr, callback: Expr) {
	final fl = parseStaticCalls(macro MagicArrayTools.forEachThen($ethis, $callback));
	final e = fl.build();
	return e;
}

macro function size(ethis: Expr) {
	final fl = parseStaticCalls(macro MagicArrayTools.size($ethis));
	final e = fl.build();
	return e;
}

macro function count(ethis: Expr, callback: Expr) {
	final fl = parseStaticCalls(macro MagicArrayTools.count($ethis, $callback));
	final e = fl.build();
	return e;
}

macro function isEmpty(ethis: Expr) {
	final fl = parseStaticCalls(macro MagicArrayTools.isEmpty($ethis));
	final e = fl.build();
	return e;
}

macro function find(ethis: Expr, callback: Expr) {
	final fl = parseStaticCalls(macro MagicArrayTools.find($ethis, $callback));
	final e = fl.build();
	return e;
}

macro function indexOf(ethis: Expr, obj: Expr) {
	final fl = parseStaticCalls(macro MagicArrayTools.indexOf($ethis, $obj));
	final e = fl.build();
	return e;
}

macro function asList(ethis: Expr) {
	final fl = parseStaticCalls(macro MagicArrayTools.asList($ethis));
	final e = fl.build();
	return e;
}

macro function asVector(ethis: Expr) {
	final fl = parseStaticCalls(macro MagicArrayTools.asVector($ethis));
	final e = fl.build();
	return e;
}
