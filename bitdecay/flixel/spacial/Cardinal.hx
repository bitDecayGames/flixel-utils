package bitdecay.flixel.spacial;

import flixel.util.FlxDirectionFlags;
import flixel.math.FlxAngle;
import flixel.math.FlxPoint;

/**
 * Cardinal direction handling. Directly usable as their integer value in degrees
**/
enum abstract Cardinal(Int) from Int to Int {
	private static var upZeroAngle = new FlxPoint(0, -1);
	private static inline var halfAngle = 22.5;
	var N = 0;
	var NE = 45;
	var E = 90;
	var SE = 135;
	var S = 180;
	var SW = 225;
	var W = 270;
	var NW = 315;
	var NONE = -1;

	/**
	 * Converts the given cardinal direction to a unit vector
	**/
	public function asVector(?v:FlxPoint):FlxPoint {
		if (v == null) {
			v = FlxPoint.get();
		}
		v.set();

		switch (this) {
			case NW | N | NE:
				v.y = -1;
			case SW | S | SE:
				v.y = 1;
			default:
		}
		switch (this) {
			case NE | E | SE:
				v.x = 1;
			case NW | W | SW:
				v.x = -1;
			default:
		}

		return v.normalize();
	}

	/**
	 * Converts the given cardinal direction to radians
	**/
	public function asRads():Float {
		return this * FlxAngle.TO_RAD;
	}

	/**
	 * Converts the given cardinal the a Flixel facing integer
	**/
	public function asFacing():Int {
		var facing = 0;
		switch (this) {
			case NW | N | NE:
				facing |= FlxDirectionFlags.UP.toInt();
			case SW | S | SE:
				facing |= FlxDirectionFlags.DOWN.toInt();
		}
		switch (this) {
			case NE | E | SE:
				facing |= FlxDirectionFlags.RIGHT.toInt();
			case NW | W | SW:
				facing |= FlxDirectionFlags.LEFT.toInt();
		}
		return facing;
	}

	/**
	 * Converts the given Flixel facing integer to a Cardinal
	**/
	public static function fromFacing(facing:Int):Cardinal {
		if (facing & FlxDirectionFlags.UP.toInt() != 0) {
			if (facing & FlxDirectionFlags.LEFT.toInt() != 0) {
				return NW;
			} else if (facing & FlxDirectionFlags.RIGHT.toInt() != 0) {
				return NE;
			} else {
				return N;
			}
		}

		if (facing & FlxDirectionFlags.DOWN.toInt() != 0) {
			if (facing & FlxDirectionFlags.LEFT.toInt() != 0) {
				return SW;
			} else if (facing & FlxDirectionFlags.RIGHT.toInt() != 0) {
				return SE;
			} else {
				return S;
			}
		}

		if (facing & FlxDirectionFlags.LEFT.toInt() != 0) {
			if (facing & FlxDirectionFlags.UP.toInt() != 0) {
				return NW;
			} else if (facing & FlxDirectionFlags.DOWN.toInt() != 0) {
				return SW;
			} else {
				return W;
			}
		}

		if (facing & FlxDirectionFlags.RIGHT.toInt() != 0) {
			if (facing & FlxDirectionFlags.UP.toInt() != 0) {
				return NE;
			} else if (facing & FlxDirectionFlags.DOWN.toInt() != 0) {
				return SE;
			} else {
				return E;
			}
		}

		return NONE;
	}

	/**
	 * Returns the opposite cardinal (180 degrees away)
	**/
	public function opposite():Cardinal {
		switch(this) {
			case N:
				return S;
			case NE:
				return SW;
			case E:
				return W;
			case SE:
				return NW;
			case S:
				return N;
			case SW:
				return NE;
			case W:
				return E;
			case NW:
				return SE;
			default:
				return NONE;
		}
	}

	/**
	 * Returns true if the cardinal is N or S, false otherwise
	**/
	public function vertical():Bool {
		return this == Cardinal.N || this == Cardinal.S;
	}

	/**
	 * Returns true if the cardinal is E or W, false otherwise
	**/
	public function horizontal():Bool {
		return this == Cardinal.W || this == Cardinal.E;
	}

	/**
	 * Finds the closest cardinal for the given vector
	**/
	public static function closest(vec:FlxPoint, fourDirection:Bool = false):Cardinal {
		// degrees: 0 is straight right, we want it to be straight up
		var angle = vec.degrees + 90;
		while (angle < 0) {
			angle += 360;
		}
		while (angle > 360) {
			angle -= 360;
		}

		if (fourDirection) {
			if (angle < 0 + NE) {
				return N;
			} else if (angle < 0 + SE) {
				return E;
			} else if (angle < 0 + SW) {
				return S;
			} else if (angle < 0 + NW) {
				return W;
			} else {
				return N;
			}
		} else {
			if (angle < N + halfAngle) {
				return N;
			} else if (angle < NE + halfAngle) {
				return NE;
			} else if (angle < E + halfAngle) {
				return E;
			} else if (angle < SE + halfAngle) {
				return SE;
			} else if (angle < S + halfAngle) {
				return S;
			} else if (angle < SW + halfAngle) {
				return SW;
			} else if (angle < W + halfAngle) {
				return W;
			} else if (angle < NW + halfAngle) {
				return NW;
			} else {
				return N;
			}
		}
	}

	/*
	 * Experimental function that turns a cardinal into direction strings for use in animation names and the like
	 */
	public static function asUDLR(c:Cardinal):String {
		switch(c) {
			case N:
				return "up";
			case E:
				return "right";
			case S:
				return "down";
			case W:
				return "left";
			default:
				return "none";
		}
	}
}
