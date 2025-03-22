package bitdecay.flixel.spacial;

import flixel.math.FlxPoint;
import flixel.util.FlxAxes;
import flixel.FlxObject;

using bitdecay.flixel.extensions.FlxObjectExt;

class Align {
	private static var pA = FlxPoint.get();
	private static var pB = FlxPoint.get();

	/**
	 * Aligns `a` to `b` on the provided axis/axes.
	**/
	public static function center(a:FlxObject, b:FlxObject, axis:FlxAxes=FlxAxes.XY) {
		a.getMidpoint(pA);
		b.getMidpoint(pB);
		
		switch(axis) {
			case XY:
				a.setPositionMidpoint(pB.x, pB.y);
			case X:
				a.setPositionMidpoint(pB.x, pA.y);
			case Y:
				a.setPositionMidpoint(pA.x, pB.y);
			default:
		}
	
	}
}
