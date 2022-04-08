package;

using MagicArrayTools;

function assert(b: Bool, ?pos: haxe.PosInfos) {
	if(!b) {
		throw "assert failed at " + pos.fileName + ":" + pos.lineNumber;
	}
}

function assertEquals<T>(a1: Array<T>, a2: Array<T>, ?pos: haxe.PosInfos) {
	var result = a1.length == a2.length;
	if(result) {
		for(i in 0...a1.length) {
			if(a1[i] != a2[i]) {
				result = false;
				break;
			}
		}
	}
	assert(result, pos);
}

function main() {
	trace("Testing [Magic Array Tools]");

	/**********************************************
	 * map
	 **********************************************/
	{
		final arr = [1, 2, 3, 4, 5];

		assertEquals(arr.map(_), arr);
		assertEquals(arr.map(i -> i), arr);
		assertEquals(arr.map(function(i) { return i; }), arr);

		final arrStr = ["1", "2", "3", "4", "5"];

		assertEquals(arr.map("" + _), arrStr);
		assertEquals(arr.map((i:Int) -> "" + i), arrStr);
		assertEquals(arr.map(function(i:Int) { return "" + i; }), arrStr);
	}

	/**********************************************
	 * filter
	 **********************************************/
	{
		final arr = [1, 2, 3, 4, 5];

		assertEquals(arr.filter((true)), arr);
		assertEquals(arr.filter(i -> true), arr);

		assertEquals(arr.filter((false)), []);
		assertEquals(arr.filter(i -> false), []);

		final arr2 = [3, 4, 5];

		assertEquals(arr.filter(_ >= 3), arr2);
		assertEquals(arr.filter(i -> i >= 3), arr2);

		final arr3 = ["1"];

		assertEquals(arr.filter(_ == 1).map("" + _), arr3);
		assertEquals(arr.filter(i -> i == 1).map((i:Int) -> "" + i), arr3);
		assertEquals(arr.map("" + _).filter(_ == "1"), arr3);
		assertEquals(arr.map((i:Int) -> "" + i).filter(i -> i == "1"), arr3);
	}

	// ---

	trace("[Magic Array Tools] Test Successful!");
}