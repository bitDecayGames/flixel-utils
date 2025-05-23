package bitdecay.flixel.debug.tools.btree;

import openfl.display.BitmapData;
import bitdecay.flixel.debug.tools.btree.BTreeInspector.TreeNav;

#if FLX_DEBUG
import bitdecay.behavior.Tools;
import bitdecay.behavior.tree.context.BTContext;
import haxe.ds.ArraySort;
import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.system.debug.DebuggerUtil;
import flixel.system.debug.FlxDebugger.GraphicArrowLeft;
import flixel.system.debug.FlxDebugger.GraphicArrowRight;
import flixel.system.debug.Window;
import flixel.system.ui.FlxSystemButton;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSignal.FlxTypedSignal;
import flixel.util.FlxSpriteUtil;
import openfl.display.Bitmap;
import openfl.display.Graphics;
import openfl.display.LineScaleMode;
import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.geom.Matrix;
import openfl.text.TextField;
using flixel.util.FlxBitmapDataUtil;
#end

/**
 * An output window that lets you paste BitmapData in the debugger overlay.
 */
class BTreeInspectorWindow extends DebugToolWindow {
	#if FLX_DEBUG
	static inline var FOOTER_HEIGHT = 48;
	static inline var CTX_WIDTH = 200;

	public var zoom(default, set):Float = 1;
	var requestedZoom:Float = 1;

	var _zoomCenter:FlxPoint = FlxPoint.get();

	var _canvas(get, never):BitmapData;
	var _canvasBitmap:Bitmap;
	var _entries:Array<TreeVisEntry> = [];
	var _curIndex:Int = 0;
	var _curEntry(get, never):TreeVisEntry;
	var _curBitmap(get, never):BitmapData;
	var _point:FlxPoint = FlxPoint.get();
	var _lastMousePos:FlxPoint = FlxPoint.get();
	var _curRenderOffsetRaw:FlxPoint = FlxPoint.get();
	var _matrix:Matrix = new Matrix();
	var _buttonLeft:FlxSystemButton;
	var _buttonText:FlxSystemButton;
	var _buttonRight:FlxSystemButton;
	var _counterText:TextField;
	var _dimensionsText:TextField;
	var _ui:Sprite;
	var _middleMouseDown:Bool = false;
	var _footer:Bitmap;
	var _footerText:TextField;
	var _ctxSidebar:Bitmap;
	var _ctxText:TextField;

	var footerText:String = "";

	public var onClick = new FlxTypedSignal<(String, Int, Int) -> Void>();
	public var onChange = new FlxTypedSignal<(String) -> Void>();

	public function new(icon:BitmapData) {
		super("BTree Inspector", icon);

		minSize.x = 165;
		minSize.y = Window.HEADER_HEIGHT + FOOTER_HEIGHT + 1;

		_canvasBitmap = new Bitmap(new BitmapData(Std.int(width), Std.int(Math.max( 50, height - Window.HEADER_HEIGHT - FOOTER_HEIGHT)), true, FlxColor.TRANSPARENT));
		_canvasBitmap.x = 0;
		_canvasBitmap.y = Window.HEADER_HEIGHT;
		addChild(_canvasBitmap);

		createHeaderUI();
		createFooterUI();
		createContextUI();

		setVisible(false);

		#if FLX_MOUSE
		addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
		#if FLX_MOUSE_ADVANCED
		addEventListener(MouseEvent.MIDDLE_MOUSE_DOWN, onMiddleDown);
		addEventListener(MouseEvent.MIDDLE_MOUSE_UP, onMiddleUp);
		#end
		#end

		FlxG.signals.preStateSwitch.add(clear);

		// place the handle on top
		removeChild(_handle);
		addChild(_handle);

		removeChild(_shadow);
	}

	function createHeaderUI():Void {
		_ui = new Sprite();
		_ui.y = 2;

		_buttonLeft = new FlxSystemButton(new GraphicArrowLeft(0, 0), previous);

		_dimensionsText = DebuggerUtil.createTextField();

		_counterText = DebuggerUtil.createTextField();
		_counterText.text = "0/0";

		// allow clicking on the text to reset the current settings
		_buttonText = new FlxSystemButton(null, function() {
			resetSettings();
			dirty = true;
		});
		_buttonText.addChild(_counterText);

		_buttonRight = new FlxSystemButton(new GraphicArrowRight(0, 0), next);
		_buttonRight.x = 60;

		_ui.addChild(_buttonLeft);
		_ui.addChild(_buttonText);
		_ui.addChild(_buttonRight);

		addChild(_ui);
		addChild(_dimensionsText);
	}

	function createFooterUI():Void {
		_footer = new Bitmap(new BitmapData(1, FOOTER_HEIGHT, true, Window.HEADER_COLOR));
		_footer.alpha = Window.HEADER_ALPHA;
		addChild(_footer);

		_footerText = DebuggerUtil.createTextField();
		addChild(_footerText);
	}

	function createContextUI():Void {
		_ctxSidebar = new Bitmap(new BitmapData(CTX_WIDTH, 1, true, Window.HEADER_COLOR));
		_ctxSidebar.alpha = Window.HEADER_ALPHA;
		addChild(_ctxSidebar);

		_ctxText = DebuggerUtil.createTextField();
		addChild(_ctxText);
	}

	/**
	 * Clean up memory.
	 */
	override public function destroy():Void {
		super.destroy();

		clear();

		removeChild(_canvasBitmap);
		FlxDestroyUtil.dispose(_canvas);
		_canvasBitmap.bitmapData = null;
		_canvasBitmap = null;
		_entries = null;

		removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
		#if FLX_MOUSE_ADVANCED
		removeEventListener(MouseEvent.MIDDLE_MOUSE_DOWN, onMiddleDown);
		removeEventListener(MouseEvent.MIDDLE_MOUSE_UP, onMiddleUp);
		#end

		FlxG.signals.preStateSwitch.remove(clear);
	}

	override public function update():Void {
		super.update();
		if (_middleMouseDown) {
			var delta = FlxPoint.get(mouseX, mouseY);
			_curRenderOffsetRaw.add(delta.subtractPoint(_lastMousePos));
			dirty = true;
			_lastMousePos.set(mouseX, mouseY);
		}

		if (dirty && _curEntry != null) {
			dirty = false;
			onChange.dispatch(_curEntry.name);
			refreshCanvas();
		}
	}

	override function updateSize():Void {
		super.updateSize();
		// account for the footer
		_background.scaleY = _height - _header.height - _footer.height;
	}

	override public function resize(Width:Float, Height:Float):Void {
		super.resize(Width, Height);

		_canvasBitmap.bitmapData = FlxDestroyUtil.dispose(_canvas);

		var newWidth = Std.int(Math.max(1, _width - _canvasBitmap.x - _ctxSidebar.width));
		var newHeight = Std.int(Math.max(1, _height - _canvasBitmap.y - _footer.height));

		_canvasBitmap.bitmapData = new BitmapData(newWidth, newHeight, true, FlxColor.TRANSPARENT);
		dirty = true;

		_ui.x = _header.width - _ui.width - 5;

		_footer.width = _width;
		_footer.y = _height - _footer.height;

		_ctxSidebar.height = _height - _header.height - _footer.height;
		_ctxSidebar.x = _width - _ctxSidebar.width;
		_ctxSidebar.y = _header.height;

		resizeTexts();
	}

	public function resizeTexts():Void {
		_dimensionsText.x = _header.width / 2 - _dimensionsText.textWidth / 2;
		_dimensionsText.visible = (_width > 200);

		_footerText.y = _height - _footer.height;
		_footerText.x = 0;

		_ctxText.x = _width - _ctxSidebar.width;
		_ctxText.y = _header.height;

		_buttonText.x = 33 - _counterText.textWidth / 2;
	}

	/**
	 * Show the next logged BitmapData in memory
	 */
	inline function next():Void {
		resetSettings();
		refreshCanvas(_curIndex + 1);
	}

	/**
	 * Show the previous logged BitmapData in memory
	 */
	inline function previous():Void {
		resetSettings();
		refreshCanvas(_curIndex - 1);
	}

	function resetSettings():Void {
		if (_curEntry != null && _canvas != null) {
			if (_curEntry.nav.zoom == 0) {
				zoom = Math.min(_canvas.height / _curEntry.bitmap.height, _canvas.width / _curEntry.bitmap.width);
			} else {
				zoom = Math.min(_curEntry.nav.zoom, _curEntry.nav.zoom);
			}
		} else {
			zoom = 1;
		}
		requestedZoom = zoom;
		_curRenderOffsetRaw.set(_curEntry.nav.xOffset, _curEntry.nav.yOffset);
	}

	/**
	 * Add a BitmapData to the log
	 */
	public function add(bmp:BitmapData, name:String = "", nav:TreeNav):Bool {
		if (bmp == null) {
			return false;
		}
		if (nav == null) {
			nav = {
				zoom: 1,
				xOffset: 0,
				yOffset: 0
			};
		}
		_entries.push({bitmap: bmp, name: name, nav: nav});
		resetSettings();
		dirty = true;
		return true;
	}

	/**
	 * Clear one bitmap object from the log -- the last one, by default
	 */
	public function clearAt(Index:Int = -1):Void {
		if (Index == -1) {
			Index = _entries.length - 1;
		}
		FlxDestroyUtil.dispose(_entries[Index].bitmap);
		_entries[Index] = null;
		_entries.splice(Index, 1);

		if (_curIndex > _entries.length - 1) {
			_curIndex = _entries.length - 1;
		}

		dirty = true;
	}

	public function clear():Void {
		for (i in 0..._entries.length) {
			FlxDestroyUtil.dispose(_entries[i].bitmap);
			_entries[i] = null;
		}
		_entries = [];
		if (_canvas != null)
			_canvas.fillRect(_canvas.rect, FlxColor.TRANSPARENT);
		_dimensionsText.text = "";
		_counterText.text = "0/0";
		_footerText.text = "";
	}

	function refreshCanvas(?Index:Null<Int>):Bool {
		if (_entries == null || _entries.length <= 0) {
			_curIndex = 0;
			return false;
		}

		if (Index == null) {
			Index = _curIndex;
		}

		_canvas.fillRect(_canvas.rect, FlxColor.TRANSPARENT);

		if (Index < 0) {
			Index = _entries.length - 1;
		} else if (Index >= _entries.length) {
			Index = 0;
		}

		_curIndex = Index;

		setRenderTopLeft();

		_matrix.identity();
		_matrix.scale(zoom, zoom);
		if (requestedZoom != zoom) {
			// get vector from mouse to top-left of graphic
			var offsetMath = FlxPoint.get().copyFrom(_curRenderOffsetRaw).subtractPoint(_zoomCenter);
			// invert zoom to find raw length of vector
			offsetMath.scale(1/zoom);
			// apply new zoom to get length of vector at new zoom scale
			offsetMath.scale(requestedZoom);
			// add our mouse position back in
			offsetMath.add(_zoomCenter);
			// save our new offset
			_curRenderOffsetRaw.copyFrom(offsetMath);
			offsetMath.put();
			zoom = requestedZoom;
		}
		_matrix.translate(_curRenderOffsetRaw.x, _curRenderOffsetRaw.y);

		drawBoundingBox(_curBitmap);
		_canvas.draw(_curBitmap, _matrix, null, null, _canvas.rect, false);

		_canvas.draw(FlxSpriteUtil.flashGfxSprite, _matrix, null, null, _canvas.rect, false);

		refreshTexts();

		return true;
	}

	function setRenderTopLeft() {
		_point.copyFrom(_curRenderOffsetRaw);
	}

	function refreshTexts():Void {
		_counterText.text = '${_curIndex + 1}/${_entries.length}';

		var entryName:String = _curEntry != null ? _curEntry.name : "";
		_dimensionsText.text = entryName;

		_footerText.text = footerText;

		resizeTexts();
	}

	public function setInfoText(text:String) {
		footerText = text;
		refreshTexts();
	}

	public function setContext(ctx:BTContext) {
		@:privateAccess {
			var keyIter = ctx.contents.keys();
			var rawKeys:Array<String> = [];
			while (keyIter.hasNext()) {
				rawKeys.push(keyIter.next());
			}

			ArraySort.sort(rawKeys, strSort);

			var displayText:Array<String> = [];
			for (k in rawKeys) {
				displayText.push('${k}: ${format(ctx.get(k))}');
			};

			_ctxText.text = displayText.join("\n");
		}
	}

	function format(v:Dynamic):String {
		if (Std.isOfType(v, Array)) {
			var arr:Array<Dynamic> = cast v;
			return 'Array[' + arr.length + ']';
		}

		switch Type.typeof(v) {
			case TFloat:
				return Std.string(FlxMath.roundDecimal(cast v, 3));
			case TClass(c):
				// For instances, get the class name only
				return Type.getClassName(Type.getClass(v));
			default:
				return Std.string(v);
		}
	}

	function strSort(a:String, b:String):Int {
		a = a.toUpperCase();
		b = b.toUpperCase();

		if (a < b) {
			return -1;
		}
		else if (a > b) {
			return 1;
		} else {
			return 0;
		}
	};

	function drawBoundingBox(bitmap:BitmapData):Void {
		var gfx:Graphics = FlxSpriteUtil.flashGfx;
		gfx.clear();
		gfx.lineStyle(1, FlxColor.RED, 0.25, false, LineScaleMode.NONE);
		var offset = 1 / zoom;
		gfx.drawRect(-offset, -offset, bitmap.width + offset, bitmap.height + offset);
	}

	override function onMouseDown(?_:MouseEvent) {
		super.onMouseDown(_);

		// This sets _point to the top left corner of the image in window coordinates
		setRenderTopLeft();
		_point.subtract(mouseX, mouseY - _header.height);
		// this adjusts for zoom and flips the XY so that they are in the positive direction
		_point.scale(-1 / zoom);

		if (_curEntry != null) {
			onClick.dispatch(_curEntry.name, cast _point.x, cast _point.y);
		}
	}

	function onMouseWheel(e:MouseEvent):Void {
		// some goofy math to make zoom ticks consistent. Down by 25% is the inverse of up by 33%
		requestedZoom = zoom + FlxMath.signOf(e.delta) * (FlxMath.signOf(e.delta) > 0 ? (1/3) : 0.25) * zoom;
		_zoomCenter.set(mouseX, mouseY - _header.height);
		dirty = true;
	}

	function onMiddleDown(e:MouseEvent):Void {
		_middleMouseDown = true;
		_lastMousePos.set(mouseX, mouseY);
	}

	function onMiddleUp(e:MouseEvent):Void {
		_middleMouseDown = false;
	}

	function set_zoom(Value:Float):Float {
		if (Value < 0) {
			Value = 0;
		}
		return zoom = Value;
	}

	inline function get__canvas():BitmapData {
		return _canvasBitmap.bitmapData;
	}

	inline function get__curEntry():TreeVisEntry {
		return _entries[_curIndex];
	}

	inline function get__curBitmap():BitmapData {
		return _entries[_curIndex].bitmap;
	}
	#end
}

typedef TreeVisEntry = {
	bitmap:BitmapData,
	name:String,
	nav:TreeNav,
}
