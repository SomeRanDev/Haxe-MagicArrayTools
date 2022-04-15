package;

#if macro
import mat.generation.ForLoop;
import mat.generation.MagicParser.parseStaticCalls;

import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Compiler;

using haxe.macro.ExprTools;
#end

#if !disableAutoForLoop

#if macro

function parse(name: String, ethis: Expr, args: Array<Expr>) {
	return args.length == 0 ?
		parseStaticCalls(macro MagicArrayTools.$name($ethis)) :
		(args.length == 1 ?
			parseStaticCalls(macro MagicArrayTools.$name($ethis, $e{args[0]})) :
			parseStaticCalls(macro MagicArrayTools.$name($ethis, $a{args}))
		);
}

function parseAndBuild(name: String, ethis: Expr, args: Array<Expr>) {
	final fl = parse(name, ethis, args);
	final e = fl.build();
	return e;
}

#end

@:noUsing macro function displayForLoop(ethis: Expr, args: Array<Expr>)
	return parseAndBuild("displayForLoop", ethis, args);

@:noUsing macro function map(ethis: Expr, args: Array<Expr>)
	return parseAndBuild("map", ethis, args);

@:noUsing macro function filter(ethis: Expr, args: Array<Expr>)
	return parseAndBuild("filter", ethis, args);

@:noUsing macro function forEach(ethis: Expr, args: Array<Expr>)
	return parseAndBuild("forEach", ethis, args);

@:noUsing macro function forEachThen(ethis: Expr, args: Array<Expr>)
	return parseAndBuild("forEachThen", ethis, args);

@:noUsing macro function size(ethis: Expr, args: Array<Expr>)
	return parseAndBuild("size", ethis, args);

@:noUsing macro function count(ethis: Expr, args: Array<Expr>)
	return parseAndBuild("count", ethis, args);

@:noUsing macro function isEmpty(ethis: Expr, args: Array<Expr>)
	return parseAndBuild("isEmpty", ethis, args);

@:noUsing macro function find(ethis: Expr, args: Array<Expr>)
	return parseAndBuild("find", ethis, args);

@:noUsing macro function indexOf(ethis: Expr, args: Array<Expr>)
	return parseAndBuild("indexOf", ethis, args);

@:noUsing macro function asList(ethis: Expr, args: Array<Expr>)
	return parseAndBuild("asList", ethis, args);

@:noUsing macro function asVector(ethis: Expr, args: Array<Expr>)
	return parseAndBuild("asVector", ethis, args);

@:noUsing macro function concat(ethis: Expr, args: Array<Expr>)
	return parseAndBuild("concat", ethis, args);

#end

macro function buildForLoop(ethis: Expr) {
	final fl = parseStaticCalls(ethis);
	final e = fl.build();
	return e;
}
