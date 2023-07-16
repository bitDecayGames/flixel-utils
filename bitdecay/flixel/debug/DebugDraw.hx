package bitdecay.flixel.debug;

import flixel.math.FlxRect;
import openfl.display.Graphics;
import flixel.util.FlxColor;
import openfl.display.BitmapData;
import bitdecay.flixel.debug.DebuggerWindow;
import flixel.system.ui.FlxSystemButton;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.math.FlxPoint;
import flixel.FlxBasic;

class DebugDraw extends FlxBasic {
	public static var ME(default, null):DebugDraw;
	public static var enabled(default, set) = true;

	static var icon_data = [
		[0, 0, 0, .5, 1, 1, 1, .5, 0, 0 ,0],
		[0, .5, 1, 1, .5, 0, .5, 1, 1, .5, 0],
		[1, 1, .5, 0, 0, 0, 0, 0, .5, 1, 1],
		[0, .5, 1, 1, .5, 0, .5, 1, 1, .5, 0],
		[0, 0, 0, .5, 1, 1, 1, .5, 0, 0 ,0],
		[1, 1, .5, 0, 0, 0, 0, 0, .5, 1, 1],
		[0, .5, 1, 1, .5, 0, .5, 1, 1, .5, 0],
		[0, 0, 0, .5, 1, 1, 1, .5, 0, 0 ,0],
		[1, 1, .5, 0, 0, 0, 0, 0, .5, 1, 1],
		[0, .5, 1, 1, .5, 0, .5, 1, 1, .5, 0],
		[0, 0, 0, .5, 1, 1, 1, .5, 0, 0 ,0]];

	// TODO: Can we draw this to a separate intermediate graphic rather than
	// relying on a camera for debug drawing
	public static var layer_enabled:Map<String, Bool> = [];
	private static var defaultLayer = "";

	static var draw_debug_button:FlxSystemButton;
	static var debug_window:DebuggerWindow;

	private static var registeredConsole = false;

	/**
	 * Initializes the debug drawer. Layers typically should be a list of enums provided by `Type.allEnums(<enum class>)`
	 * and will be used to initialize the layers as well as the buttons in the debug layer window
	**/
	public static function init(layers:Array<Dynamic> = null, force:Bool = false) {
		if (force && ME != null) {
			FlxG.plugins.remove(ME);
			ME.destroy();
			ME = null;

			layers = [];
		}

		if (layers == null || layers.length == 0) {
			defaultLayer = "ALL";
			layer_enabled[defaultLayer] = true;
		} else {
			defaultLayer = layers[0];
			for (l in layers) {
				layer_enabled[l] = true;
			}
		}

		if (ME == null) {
			#if FLX_DEBUG
			FlxG.plugins.add(ME = new DebugDraw());
			#end
		}

		#if FLX_DEBUG
		if (!registeredConsole) {
			FlxG.console.registerFunction("debugdraw", function() {
				enabled = !enabled;
				FlxG.log.notice('DebugDraw enabled: $enabled');
			});
		}

		if (draw_debug_button == null)
		{
			var icon = new BitmapData(11, 11, true, FlxColor.TRANSPARENT);
			for (y in 0...icon_data.length) {
				for (x in 0...icon_data[y].length) {
					if (icon_data[y][x] > 0) {
						icon.setPixel32(x, y, FlxColor.fromRGBFloat(1, 1, 1, icon_data[y][x]));
					}
				}
			}

			debug_window = new DebuggerWindow(icon);
			FlxG.game.debugger.addWindow(debug_window);

			draw_debug_button = FlxG.debugger.addButton(RIGHT, icon, () -> enabled = !enabled, true, true);
			draw_debug_button.toggled = !FlxG.debugger.drawDebug;
		}
		enabled = FlxG.debugger.drawDebug;
		#end
	}

	#if FLX_DEBUG
	public var lastCallCount(default, null):Int = 0;

	private var calls:Array<()->Void> = [];
	private var tmpPoint = FlxPoint.get();
	private var tmpPoint2 = FlxPoint.get();

	private var tmpRect = FlxRect.get();
	private var tmpRect2 = FlxRect.get();

	public function drawWorldRect(?cam:FlxCamera, x:Float, y:Float, width:Float, height:Float, layer:Dynamic = null, color:Int = 0xFF00FF) {
		if (layer == null) {
			layer = defaultLayer;
		}

		if (!enabled || !layer_enabled[layer]) {
			return;
		}

		calls.push(() -> {
			var renderCam = cam;

			if (renderCam == null) {
				renderCam = FlxG.camera;
			}

			// TODO: This doesn't take any scroll factor into account. We'd need a better way to pass this in
			tmpRect.set(x - renderCam.scroll.x, y - renderCam.scroll.y, width, height);
			renderCam.getViewMarginRect(tmpRect2);
			if (!tmpRect.overlaps(tmpRect2)) {
				return;
			}

			var gfx = renderCam.debugLayer.graphics;
			gfx.lineStyle(1, color, 0.8);
			gfx.drawRect(tmpRect.x, tmpRect.y, tmpRect.width, tmpRect.height);
		});
	}

	public function drawCameraRect(?cam:FlxCamera, x:Float, y:Float, width:Float, height:Float, layer:Dynamic = null, color:Int = 0xFF00FF) {
		if (layer == null) {
			layer = defaultLayer;
		}

		if (!enabled || !layer_enabled[layer]) {
			return;
		}

		calls.push(() -> {
			var renderCam = cam;

			if (renderCam == null) {
				renderCam = FlxG.camera;
			}

			tmpRect.set(x, y, width, height);
			renderCam.getViewMarginRect(tmpRect2);
			if (!tmpRect.overlaps(tmpRect2)) {
				return;
			}

			var gfx = renderCam.debugLayer.graphics;
			gfx.lineStyle(1, color, 0.8);
			gfx.drawRect(x, y, width, height);
		});
	}

	private static function lineRectOverlap(p0:FlxPoint, p1:FlxPoint, rect:FlxRect):Bool {
		// Routine adapted from aek's post in this thread: https://www.lexaloffle.com/bbs/?tid=39127
		var testL = (rect.left - p0.x) / (p1.x - p0.x);
		var testR = (rect.right - p0.x) / (p1.x - p0.x);
		var testT = (rect.top - p0.y) / (p1.y - p0.y);
		var testB = (rect.bottom - p0.y) / (p1.y - p0.y);
		return Math.max(0, Math.max(Math.min(testL, testR), Math.min(testT, testB))) <
		Math.min(1, Math.min(Math.max(testL, testR), Math.max(testT, testB)));
	}

	public function drawWorldLine(?cam:FlxCamera, startX:Float, startY:Float, endX:Float, endY:Float, layer:Dynamic = null, color:Int = 0xFF00FF) {
		if (layer == null) {
			layer = defaultLayer;
		}

		if (!enabled || !layer_enabled[layer]) {
			return;
		}

		calls.push(() -> {
			var renderCam = cam;

			if (renderCam == null) {
				renderCam = FlxG.camera;
			}
			// TODO: This doesn't take any scroll factor into account. We'd need a better way to pass this in
			renderCam.getViewMarginRect(tmpRect);
			tmpPoint.set(startX, startY).subtract(renderCam.scroll.x, renderCam.scroll.y);
			tmpPoint2.set(endX, endY).subtract(renderCam.scroll.x, renderCam.scroll.y);
			if (!lineRectOverlap(tmpPoint, tmpPoint2, tmpRect)) {
				return;
			}

			var gfx = renderCam.debugLayer.graphics;
			gfx.lineStyle(1, color, 0.8);
			gfx.moveTo(tmpPoint.x, tmpPoint.y);
			gfx.lineTo(tmpPoint2.x, tmpPoint2.y);
		});
	}

	public function drawCameraLine(?cam:FlxCamera, startX:Float, startY:Float, endX:Float, endY:Float, layer:Dynamic = null, color:Int = 0xFF00FF) {
		if (layer == null) {
			layer = defaultLayer;
		}

		if (!enabled || !layer_enabled[layer]) {
			return;
		}

		calls.push(() -> {
			var renderCam = cam;

			if (renderCam == null) {
				renderCam = FlxG.camera;
			}

			renderCam.getViewMarginRect(tmpRect);
			tmpPoint.set(startX, startY);
			tmpPoint2.set(endX, endY);
			if (!lineRectOverlap(tmpPoint, tmpPoint2, tmpRect2)) {
				return;
			}

			var gfx = renderCam.debugLayer.graphics;
			gfx.lineStyle(1, color, 0.8);
			gfx.moveTo(startX, startY);
			gfx.lineTo(endX, endY);
		});
	}

	public function drawWorldCircle(?cam:FlxCamera, x:Float, y:Float, radius:Float, layer:Dynamic = null, color:Int = 0xFF00FF) {
		if (layer == null) {
			layer = defaultLayer;
		}

		if (!enabled || !layer_enabled[layer]) {
			return;
		}

		calls.push(() -> {
			var renderCam = cam;

			if (renderCam == null) {
				renderCam = FlxG.camera;
			}

			tmpPoint.set(x, y).subtract(renderCam.scroll.x, renderCam.scroll.y);
			renderCam.getViewMarginRect(tmpRect);
			getCenterPoint(tmpRect, tmpPoint2);
			if (Math.abs(tmpPoint.x - tmpPoint2.x) > renderCam.viewWidth/2 + radius ||
				Math.abs(tmpPoint.y - tmpPoint2.y) > renderCam.viewHeight/2 + radius) {
				return;
			}

			var gfx = renderCam.debugLayer.graphics;
			gfx.lineStyle(1, color, 0.8);
			gfx.drawCircle(tmpPoint.x, tmpPoint.y, radius);
		});
	}

	public function drawCameraCircle(?cam:FlxCamera, x:Float, y:Float, radius:Float, layer:Dynamic = null, color:Int = 0xFF00FF) {
		if (layer == null) {
			layer = defaultLayer;
		}

		if (!enabled || !layer_enabled[layer]) {
			return;
		}

		calls.push(() -> {
			var renderCam = cam;

			if (renderCam == null) {
				renderCam = FlxG.camera;
			}

			tmpPoint.set(x, y);
			renderCam.getViewMarginRect(tmpRect);
			getCenterPoint(tmpRect, tmpPoint2);
			if (Math.abs(tmpPoint.x - tmpPoint2.x) > renderCam.viewWidth/2 + radius ||
				Math.abs(tmpPoint.y - tmpPoint2.y) > renderCam.viewHeight/2 + radius) {
				return;
			}

			var gfx = renderCam.debugLayer.graphics;
			gfx.lineStyle(1, color, 0.8);
			gfx.drawCircle(tmpPoint.x, tmpPoint.y, radius);
		});
	}

	private static function getCenterPoint(rect:FlxRect, ?point:FlxPoint):FlxPoint {
		if (point == null) {
			point = FlxPoint.get();
		}

		point.set((rect.right - rect.left) / 2, (rect.bottom - rect.top) / 2);
		return point;
	}

	#else
	// all no-ops when not in debug. Inline to save function call if compiler doesn't optimize it out
	public inline function drawWorldRect(?cam:FlxCamera, x:Float, y:Float, width:Float, height:Float, layer:Dynamic = null, color:Int = 0xFF00FF) {}
	public inline function drawCameraRect(?cam:FlxCamera, x:Float, y:Float, width:Float, height:Float, layer:Dynamic = null, color:Int = 0xFF00FF) {}
	public inline function drawWorldLine(?cam:FlxCamera, startX:Float, startY:Float, endX:Float, endY:Float, layer:Dynamic = null, color:Int = 0xFF00FF) {}
	public inline function drawCameraLine(?cam:FlxCamera, startX:Float, startY:Float, endX:Float, endY:Float, layer:Dynamic = null, color:Int = 0xFF00FF) {}
	public inline function drawWorldCircle(?cam:FlxCamera, x:Float, y:Float, radius:Float, layer:Dynamic = null, color:Int = 0xFF00FF) {}
	public inline function drawCameraCircle(?cam:FlxCamera, x:Float, y:Float, radius:Float, layer:Dynamic = null, color:Int = 0xFF00FF) {}
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

		lastCallCount = calls.length;
		if (calls.length == 0) {
			return;
		}

		for (drawCall in calls) {
			drawCall();
		}
		calls = [];
		#end
	}

	static function set_enabled(value:Bool) {
		#if FLX_DEBUG
		if (draw_debug_button != null) draw_debug_button.toggled = !value;

		DebugDraw.enabled = value;
		debug_window.visible = value;
		#end
		return enabled = value;
	}
}