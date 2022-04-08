package mat.generation;

#if macro

using mat.generation.ExprHelpers;

import haxe.macro.Expr;
import haxe.macro.Context;

using haxe.macro.ExprTools;

class ForLoop {
	var init: Expr;
	var initVars: Array<Expr>;
	var loops: Array<ForLoopInternals>;
	var result: Null<Expr>;

	var initVarNames: Map<String,Int>;

	var indexTracking: Bool;

	var complete: Bool;

	public function new() {
		init = macro final result = [];
		initVars = [];
		loops = [];
		result = macro result;
		initVarNames = [];
		indexTracking = false;
		complete = false;
	}

	public function setCoreIterated(e: Expr) {
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

	public function clearResult() {
		init = macro @:mergeBlock {};
		for(l in loops) l.clearResult();
		result = macro @:mergeBlock {};
	}

	public function enableIndexTracking() {
		indexTracking = true;
	}

	public function build() {
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

	public function callModifier(name: String, e: Array<Expr>) {
		if(complete) {
			throw 'Cannot call $name on completed for-loop.';
		}
		switch(name) {
			case "map": if(e.length == 1) map(e[0]);
			case "filter": if(e.length == 1) filter(e[0]);
			case "forEach": if(e.length == 1) forEach(e[0]);
			case "forEachThen": if(e.length == 1) forEachThen(e[0]);

			case "size": if(e.length == 0) size();
			case "count": if(e.length == 1) { count(e[0]); } else if(e.length == 0) { count(); };
			case "isEmpty": if(e.length == 0) isEmpty();
			case "find": if(e.length == 1) find(e[0]);
			case "indexOf": if(e.length == 1) indexOf(e[0]);

			case "asList": if(e.length == 0) asList();
			case "asVector": if(e.length == 0) asVector();
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
