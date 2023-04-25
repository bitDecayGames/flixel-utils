package bitdecay.flixel.debug;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.math.FlxPoint;
import flixel.FlxBasic;

class DebugDraw extends FlxBasic {
	public static var ME(get, null):DebugDraw;
	public static var enabled = true;

	static function get_ME():DebugDraw {
		if (ME == null) {
			ME = new DebugDraw();
			#if FLX_DEBUG
			FlxG.plugins.add(ME);

			FlxG.console.registerFunction("debugdraw", function() {
				enabled = !enabled;
				FlxG.log.notice('DebugDraw enabled: $enabled');
			});
			#else
			FlxG.log.error("DebugDraw called without debug flag enabled");
			#end
		}

		return ME;
	}

	#if FLX_DEBUG
	private var calls:Array<()->Void> = [];
	private var tmpPoint = FlxPoint.get();
	private var tmpPoint2 = FlxPoint.get();
	private var tmpPoint3 = FlxPoint.get();
	private var tmpPoint4 = FlxPoint.get();

	public function drawWorldRect(?cam:FlxCamera, x:Float, y:Float, width:Float, height:Float, color:Int = 0xFF00FF) {
		if (!enabled) {
			return;
		}

		calls.push(() -> {
			var renderCam = cam;

			if (renderCam == null) {
				renderCam = FlxG.camera;
			}

			// TODO: This doesn't take any scroll factor into account. We'd need a better way to pass this in
			tmpPoint.set(x, y).subtract(renderCam.scroll.x, renderCam.scroll.y);
			tmpPoint2.set(x + width, y + height).subtract(renderCam.scroll.x, renderCam.scroll.y);
			tmpPoint3.set(x + width, y).subtract(renderCam.scroll.x, renderCam.scroll.y);
			tmpPoint4.set(x, y + height).subtract(renderCam.scroll.x, renderCam.scroll.y);
			if (!(renderCam.containsPoint(tmpPoint) ||
				renderCam.containsPoint(tmpPoint2) ||
				renderCam.containsPoint(tmpPoint3) ||
				renderCam.containsPoint(tmpPoint4))) {
					// if we don't contain one point on the rectangle, then don't draw it
					return;
			}

			var gfx = renderCam.debugLayer.graphics;
			gfx.lineStyle(1, color, 0.8);
			gfx.drawRect(tmpPoint.x, tmpPoint.y, width, height);
		});
	}

	public function drawCameraRect(?cam:FlxCamera, x:Float, y:Float, width:Float, height:Float, color:Int = 0xFF00FF) {
		if (!enabled) {
			return;
		}

		calls.push(() -> {
			var renderCam = cam;

			if (renderCam == null) {
				renderCam = FlxG.camera;
			}

			tmpPoint.set(x, y);
			tmpPoint2.set(x + width, y + height);
			tmpPoint3.set(x + width, y);
			tmpPoint4.set(x, y + height);
			if (!(renderCam.containsPoint(tmpPoint) ||
				renderCam.containsPoint(tmpPoint2) ||
				renderCam.containsPoint(tmpPoint3) ||
				renderCam.containsPoint(tmpPoint4))) {
					// if we don't contain one point on the rectangle, then don't draw it
					return;
			}

			var gfx = renderCam.debugLayer.graphics;
			gfx.lineStyle(1, color, 0.8);
			gfx.drawRect(x, y, width, height);
		});
	}

	public function drawWorldLine(?cam:FlxCamera, startX:Float, startY:Float, endX:Float, endY:Float, color:Int = 0xFF00FF) {
		if (!enabled) {
			return;
		}

		calls.push(() -> {
			var renderCam = cam;

			if (renderCam == null) {
				renderCam = FlxG.camera;
			}
			// TODO: This doesn't take any scroll factor into account. We'd need a better way to pass this in
			tmpPoint.set(startX, startY).subtract(renderCam.scroll.x, renderCam.scroll.y);
			tmpPoint2.set(endX, endY).subtract(renderCam.scroll.x, renderCam.scroll.y);
			if (!(renderCam.containsPoint(tmpPoint) ||
				renderCam.containsPoint(tmpPoint2))) {
					// if we don't contain one point of the line, then don't draw it
					return;
			}

			var gfx = renderCam.debugLayer.graphics;
			gfx.lineStyle(1, color, 0.8);
			gfx.moveTo(tmpPoint.x, tmpPoint.y);
			gfx.lineTo(tmpPoint2.x, tmpPoint2.y);
		});
	}

	public function drawCameraLine(?cam:FlxCamera, startX:Float, startY:Float, endX:Float, endY:Float, color:Int = 0xFF00FF) {
		if (!enabled) {
			return;
		}

		calls.push(() -> {
			var renderCam = cam;

			if (renderCam == null) {
				renderCam = FlxG.camera;
			}


			tmpPoint.set(startX, startY);
			tmpPoint2.set(endX, endY);
			if (!(renderCam.containsPoint(tmpPoint) ||
				renderCam.containsPoint(tmpPoint2))) {
					// if we don't contain one point of the line, then don't draw it
					return;
			}

			var gfx = renderCam.debugLayer.graphics;
			gfx.lineStyle(1, color, 0.8);
			gfx.moveTo(startX, startY);
			gfx.lineTo(endX, endY);
		});
	}
	#else
	// all no-ops when not in debug. Inline to save function call if compiler doesn't optimize it out
	public inline function drawWorldRect(?cam:FlxCamera, x:Float, y:Float, width:Float, height:Float, color:Int = 0xFF00FF) {}
	public inline function drawCameraRect(?cam:FlxCamera, x:Float, y:Float, width:Float, height:Float, color:Int = 0xFF00FF) {}
	public inline function drawWorldLine(?cam:FlxCamera, startX:Float, startY:Float, endX:Float, endY:Float, color:Int = 0xFF00FF) {}
	public inline function drawCameraLine(?cam:FlxCamera, startX:Float, startY:Float, endX:Float, endY:Float, color:Int = 0xFF00FF) {}
	#end

	override function update(elapsed:Float) {
		super.update(elapsed);
	}

	override function draw() {
		super.draw();

		#if FLX_DEBUG
		if (!enabled) {
			return;
		}

		FlxG.watch.addQuick('debug draw calls: ', calls.length);
		if (calls.length == 0) {
			return;
		}

		for (drawCall in calls) {
			drawCall();
		}
		calls = [];
		#end
	}
}