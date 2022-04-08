package;

#if macro

import generation.ForLoop;

import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Compiler;

using haxe.macro.ExprTools;

final RequiredUsingName = "MagicArrayTools_Fields_";

function setupMagicArrayTools() {
	var isUsing = false;
	for(u in Context.getLocalUsing()) {
		if(u.get().name == RequiredUsingName) {
			isUsing = true;
			break;
		}
	}
	if(!isUsing) return null;

	final fields = Context.getBuildFields();
	for(f in fields) {
		final e = switch(f.kind) {
			case FVar(_, e): e;
			case FProp(_, _, _, e): e;
			case FFun(fun): fun.expr;
		}
		if(e != null) e.expr = convert(e).expr;
	}
	
	return fields;
}

function convert(e: Null<Expr>): Null<Expr> {
	if(e == null) return null;
	return e.map(convertInternal);
}

final ExtensionMethods = [
	"debugTrace",
	"map", "filter", "forEach", "forEachThen"
];

// Macro static extension functions cannot analyze the "this" Expr passed.
// https://haxe.org/manual/macro-limitations-static-extension.html
//
// To circumvent this, modules "using MagicArrayTools", will convert all 
// field-access function calls that use the extension function names to 
// direct calls to the MagicArrayTool module.
function convertInternal(e: Expr): Expr {
	switch(e.expr) {
		case ECall(eCall, params): {
			switch(eCall.expr) {
				case EField(eField, f): {
					final newEField = convertInternal(eField);
					if(ExtensionMethods.contains(f)) {
						return convertToDirectCall(
							f,
							[newEField].concat(params),
							[e.pos, eCall.pos, newEField.pos]
						);
					}
				}
				case _:
			}
		}
		case _:
	}
	return e.map(convertInternal);
}

function convertToDirectCall(name: String, params: Array<Expr>, positions: Array<Position>) {
	return {
		pos: positions[0],
		expr: ECall({
			pos: positions[1],
			expr: EField({
				pos: positions[2],
				expr: EConst(CIdent("MagicArrayTools"))
			}, name)
		}, params)
	};
}

function setup() {
	Compiler.addGlobalMetadata("", "@:build(MagicArrayTools.setupMagicArrayTools())", true);
}

#end

macro function debugTrace(ethis: Expr): Expr {
	final str = ethis.toString();
	return macro {
		$ethis;
		trace($v{str});
	}
}

macro function map(ethis: Expr, callback: Expr) {
	final calls = parseStaticCalls(macro MagicArrayTools.map($ethis, $callback));

	for(c in calls) {
		trace(c.target);
	}

	final fl = new ForLoop(ethis);

	/*for(c in calls) {
		switch(c.name) {
			case "map": {
				fl.map()
			}
		}
	}

	final fl = new ForLoop(ethis);*/
	final e = fl.build();
	return macro $e;
}

#if macro
function parseStaticCalls(e: Expr) {
	final arr = parseStaticCall(e, []);
	return arr;
}

function parseStaticCall(e: Expr, arr: Array<{name: String, target: Null<Expr>, params: Array<Expr>}>) {
	 return switch(e.expr) {
		case ECall(eCall, params): {
			final name = isMagicArrayToolsFunction(eCall);
			final target = params[0];
			final callData = parseStaticCall(target, arr);
			trace(callData);
			arr.push({
				name: name,
				target: callData == null ? target : null,
				params: params.slice(1)
			});
			arr;
		}
		case _: null;
	}
}

function isMagicArrayToolsFunction(e: Expr) {
	switch(e.expr) {
		case EField(i, f): {
			if(isMagicArrayTools(i)) {
				return f;
			}
		}
		case _:
	}
	return null;
}

function isMagicArrayTools(e: Expr) {
	return switch(e.expr) {
		case EConst(i): {
			switch(i) {
				case CIdent(c): c == "MagicArrayTools";
				case _: false;
			}
		}
		case _: false;
	}
}
#end