package bitdecay.flixel.extensions;

import flixel.util.FlxAxes;
import flixel.math.FlxAngle;
import flixel.math.FlxPoint;

class FlxPointExt {
	/**
	 *  returns a new point on the circumference of a circle. Rotation of 0 is pointing to the right
	 *  @param point	center point
	 *  @param angle	angle from center in degrees
	 *  @param radius	radius/distance from center
	 *  @return			FlxPoint
	 */
	public static inline function pointOnCircumference(point:FlxPoint, angle:Float, radius:Float):FlxPoint {
		return FlxPoint.get(point.x + radius * Math.cos(angle * FlxAngle.TO_RAD), point.y + radius * Math.sin(angle * FlxAngle.TO_RAD));
	}

	/**
	* bounds the x or y axes respectively for the given point by length
	* @param point		the point to bound
	* @param length		the max length to limit by 
	* @param axes		the axes to bound, default to both
	**/
	public static inline function bound(point:FlxPoint, length:Float, axes:FlxAxes=XY) {
		if(axes.x){
			if(point.x > length)
				point.x = length;
			else if(point.x < -length){
				point.x = -length;
			}
		}
		if(axes.y){
			if(point.y > length)
				point.y = length;
			else if(point.y < -length){
				point.y = -length;
			}
		}
	}
}
