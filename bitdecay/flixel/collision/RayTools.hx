package bitdecay.flixel.collision;

import flixel.util.FlxCollision;
import flixel.math.FlxRect;
import flixel.util.FlxPool;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxBasic;
import flixel.system.FlxQuadTree;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.math.FlxPoint;

class RayTools {
	// group for us to put rays into for the quad tree calculations
	private static var rayGroup:FlxTypedGroup<Ray> = null;

	// helpers to reduce allocations
	private static var qt:FlxQuadTree = null;
	private static var delta = FlxPoint.get();

	/**
	 * casts a set of rays against the provided objects
	 *
	 * @param rays    the set of rays to cast
	 * @param objects either an object or group of objects to cast against. Same rules as what you'd pass to FlxG.overlap
	 * @param bounds  optional bounds to use for the ray. defaults to FlxG.worldBounds if not provided
	 *
	 * @return        true if any intersections were found, false otherwise
	**/
	public static function castAll(rays:Array<Ray>, objects:FlxBasic, bounds:FlxRect = null):Bool {
		if (bounds == null) {
			bounds = FlxG.worldBounds;
		}
		if (qt == null) {
			qt = FlxQuadTree.recycle(bounds.x, bounds.y, bounds.width, bounds.height);
		} else {
			qt.reset(bounds.x, bounds.y, bounds.width, bounds.height);
		}

		if (rayGroup == null) {
			rayGroup = new FlxTypedGroup();
		}
		rayGroup.clear();
		for (ray in rays) {
			trimToBounds(ray, bounds);
			if (ray.start == null || ray.end == null) {
				// this ray does not intersect our bounds, so don't add it
				continue;
			}
			rayGroup.add(ray);
		}

		var found = false;
		qt.load(rayGroup, objects, (a, b) -> {
			var r:Ray = cast a;
			var newDist = intersectRayWithObject(r, b);
			if (newDist < r.dist) {
				found = true;
				r.obj = b;
				r.dist = newDist;
			}
		});
		qt.execute();

		return found;
	}

	/**
	 * casts a ray from start to end against the provided objects, returning the closest object it intersects with
	 *
	 * @param start   the starting point of the ray
	 * @param end     the ending point of the ray
	 * @param objects either an object or group of objects to cast against. Same rules as what you'd pass to FlxG.overlap
	 * @param bounds  optional bounds to use for the ray. defaults to FlxG.worldBounds if not provided
	 *
	 * @return        the closest object intersected along the ray's path
	**/
	public static function castOne(ray:Ray, objects:FlxBasic, bounds:FlxRect = null):FlxObject {
		castAll([ray], objects, bounds);
		return ray.obj;
	}

	private static function trimToBounds(r:Ray, bounds:FlxRect) {
		r.start = FlxCollision.calcRectEntry(bounds, r.start, r.end, r.start);
		if (r.start == null) {
			return;
		}
		r.end = FlxCollision.calcRectEntry(bounds, r.end, r.start, r.end);
	}

	public static function intersectRayWithObject(ray:Ray, obj:FlxObject):Float {
		var dx = ray.end.x - ray.start.x;
		var dy = ray.end.y - ray.start.y;

		var min = 0.0;
		var max = 1.0;

		var p:Array<Float> = [-dx, dx, -dy, dy];
		var q:Array<Float> = [
			ray.start.x - obj.x,
			obj.x + obj.width - ray.start.x,
			ray.start.y - obj.y,
			obj.y + obj.height - ray.start.y
		];

		for (i in 0...4) {
			if (p[i] == 0) {
				if (q[i] < 0)
					return 1; // Line is parallel and outside
			} else {
				var t = q[i] / p[i];
				if (p[i] < 0) {
					if (t > max)
						return 1;
					if (t > min)
						min = t;
				} else {
					if (t < min)
						return 1;
					if (t < max)
						max = t;
				}
			}
		}

		return min;
	}
}

class Ray extends FlxObject {
	public var start:FlxPoint;
	public var end:FlxPoint;
	public var intersect:FlxPoint;
	public var dist(default, set):Float;
	public var obj:FlxObject = null;

	static var pool:FlxPool<Ray> = new FlxPool(Ray.new.bind());

	public static function get(?start:FlxPoint, ?end:FlxPoint):Ray {
		var ray = pool.get();
		ray.init(start ?? FlxPoint.get(), end ?? FlxPoint.get());
		return ray;
	}

	public static function put(r:Ray) {
		r.clean();
		pool.put(r);
	}

	private function new() {
		super();
	}

	public function init(start:FlxPoint, end:FlxPoint) {
		x = Math.min(start.x, end.x);
		y = Math.min(start.y, end.y);
		width = Math.max(1, Math.abs(end.x - start.x));
		height = Math.max(1, Math.abs(end.y - start.y));

		this.start = start;
		this.end = end;

		if (intersect == null) {
			intersect = FlxPoint.get();
		}

		this.dist = 1.0;
		obj = null;
	}

	private function clean() {
		obj = null;
	}

	function set_dist(value:Float):Float {
		intersect.set(start.x + (end.x - start.x) * value, start.y + (end.y - start.y) * value);
		return dist = value;
	}
}
