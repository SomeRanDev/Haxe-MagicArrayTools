package;

using MagicArrayTools;

function assert(b: Bool, ?pos: haxe.PosInfos) {
	if(!b) {
		throw "assert failed at " + pos.fileName + ":" + pos.lineNumber;
	}
}

function main() {
	trace("Testing [Magic Array Tools]");

	/**********************************************
	 * ---
	 *
	 * desc
	 **********************************************/
	final arr = [1, 2, 3, 4];
	arr.map(_).map(123).forEachThen(_).map(_);
	//arr.forEach(trace);

	// ---

	trace("[Magic Array Tools] Test Successful!");
}