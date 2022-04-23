package mat.generation;

#if macro

import mat.generation.ForLoop;
import mat.generation.ExprHelpers.removeMergeBlocks;

import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Compiler;

using haxe.macro.ExprTools;

final ExtensionMethods = [
	"displayForLoop",
	"map", "filter", "forEach", "forEachThen",
	"size", "count", "isEmpty", "find", "findIndex", "indexOf",
	"every", "some", "reduce",
	"asArray", "asList", "asVector",
	"concat", "fill"
];

var EnabledMAT = true;
var SetupCalled = false;

function setup() {
	if(SetupCalled) return;
	Compiler.addGlobalMetadata("", "@:build(mat.generation.MagicBuildSetup.setupMagicArrayTools())", true);
	SetupCalled = true;
}

function importIsMAT(im: ImportExpr) {
	if(im.mode == INormal) {
		for(p in im.path) {
			if(p.name == "MagicArrayTools") {
				return true;
			}
		}
	}
	return false;
}

function isUsingMAT() {
	for(u in Context.getLocalUsing()) {
		if(u.get().name == "MagicArrayTools_Fields_") {
			return true;
		}
	}
	for(im in Context.getLocalImports()) {
		if(importIsMAT(im)) {
			return true;
		}
	}
	return false;
}

function setupMagicArrayTools() {
	if(!isUsingMAT()) {
		return null;
	}

	if(Context.defined("disableAutoForLoop")) {
		EnabledMAT = false;
	}

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

// Macro static extension functions cannot analyze the "this" Expr passed.
// https://haxe.org/manual/macro-limitations-static-extension.html
//
// To circumvent this, modules "using MagicArrayTools", will convert all 
// field-access function calls that use the extension function names to 
// direct calls to the MagicArrayTool module.
function convertInternal(e: Expr): Expr {
	switch(e.expr) {
		case EMeta(m, _): {
			if(EnabledMAT && m.name == "disableAutoForLoop") {
				EnabledMAT = false;
				final result = e.map(convertInternal);
				EnabledMAT = true;
				return result;
			}
		}
		case ECall(eCall, params): {
			switch(eCall.expr) {
				case EField(eField, f): {
					final buildForLoop = f == "buildForLoop";
					final newEField = if(!EnabledMAT && buildForLoop) {
						EnabledMAT = true;
						final result = convertInternal(eField);
						EnabledMAT = false;
						result;
					} else {
						convertInternal(eField);
					}
					if(buildForLoop || (EnabledMAT && ExtensionMethods.contains(f))) {
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

#end
