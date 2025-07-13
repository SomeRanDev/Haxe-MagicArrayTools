package mat.extension_functions;

#if (macro || mat_runtime)

import haxe.macro.Expr;

using haxe.macro.ExprTools;
using mat.extension_functions.ExprEx;
using mat.utils.Error;

/**
	If the expression is `EMeta` and the meta's name matches `metaName`, the internal expression is
	returned. Otherwise, `null` is returned.
**/
function isMeta(self: Expr, metaName: String): Null<Expr> {
	switch(self.expr) {
		case EMeta(metaEntry, inner): {
			if(metaEntry.name == metaName) {
				return inner;
			}
		}
		case _:
	}
	return null;
}

/**
	If the expression is `EReturn`, the returned expression is returned. Otherwise, `null` is
	returned.
**/
function isReturn(self: Expr): Null<Expr> {
	return switch(self.expr) {
		case EReturn(ex): ex;
		case EBlock(exprs): {
			if(exprs.length == 1) {
				isReturn(exprs[0]);
			} else {
				null;
			}
		}
		case EMeta(m, ex): {
			final returnedExpr = isReturn(ex);
			if(returnedExpr != null) {
				{
					pos: self.pos,
					expr: EMeta(m, returnedExpr)
				};
			} else {
				null;
			}
		}
		case _: null;
	}
}

/**
	Returns `true` if a `true` expression, `false` if `false`, `null` if not a bool expression.
**/
function isBoolLiteral(self: Expr): Null<Bool> {
	return switch(self.expr) {
		case EConst(c): {
			switch(c) {
				case CIdent(s): {
					if(s == "true") true;
					else if(s == "false") false;
					else null;
				}
				case _: null;
			}
		}
		case _: null;
	}
}

/**
	Returns `true` if the expression is a literal `0`.
**/
function isZero(self: Expr): Bool {
	return switch(self.expr) {
		case EConst(CInt("0")): true;
		case _: false;
	}
}

/**
	Returns `true` if the expression is a literal `null`.
**/
function isNullLiteral(self: Expr): Bool {
	return switch(self.expr) {
		case EConst(CIdent("null")): true;
		case _: false;
	}
}

/**
	Returns `true` if `self` is a function expression with the same number of arguments as `argCount`.
**/
function isFunction(self: Expr, argCount: Int): Bool {
	return switch(self.expr) {
		case EFunction(k, f): {
			f.args != null && f.args.length == argCount;
		}
		case _: false;
	}
}

/**
	For functions like `MagicArrayTools.indexOf`, where the argument should be an object, it's
	likely an operation expression may be passed (function call, array access, etc.).

	If it's an operation, I want to store it in variable instead of inlining in the for-loop. This
	function checks to see if the operation has a runtime cost beyond variable access.
**/
function isCostly(self: Expr) {
	return switch(self.expr) {
		case EConst(c): {
			switch(c) {
				// if single-quotes, there could be an expression in it?
				case CString(_, SingleQuotes): true;
				// regexp converts to object creation on most platforms?
				case CRegexp(_, _): true;
				case _: false;
			}
		}
		case EField(accessed, _, Normal | null): isCostly(accessed);
		case EParenthesis(inner): isCostly(inner);
		case EMeta(_, inner): isCostly(inner);
		case _: true;
	}
}

/**
	Given an expression, replaces the underscore identifier with an identifier expression of name
	`name`.

	If `doubleUnderscore` is not `null`, double underscore identifiers are replaced with it as an
	identifier.
**/
function replaceUnderscore(self: Expr, name: String, doubleUnderscore: Null<String> = null): Expr {
	switch(self.expr) {
		case EConst(c): {
			switch(c) {
				case CIdent(str): {
					if(str == "_") {
						return { expr: EConst(CIdent(name)), pos: self.pos };
					} else if(doubleUnderscore != null && str == "__") {
						return { expr: EConst(CIdent(doubleUnderscore)), pos: self.pos };
					}
				}
				case _:
			}
		}
		case EVars(vars): {
			return {
				pos: self.pos,
				expr: EVars(vars.map(function(v) {
					final result: haxe.macro.Expr.Var = Reflect.copy(v) ?? { name: "" };
					result.name = (if(v.name == "_") {
						name;
					} else if(doubleUnderscore != null && v.name == "__") {
						doubleUnderscore;
					} else {
						v.name;
					});
					result.expr = (if(v.expr != null) {
						replaceUnderscore(v.expr, name, doubleUnderscore);
					} else {
						null;
					});
					return result;
				}))
			};
		}
		case _:
	}
	return self.map(_e -> replaceUnderscore(_e, name, doubleUnderscore));
}

/**
	Given an expression, replaces the numbered underscore identifiers with an identifier expression
	obtained from `names` correlating to the underscore's number (ie. `_2` will retrieve the name
	of index `1` from `names`).

	If `doubleUnderscore` is not `null`, double underscore identifiers are replaced with it as an
	identifier.
**/
function replaceNumberedUnderscores(
	self: Expr,
	names: Array<String>,
	disallowUnderscore: Bool = true,
	doubleUnderscore: Null<String> = null
): Expr {
	switch(self.expr) {
		case EConst(c): {
			switch(c) {
				case CIdent(str) if(disallowUnderscore && str == "_"): {
					Error.UnderscoreInMultiArgumentCallback.atFormatted(self.pos, [
						Std.string(names.length)
					]);
				}
				case CIdent(str): {
					final index = isNumberedUnderscore(str);
					if(index != null && index >= 0 && index < names.length) {
						return { expr: EConst(CIdent(names[index])), pos: self.pos };
					} else if(doubleUnderscore != null && str == "__") {
						return { expr: EConst(CIdent(doubleUnderscore)), pos: self.pos };
					}
				}
				case _:
			}
		}
		case EVars(vars): {
			return {
				pos: self.pos,
				expr: EVars(vars.map(function(v) {
					final result: haxe.macro.Expr.Var = Reflect.copy(v) ?? { name: "" };
					final index = isNumberedUnderscore(v.name);
					result.name = (if(index != null && index >= 0 && index < names.length) {
						names[index];
					} else if(doubleUnderscore != null && v.name == "__") {
						doubleUnderscore;
					} else {
						v.name;
					});
					result.expr = (if(v.expr != null) {
						replaceNumberedUnderscores(v.expr, names, doubleUnderscore);
					} else {
						null;
					});
					return result;
				}))
			};
		}
		case _:
	}
	return self.map(_e -> replaceNumberedUnderscores(_e, names, doubleUnderscore));
}

/**
	Extracts the index from a numbered underscore identifier. For example, `_1` would be `0`, `_2`
	would be `1`, etc. Returns `null` if `name` isn't a valid numbered underscore identifier.
**/
function isNumberedUnderscore(name: String): Null<Int> {
	if(name.length < 1) {
		return null;
	}

	if(name.charAt(0) != "_") {
		return null;
	}

	final index = Std.parseInt(name.substring(1));
	if(index == null) {
		return null;
	}

	return index < 1 ? null : index - 1;
}

/**
	Replaces all identifiers within `self` of name `name` with underscore identifiers.
**/
function replaceIdentWithUnderscore(self: Expr, name: String): Expr {
	switch(self.expr) {
		case EConst(c): {
			switch(c) {
				case CIdent(str): {
					if(str == name) {
						return { expr: EConst(CIdent("_")), pos: self.pos };
					}
				}
				case _:
			}
		}
		case _:
	}
	return self.map(_e -> replaceIdentWithUnderscore(_e, name));
}

/**
	Replaces all identifiers within `self`, with names in `names`, with numbered underscore
	identifiers correlating to their index within `names`. For example, if the name is of index `2`
	in `names` (aka. the third element), it would be replaced with `_3`.
**/
function replaceMultipleIdentsWithNumberedUnderscore(self: Expr, names: Array<String>): Expr {
	switch(self.expr) {
		case EConst(c): {
			switch(c) {
				case CIdent(str): {
					final index = names.indexOf(str);
					if(index >= 0) {
						return { expr: EConst(CIdent("_" + (index + 1))), pos: self.pos };
					}
				}
				case _:
			}
		}
		case _:
	}
	return self.map(_e -> replaceMultipleIdentsWithNumberedUnderscore(_e, names));
}

/**
	Removes every `@:implicitReturn`.
**/
function stripImplicitReturnMetadata(self: Expr) {
	switch(self.expr) {
		case EMeta(metaEntry, inner): {
			if(metaEntry.name == ":implicitReturn") {
				return inner.map(stripImplicitReturnMetadata);
			}
		}
		case _:
	}
	return self.map(stripImplicitReturnMetadata);
}

/**
	Merges all `@:mergeBlock` expressions within `self`.
**/
function removeMergeBlocks(self: Expr): Expr {
	final newExprDef = switch(self.expr) {
		case EBlock(exprs): {
			EBlock(removeMergeBlocksFromArray(exprs));
		}
		case _: self.expr;
	}
	final newExpr = { expr: newExprDef, pos: self.pos };
	return newExpr.map(removeMergeBlocks);
}

/**
	Given an array of expressions, returns a copy with `@:mergeBlock { ... }` expressions replaced
	with their contents within the array.
**/
function removeMergeBlocksFromArray(exprs: Array<Expr>): Array<Expr> {
	final result = [];
	for(e in exprs) {
		switch(e.expr) {
			case EMeta(s, me): {
				if(s.name == ":mergeBlock") {
					switch(me.expr) {
						case EBlock(blockExprs): {
							final newBlockExprs = removeMergeBlocksFromArray(blockExprs);
							for(be in newBlockExprs) {
								result.push(be);
							}
						}
						case _: result.push(me);
					}
				} else {
					result.push(e);
				}
			}
			case _: result.push(e);
		}
	}
	return result;
}

#end
