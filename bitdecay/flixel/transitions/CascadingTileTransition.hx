package bitdecay.flixel.transitions;

import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;

import bitdecay.flixel.collision.GeometryUtils;
import bitdecay.flixel.debug.tools.draw.DebugDraw;
import bitdecay.flixel.debug.DebugSuite;

using bitdecay.flixel.extensions.FlxPointExt;


/**
 * Work in Progress
 * Still need to figure out tween in vs tween out
**/
class CascadingTileTransition extends FlxSubState {
	var dir:FlxPoint;
    var normal:FlxPoint;
	var lineStart = FlxPoint.get();
	var lineEnd = FlxPoint.get();
	var sweepVector = FlxPoint.get();
	var tmp = FlxPoint.get();
	var sweepStart = FlxPoint.get();
	var sweepEnd = FlxPoint.get();
    var gridWidth:Int;
    var gridHeight:Int;
	var tileWidth:Int;
	var tileHeight:Int;

	var lastSweepStart:Float = 0.0;

	var time:Float;
    var duration:Float;

    var cbIn:(x:Float, y:Float) -> FlxSprite;
    var cbOut:(s:FlxSprite) -> Void;
	public var modeIn = true;

	var tileBoxes = new FlxTypedGroup<FlxObject>();
	var tilePairing = new Map<FlxObject, FlxSprite>();

    var visited = new Map<Int, Bool>();

	var sweepStartPoint:Float;
    var sweepLength:Float;
	var sweepDir:Int;
	var progress = 0.0;
	var unsweptProgress = 0.0;
	var maxProgressJump = 0.0;

	public function new(direction:FlxPoint, tileWidth:Int, tileHeight:Int, duration:Float, cbIn:(x:Float, y:Float) -> FlxSprite, cbOut:(s:FlxSprite) -> Void) {
		super();

		this.tileWidth = tileWidth;
		this.tileHeight = tileHeight;
        this.dir = direction.copyTo().normalize();
        this.normal = FlxPoint.get(-dir.y, dir.x).normalize(); // perpendicular
        this.gridWidth = Math.ceil(camera.width / tileWidth);
        this.gridHeight = Math.ceil(camera.height / tileHeight);
        this.duration = duration;
        this.cbIn = cbIn;
        this.cbOut = cbOut;

		// 1. find our starting corner (which becomes our line start point)
		// 2. find our line end point (follow normal to the opposite side of the camera)
		// 3. calculate our sweep distance (point furthest from opposite side of camera, should always be the end point)
		// 4.

		for (i in 0...gridWidth) {
			for (k in 0...gridHeight) {
				var o = new FlxObject(i * tileWidth, k * tileHeight);
				o.setSize(tileWidth, tileHeight);
				o.scrollFactor.set();
				tileBoxes.add(o);
			}
		}

		// step 1
		lineStart.x = dir.x >= 0 ? 0 : gridWidth * tileWidth;
		lineStart.y = dir.y >= 0 ? 0 : gridHeight * tileHeight;

		var endScale = 0.0;
		sweepDir = 1;
		if (Math.abs(dir.x) >= Math.abs(dir.y)) {
			// x-component larger, so sweep horizontally
			if (dir.y != 0) {
				if (lineStart.x == 0) {
					if (lineStart.y == 0 && normal.quadrant() != BOTTOM_LEFT) {
						normal.scale(-1);
					} else if (normal.quadrant() != BOTTOM_LEFT) {
						normal.scale(-1);
					}
				} else {
					if (lineStart.y == 0 && normal.quadrant() != BOTTOM_RIGHT) {
						normal.scale(-1);
					} else if (normal.quadrant() != TOP_RIGHT) {
						normal.scale(-1);
					}
				}
			}
			
			endScale = Math.abs(camera.height / normal.y);
			sweepDir = lineStart.x == 0 ? 1 : -1;
			
		} else {
			// y-component larger, so sweep vertically
			if (dir.x != 0) {
				if (lineStart.y == 0) {
					if (lineStart.x == 0 && normal.quadrant() != TOP_RIGHT) {
						normal.scale(-1);
					} else if (normal.quadrant() != TOP_LEFT) {
						normal.scale(-1);
					}
				} else {
					if (lineStart.x == 0 && normal.quadrant() != BOTTOM_RIGHT) {
						normal.scale(-1);
					} else if (normal.quadrant() != BOTTOM_RIGHT) {
						normal.scale(-1);
					}
				}
			}

			endScale = Math.abs(camera.width / normal.x);
			sweepDir = lineStart.y == 0 ? 1 : -1;
		}

		lineEnd.set(lineStart.x + normal.x * endScale, lineStart.y + normal.y * endScale);

		if (Math.abs(dir.x) >= Math.abs(dir.y)) {
			sweepLength = camera.width + Math.abs(lineStart.x - lineEnd.x);
			sweepVector.set(sweepLength * sweepDir, 0);
		} else {
			sweepLength = camera.height + Math.abs(lineStart.y - lineEnd.y);
			sweepVector.set(0, sweepLength * sweepDir);
		}
		progress = 0;

		var maxPixelJump = Math.min(tileHeight / 2, tileWidth / 2);
		maxProgressJump = 1 / (sweepLength / maxPixelJump);

		add(tileBoxes);
    }

	override function create() {
		super.create();
	}

	var tmpRect = FlxRect.get();
	override function update(delta:Float) {
		super.update(delta);

		if (progress >= 1) {
			return;
		}

		time += delta;

		// TODO:
		// Progress in fast transitions could causes us to move the line too far and not interact
		// with certain cells. We want to allow this to loop while incrementing progress a maximum
		// amount each time so we don't skip over anything.
		var lastProgress = progress;
		progress = Math.min(1, time / duration);
		unsweptProgress += progress - lastProgress;
		var interimProg = lastProgress;
		while(unsweptProgress > maxProgressJump) {
			interimProg += maxProgressJump;
			unsweptProgress -= maxProgressJump;
			
			sweepAt(interimProg);
		}

		sweepAt(progress);
		

		DebugSuite.get(DebugDraw).drawCameraLine(sweepStart.x, sweepStart.y, sweepEnd.x, sweepEnd.y);
	}

	function sweepAt(progress:Float) {
		tmp.copyFrom(sweepVector).scale(progress);
		sweepStart.copyFrom(lineStart).add(tmp);
		sweepEnd.copyFrom(lineEnd).add(tmp);

			
		tileBoxes.forEachAlive((o) -> {
			if (GeometryUtils.rectIntersectsLine(o.getRotatedBounds(tmpRect), sweepStart, sweepEnd)) {
				o.kill();
				if (modeIn) {
					var s = cbIn(o.x, o.y);
					tilePairing.set(o, s);
					add(s);
				} else {
					if (tilePairing.exists(o)) {
						cbOut(tilePairing.get(o));
					}
				}
			}
		});
	}

	public function resetSweep() {
		tileBoxes.forEach((o) -> { o.revive(); });

		time = 0;
		progress = 0;
		unsweptProgress = 0;
	}

	// Cantor's pairing function to give us a unique key for any given x,y pair of ints
	function pairKey(x:Int, y:Int):Int {
		return cast((x + y) * (x + y + 1)) / 2 + y;
	}
}