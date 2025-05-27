package bitdecay.flixel.collision;

import flixel.math.FlxRect;
import flixel.math.FlxPoint;

class GeometryUtils {
    public static function rectIntersectsLine(rect:FlxRect, p1:FlxPoint, p2:FlxPoint):Bool {
        // Step 1: check if either endpoint is inside the rectangle
        if (rect.containsPoint(p1) || rect.containsPoint(p2))
            return true;

        // Step 2: define rectangle corners
        var topLeft = FlxPoint.get(rect.left, rect.top);
        var topRight = FlxPoint.get(rect.right, rect.top);
        var bottomLeft = FlxPoint.get(rect.left, rect.bottom);
        var bottomRight = FlxPoint.get(rect.right, rect.bottom);

        // Step 3: check intersection with each edge of the rect
        if (segmentsIntersect(p1, p2, topLeft, topRight)) return true; // top
        if (segmentsIntersect(p1, p2, topRight, bottomRight)) return true; // right
        if (segmentsIntersect(p1, p2, bottomRight, bottomLeft)) return true; // bottom
        if (segmentsIntersect(p1, p2, bottomLeft, topLeft)) return true; // left

        return false;
    }

    // Helper to check if two line segments intersect
    public static function segmentsIntersect(p1:FlxPoint, p2:FlxPoint, q1:FlxPoint, q2:FlxPoint):Bool {
        var d = (p2.x - p1.x) * (q2.y - q1.y) - (p2.y - p1.y) * (q2.x - q1.x);
        if (d == 0) return false; // parallel

        var u = ((q1.x - p1.x) * (q2.y - q1.y) - (q1.y - p1.y) * (q2.x - q1.x)) / d;
        var v = ((q1.x - p1.x) * (p2.y - p1.y) - (q1.y - p1.y) * (p2.x - p1.x)) / d;

        return u >= 0 && u <= 1 && v >= 0 && v <= 1;
    }
}