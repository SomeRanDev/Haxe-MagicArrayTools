package mat.generation;

#if macro

import mat.generation.ForLoop;
import mat.generation.ExprHelpers.removeMergeBlocks;

import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Compiler;

using haxe.macro.ExprTools;

function setup() {
	Compiler.addGlobalMetadata("", "@:build(mat.generation.MagicBuildSetup.setupMagicArrayTools())", true);
}

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
	"stringifyAndTrace",
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

#end
