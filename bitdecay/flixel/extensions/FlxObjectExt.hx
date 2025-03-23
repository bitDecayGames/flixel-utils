package bitdecay.flixel.extensions;

import flixel.math.FlxRect;
import flixel.FlxObject;

/**
 * General helpers for adding convenience functions onto FlxObject
 */
class FlxObjectExt {
	/**
	 * Sets the FlxObject position such that the midpoint is at (x,y)
	 *
	 * @param   x   The new x position for midpoint
	 * @param   y   The new x position for midpoint
	 */
	static public function setPositionMidpoint(o:FlxObject, x:Float, y:Float) {
		o.setPosition(x - o.width / 2, y - o.height / 2);
	}

	/**
	 * Computes and returns the overlapping rectangle between `a` and `b`
	 *
	 * @param   a        The first object
	 * @param   b        The second object
	 * @param   result   The rectangle to store the result in, if provided
	 */
	public static function getOverlapRect(a:FlxObject, b:FlxObject, ?result:FlxRect):FlxRect {
		var aRect = FlxRect.get(a.x, a.y, a.width, a.height);
		var bRect = FlxRect.get(b.x, b.y, b.width, b.height);

		if (result == null) {
			result = FlxRect.get();
		}

		aRect.intersection(bRect, result);

		aRect.put();
		bRect.put();

		return result;
	}
}
