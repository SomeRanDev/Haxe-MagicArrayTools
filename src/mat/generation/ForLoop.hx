package mat.generation;

#if macro

using mat.generation.ExprHelpers;
import mat.generation.ExprHelpers.removeMergeBlocks;

import mat.generation.MagicBuildSetup;

import mat.generation.MagicParser.parseStaticCalls;

import mat.generation.TypeHelpers.isTypeIterable;

import haxe.macro.Expr;
import haxe.macro.Context;

using haxe.macro.ExprTools;

class ForLoop {
	var init: Expr;
	var initVars: Array<Expr>;
	var loops: Array<ForLoopInternals>;
	var result: Null<Expr>;

	var initVarNames: Map<String,Int>;

	var isIterable: Bool;
	var complete: Bool;
	var indexTracking: Bool;
	var displayForLoop: Bool;

	public function new() {
		init = macro final result = [];
		initVars = [];
		loops = [];
		result = macro result;

		initVarNames = [];
		
		isIterable = false;
		complete = false;
		indexTracking = false;
		displayForLoop = false;
	}

	public function setCoreIterated(e: Expr) {
		isIterable = checkType(e);
		if(isIterable) {
			initLoops(e);
		} else {
			result = e;
		}
	}

	function checkType(e: Expr) {
		return try {
			isTypeIterable(Context.typeExpr(e).t);
		} catch(e) {
			false;
		};
	}

	function initLoops(e: Expr) {
		if(loops.length == 0) {
			loops.push(new ForLoopInternals(e));
		} else {
			throw "Cannot assign core-iterated, but for-loops already exist.";
		}
	}

	public function addPreAction(a: Expr, incrementMainVar: Bool = false) {
		for(l in loops) {
			l.addPreAction(a, incrementMainVar);
		}
	}

	public function setAction(a: Expr) {
		for(l in loops) {
			l.setAction(a);
		}
		complete = true;
	}

	function mergeSubForLoop(fl: ForLoop) {
		if(fl.complete) {
			throw "Cannot merge ForLoop that does not return array.";
		}
		for(l in fl.loops) {
			loops.push(l);
		}
	}

	public function clearResult() {
		init = macro @:mergeBlock {};
		for(l in loops) l.clearResult();
		result = macro @:mergeBlock {};
	}

	public function enableIndexTracking() {
		indexTracking = true;
	}

	function buildInternal(): Expr {
		if(!isIterable) {
			return result;
		}

		final indexTrackingInit = indexTracking ? (macro var i = 0) : (macro @:mergeBlock {});
		final exprs = loops.map(fl -> fl.build(indexTracking));
		return macro {
			$init;
			@:mergeBlock $b{initVars};
			$indexTrackingInit;
			@:mergeBlock $b{exprs};
			$result;
		}
	}

	public function build(): Expr {
		final e = buildInternal();
	
		if(displayForLoop) {
			final newExpr = removeMergeBlocks(e);
			if(newExpr == null) return e;
			final str = newExpr.toString();
			final p = Context.currentPos();
			return macro {
				@:pos(p) trace($v{str});
				$e;
			}
		}
		
		return e;
	}

	public function callModifier(name: String, e: Array<Expr>, callPosition: Position) {
		if(!isIterable) {
			result = { pos: callPosition, expr: ECall({ pos: result.pos, expr: EField(result, name) }, e) };
			return;
		}
		if(name == "displayForLoop") {
			displayForLoop = true;
			return;
		}
		if(complete) {
			Context.warning('Cannot call $name on completed for-loop.', callPosition);
		}

		final oneParam = switch(name) {
			case "map": map;
			case "filter": filter;
			case "forEach": forEach;
			case "forEachThen": forEachThen;

			case "count": count;
			case "find": find;
			case "indexOf": indexOf;

			case "concat": concat;

			case _: null;
		}
		if(oneParam != null) {
			makeCall(oneParam, 1, e, name, callPosition);
			return;
		}

		final zeroParam: Dynamic = switch(name) {
			case "count": count;
			case "size": size;
			case "isEmpty": isEmpty;

			case "asList": asList;
			case "asVector": asVector;

			case _: null;
		}
		if(zeroParam != null) {
			makeCall(zeroParam, 0, e, name, callPosition);
			return;
		}
	}

	function makeCall(f: Dynamic, paramCount: Int, params: Array<Expr>, name: String, callPosition: Position) {
		if(paramCount == 1) {
			if(params.length == 0) {
				Context.error('One argument required for call to $name', callPosition);
				return;
			}
			for(p in params) {
				f(p);
			}
		} else if(paramCount == 0) {
			if(params.length > 0) {
				Context.error('${params.length} unwanted arguments passed for call to $name', callPosition);
				return;
			}
			f();
		}
	}

	function makeMagicCallback(e: Expr, name: String) {
		final callbackData = new MagicCallback(e, genName(name));
		if(callbackData.usedName) usedName(name);
		if(callbackData.init != null) initVars.push(callbackData.init);
		return callbackData;
	}

	public function map(e: Expr) {
		final callbackData = makeMagicCallback(e, "map");
		final e2 = callbackData.expr;
		final p = e.pos;
		final pre = macro @:pos(p) final __ = $e2;
		addPreAction(pre, true);
	}

	public function filter(e: Expr) {
		final callbackData = makeMagicCallback(e, "filter");
		final e2 = callbackData.expr;
		final p = e.pos;
		final pre = macro @:pos(p) if(!($e2)) continue;
		addPreAction(pre);
	}

	public function forEach(e: Expr) {
		final callbackData = makeMagicCallback(e, "forEach");
		final e2 = callbackData.expr;
		final p = e.pos;
		final pre = macro @:pos(p) $e2;
		addPreAction(pre);
		clearResult();
	}

	public function forEachThen(e: Expr) {
		final callbackData = makeMagicCallback(e, "forEachThen");
		final e2 = callbackData.expr;
		final p = e.pos;
		final pre = macro @:pos(p) $e2;
		addPreAction(pre);
	}

	public function size() {
		init = macro var result = 0;
		setAction(macro result++);
	}

	public function count(e: Null<Expr> = null) {
		if(e == null) {
			return size();
		}

		final callbackData = makeMagicCallback(e, "count");
		init = macro var result = 0;
		final e2 = callbackData.expr;
		setAction(macro @:mergeBlock {
			if($e2) {
				result++;
			}
		});
	}

	public function isEmpty() {
		init = macro var result = true;
		setAction(macro @:mergeBlock {
			result = false;
			break;
		});
	}

	public function find(e: Expr) {
		final callbackData = makeMagicCallback(e, "find");

		init = macro var result = null;

		final e2 = callbackData.expr;
		setAction(macro @:mergeBlock {
			if($e2) {
				result = _;
				break;
			}
		});
	}

	public function indexOf(e: Expr) {
		init = macro var result = -1;
		enableIndexTracking();
		setAction(macro @:mergeBlock {
			if($e == _) {
				result = i;
				break;
			}
		});
	}

	public function asList() {
		init = macro final result = new haxe.ds.List();
		setAction(macro result.add(_));
	}

	public function asVector() {
		result = macro haxe.ds.Vector.fromArrayCopy(result);
		complete = true;
	}

	public function concat(e: Expr) {
		final fl: ForLoop = parseStaticCalls(MagicBuildSetup.convertInternal(e), true);
		mergeSubForLoop(fl);
	}

	function genName(str: String) {
		if(!initVarNames.exists(str)) {
			initVarNames[str] = 1;
		}
		final id = initVarNames[str];
		return str + id;
	}
	
	function usedName(str: String) {
		initVarNames[str]++;
	}
}

#end
