package bitdecay.flixel.debug.tools.draw;

import flixel.FlxCamera;
import bitdecay.flixel.debug.tools.draw.DebugDrawWindow;

#if FLX_DEBUG
import openfl.display.BitmapData;
import openfl.geom.Matrix;
import openfl.text.TextField;
import openfl.text.TextFormat;

import flixel.FlxG;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.ui.FlxSystemButton;

import bitdecay.flixel.debug.DebugTool;
import bitdecay.flixel.debug.DebugTool.BaseToolData;
#end

class DebugDraw extends DebugTool<DebugDrawWindow> {
	public static var ME(default, null):DebugDraw;

	#if FLX_DEBUG
	static var icon_data = [
		[0, 0, 0, .5, 1, 1, 1, .5, 0, 0, 0],
		[0, .5, 1, 1, .5, 0, .5, 1, 1, .5, 0],
		[1, 1, .5, 0, 0, 0, 0, 0, .5, 1, 1],
		[0, .5, 1, 1, .5, 0, .5, 1, 1, .5, 0],
		[0, 0, 0, .5, 1, 1, 1, .5, 0, 0, 0],
		[1, 1, .5, 0, 0, 0, 0, 0, .5, 1, 1],
		[0, .5, 1, 1, .5, 0, .5, 1, 1, .5, 0],
		[0, 0, 0, .5, 1, 1, 1, .5, 0, 0, 0],
		[1, 1, .5, 0, 0, 0, 0, 0, .5, 1, 1],
		[0, .5, 1, 1, .5, 0, .5, 1, 1, .5, 0],
		[0, 0, 0, .5, 1, 1, 1, .5, 0, 0, 0]
	];

	// TODO: Can we draw this to a separate intermediate graphic rather than
	// relying on a camera for debug drawing
	public static var layer_enabled:Map<String, Bool> = [];
	private static var defaultLayer = "";

	static var draw_debug_button:FlxSystemButton;
	static var debug_window:DebugDrawWindow;

	private static var registeredConsole = false;

	/**
	 * How often to update the stats, in ms. The lower, the more performance-intense!
	 */
	static inline var UPDATE_DELAY:Int = 250;
	var _currentTime:Int;
	var _lastTime:Int = 0;
	var _updateTimer:Int = 0;

	public function new(layers:Array<Dynamic> = null) {
		super('debugDraw', icon_data);

		if (layers == null || layers.length == 0) {
			defaultLayer = "ALL";
			layer_enabled[defaultLayer] = true;
		} else {
			defaultLayer = layers[0];
			for (l in layers) {
				layer_enabled[l] = true;
			}
		}

		window.onLayerToggle.add(updateLayerEnabled);
		window.onCollapseToggle.add(updateCollapsed);
	}

	/**
	 * Initializes the debug drawer. Layers typically should be a list of enums provided by `Type.allEnums(<enum class>)`
	 * and will be used to initialize the layers as well as the buttons in the debug layer window
	**/
	override public function init() {
		super.init();

		#if FLX_DEBUG
		ME = this;

		// draw needs to be done at a specific point in the render pipeline that
		// happens to coincide with plugins, so we use this mechanism
		FlxG.plugins.addPlugin(this);
		window.onUpdate.remove(update);

		if (!registeredConsole) {
			FlxG.console.registerFunction("debugdraw", function() {
				enabled = !enabled;
				FlxG.log.notice('DebugDraw enabled: $enabled');
			});
		}
		#else
		// if we aren't in debug, just set this to the no-op implementation
		ME = new DebugDraw();
		#end
	}

	public var lastCallCount(default, null):Int = 0;

	private var calls:Array<() -> Void> = [];
	private var tmpPoint = FlxPoint.get();
	private var tmpPoint2 = FlxPoint.get();

	private var tmpRect = FlxRect.get();
	private var tmpRect2 = FlxRect.get();

	// Matrix to aid in getting text to render where we want on-screen
	private var textMatrix = new Matrix();
	private var textFormat:TextFormat = null;

	override function makeWindow(icon:BitmapData):DebugDrawWindow {
		return new DebugDrawWindow(icon);
	}

	function updateLayerEnabled(name:String, on:Bool) {
		layer_enabled[name] = on;
		data.layers.set(name, on);
		FlxG.save.flush();
	}

	function updateCollapsed(collapsed:Bool) {
		data.collapsed = collapsed;
		FlxG.save.flush();
	}

	override function loadData():Bool {
		if (!super.loadData()) {
			return false;
		}

		for (key => value in layer_enabled) {
			if (!data.layers.exists(key)) {
				data.layers.set(key, value);
			}

			if (!data.layers.get(key)) {
				layer_enabled[key] = false;
			}
		}
		window.setLayers(layer_enabled);
		window.collapsed = data.collapsed;
		return true;
	}

	override function getDefaults():Dynamic {
		var defaults:DebugDrawData = {};
		defaults.layers = [];
		defaults.collapsed = false;
		return defaults;
	}

	public function setDrawFont(name:String, size:Int) {
		textFormat = new TextFormat(name, size, 0xFFFFFF);
	}

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
			tmpRect.set(x - renderCam.scroll.x, y - renderCam.scroll.y, width, height);
			drawRectInner(renderCam, tmpRect, color);
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
			drawRectInner(renderCam, tmpRect, color);
		});
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
			tmpPoint.set(startX, startY).subtract(renderCam.scroll.x, renderCam.scroll.y);
			tmpPoint2.set(endX, endY).subtract(renderCam.scroll.x, renderCam.scroll.y);
			drawLineInner(renderCam, tmpPoint, tmpPoint2, color);
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

			tmpPoint.set(startX, startY);
			tmpPoint2.set(endX, endY);
			drawLineInner(renderCam, tmpPoint, tmpPoint2, color);
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
			drawCircleInner(renderCam, tmpPoint, radius, color);
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
			drawCircleInner(renderCam, tmpPoint, radius, color);
		});
	}

	public function drawCameraText(?cam:FlxCamera, x:Float, y:Float, text:String, size:Int = 10, layer:Dynamic = null, color:Int = 0xFF00FF) {
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
			drawTextInner(renderCam, tmpPoint, text, size, layer, color);
		});
	}

	public function drawWorldText(?cam:FlxCamera, x:Float, y:Float, text:String, size:Int = 10, layer:Dynamic = null, color:Int = 0xFF00FF) {
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
			drawTextInner(renderCam, tmpPoint, text, size, layer, color);
		});
	}

	public function drawTextInner(renderCam:FlxCamera, p:FlxPoint, text:String, size:Int = 10, layer:Dynamic = null, color:Int = 0xFF00FF) {
		var textField = new TextField();

		if (textFormat == null) {
			textFormat = new TextFormat(size, color);
		}

		textField.text = text;
		textField.embedFonts = true;
		textFormat.size = size;
		textFormat.color = color;

		// Set textFormat _after_ setting the text into the field to avoid weird defaults getting set
		// due to an empty string
		textField.setTextFormat(textFormat);
		textField.textColor = color;

		var bitmapData = new BitmapData(Std.int(textField.width), Std.int(textField.height), true, 0x00000000);
		bitmapData.draw(textField);

		var gfx = renderCam.debugLayer.graphics;
		textMatrix.identity(); // Reset our matrix
		textMatrix.translate(p.x, p.y);
		gfx.beginBitmapFill(bitmapData, textMatrix);
		gfx.drawRect(p.x, p.y, bitmapData.width, bitmapData.height);
		gfx.endFill();
	}

	private function drawRectInner(renderCam:FlxCamera, rect:FlxRect, color:Int) {
		renderCam.getViewMarginRect(tmpRect2);
		if (!tmpRect.overlaps(tmpRect2)) {
			return;
		}

		var gfx = renderCam.debugLayer.graphics;
		gfx.lineStyle(1, color, 0.8);
		gfx.drawRect(rect.x, rect.y, rect.width, rect.height);
	}

	private function drawLineInner(renderCam:FlxCamera, start:FlxPoint, end:FlxPoint, color:Int) {
		renderCam.getViewMarginRect(tmpRect);
		if (!lineRectOverlap(tmpPoint, tmpPoint2, tmpRect)) {
			return;
		}

		var gfx = renderCam.debugLayer.graphics;
		gfx.lineStyle(1, color, 0.8);
		gfx.moveTo(start.x, start.y);
		gfx.lineTo(end.x, end.y);
	}

	private function drawCircleInner(renderCam:FlxCamera, center:FlxPoint, radius:Float, color:Int) {
		renderCam.getViewMarginRect(tmpRect);
		getCenterPoint(tmpRect, tmpPoint2);
		if (Math.abs(tmpPoint.x - tmpPoint2.x) > renderCam.viewWidth / 2 + radius
			|| Math.abs(tmpPoint.y - tmpPoint2.y) > renderCam.viewHeight / 2 + radius) {
			return;
		}

		var gfx = renderCam.debugLayer.graphics;
		gfx.lineStyle(1, color, 0.8);
		gfx.drawCircle(tmpPoint.x, tmpPoint.y, radius);
	}

	private static function lineRectOverlap(p0:FlxPoint, p1:FlxPoint, rect:FlxRect):Bool {
		// Routine adapted from aek's post in this thread: https://www.lexaloffle.com/bbs/?tid=39127
		var testL = (rect.left - p0.x) / (p1.x - p0.x);
		var testR = (rect.right - p0.x) / (p1.x - p0.x);
		var testT = (rect.top - p0.y) / (p1.y - p0.y);
		var testB = (rect.bottom - p0.y) / (p1.y - p0.y);
		return Math.max(0, Math.max(Math.min(testL, testR), Math.min(testT, testB))) < Math.min(1, Math.min(Math.max(testL, testR), Math.max(testT, testB)));
	}

	private static function getCenterPoint(rect:FlxRect, ?point:FlxPoint):FlxPoint {
		if (point == null) {
			point = FlxPoint.get();
		}

		point.set((rect.right - rect.left) / 2, (rect.bottom - rect.top) / 2);
		return point;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		var time:Int = _currentTime = FlxG.game.ticks;
		var elapsed:Int = time - _lastTime;

		if (elapsed > UPDATE_DELAY) {
			elapsed = UPDATE_DELAY;
		}
		_lastTime = time;

		_updateTimer += elapsed;

		if (_updateTimer > UPDATE_DELAY) {
			window.updateDrawCallCount(lastCallCount);
		}
	}

	override function draw() {
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
	}
	#else
	// all no-ops when not in debug. Inline to save function call if compiler doesn't optimize it out

	public function new(layers:Array<Dynamic> = null) {
		super();
	}
	
	public inline function setDrawFont(name:String, size:Int) {}
	
	public inline function drawWorldRect(?cam:FlxCamera, x:Float, y:Float, width:Float, height:Float, layer:Dynamic = null, color:Int = 0xFF00FF) {}
	public inline function drawCameraRect(?cam:FlxCamera, x:Float, y:Float, width:Float, height:Float, layer:Dynamic = null, color:Int = 0xFF00FF) {}

	public inline function drawWorldLine(?cam:FlxCamera, startX:Float, startY:Float, endX:Float, endY:Float, layer:Dynamic = null, color:Int = 0xFF00FF) {}
	public inline function drawCameraLine(?cam:FlxCamera, startX:Float, startY:Float, endX:Float, endY:Float, layer:Dynamic = null, color:Int = 0xFF00FF) {}

	public inline function drawWorldCircle(?cam:FlxCamera, x:Float, y:Float, radius:Float, layer:Dynamic = null, color:Int = 0xFF00FF) {}
	public inline function drawCameraCircle(?cam:FlxCamera, x:Float, y:Float, radius:Float, layer:Dynamic = null, color:Int = 0xFF00FF) {}
	
	public inline function drawWorldText(?cam:FlxCamera, x:Float, y:Float, text:String, size:Int = 10, layer:Dynamic = null, color:Int = 0xFF00FF) {}
	public inline function drawCameraText(?cam:FlxCamera, x:Float, y:Float, text:String, size:Int = 10, layer:Dynamic = null, color:Int = 0xFF00FF) {}
	#end
}

#if FLX_DEBUG
typedef DebugDrawData = BaseToolData & {
	var ?layers:Map<String, Bool>;
	var ?collapsed:Bool;
}
#end
