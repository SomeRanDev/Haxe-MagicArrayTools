package mat.generation;

#if macro

import haxe.macro.Expr;

using mat.generation.ExprHelpers;

function parseStaticCalls(e: Expr, expectForLoop: Bool = false) {
	final fl = new ForLoop();
	if(!parseStaticCall(e, fl, expectForLoop) && expectForLoop) {
		fl.setCoreIterated(e);
	}
	return fl;
}

function parseStaticCall(e: Expr, fl: ForLoop, expectForLoop: Bool) {
	 switch(e.expr) {
		case ECall(eCall, params): {
			if(expectForLoop) {
				if(shouldExpectForLoop(eCall, fl, expectForLoop)) {
					return true;
				}
			}
			
			final name = isMagicArrayToolsFunction(eCall);
			if(name != null) {
				return parseCall(e, name, params, fl, expectForLoop);
			}
		}
		case EParenthesis(_e): {
			return parseStaticCall(_e, fl, expectForLoop);
		}
		case _: {
		}
	}
	return false;
}

function parseCall(e: Expr, name: String, params: Array<Expr>, fl: ForLoop, expectForLoop: Bool) {
	final target = params[0];
	final callData = parseStaticCall(target, fl, expectForLoop);
	if(!callData) {
		fl.setCoreIterated(target);
	}
	fl.callModifier(name, params.slice(1), e.pos);
	return true;
}

function isMagicArrayToolsFunction(e: Expr): Null<String> {
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

function shouldExpectForLoop(eCall: Expr, fl: ForLoop, expectForLoop: Bool) {
	switch(eCall.expr) {
		case EField(newExpr, f): {
			if(f == "buildForLoop") {
				return parseStaticCall(newExpr, fl, expectForLoop);
			}
		}
		case _:
	}
	return false;
}

#end