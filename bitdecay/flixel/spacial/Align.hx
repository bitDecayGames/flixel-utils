package bitdecay.flixel.spacial;

import flixel.FlxSprite;
import bitdecay.flixel.system.QuickLog;
import flixel.util.FlxDirectionFlags;
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

	/**
	 * Aligns `a` to `b` on the provided edges
	**/
	public static function edge(a:FlxSprite, b:FlxSprite, edges:FlxDirectionFlags, feature:Feature=HITBOX) {
		if (edges.has(LEFT.with(RIGHT)) || edges.has(UP.with(DOWN))) {
			QuickLog.error('cannot align object edges on opposite sides simultaneously');
			return;
		}

		if (edges == NONE) {
			QuickLog.notice('attempting to align on no edges');
			return;
		}

		if (edges.has(UP)) {
			a.y = b.y;
		} else if (edges.has(DOWN)) {
			a.y = b.y + b.height - a.height;
		}
		
		if (edges.has(LEFT)) {
			a.x = b.x - b.offset.x + a.offset.x;
		} else if (edges.has(RIGHT)) {
			a.x = b.x + b.width - b.offset.x - a.width + a.offset.x;
		}

		if (feature == HITBOX_WITH_OFFSET) {
			if (edges.hasAny(UP.with(DOWN))) {
				a.y = a.y - b.offset.y + a.offset.y;
			}

			if (edges.hasAny(LEFT.with(RIGHT))) {
				a.x = a.x - b.offset.x + a.offset.x;
			}
		}
	}

	/**
	 * Aligns `a` to butt up against `b` on the provided side
	 *
	 * @param side    The side of `b` to move `a` to butt up against
	 * @param spacing Optional spacing offset if a gap between `a` and `b` is desired
	**/
	public static function stack(a:FlxObject, b:FlxObject, side:FlxDirectionFlags, spacing:Float = 0) {
		switch(side) {
			case UP:
				a.y = b.y - a.height - spacing;
			case DOWN:
				a.y = b.y + b.height + spacing;
			case LEFT:
				a.x = b.x - a.width - spacing;
			case RIGHT:
				a.x = b.x + b.height + spacing;
			default:
		}
	}
}

enum Feature {
	HITBOX;
	HITBOX_WITH_OFFSET;
}
