package bitdecay.flixel.debug.tools.btree;

#if FLX_DEBUG
import flixel.util.FlxSignal.FlxTypedSignal;
import flixel.system.debug.DebuggerUtil;
import flixel.FlxG;
import flixel.system.debug.Window;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Graphics;
import openfl.display.LineScaleMode;
import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.geom.Matrix;
import openfl.text.TextField;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.system.ui.FlxSystemButton;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxStringUtil;
import flixel.system.debug.FlxDebugger.GraphicArrowLeft;
import flixel.system.debug.FlxDebugger.GraphicArrowRight;
import flixel.system.debug.FlxDebugger.GraphicBitmapLog;

using flixel.util.FlxBitmapDataUtil;

/**
 * An output window that lets you paste BitmapData in the debugger overlay.
 */
class BTreeInspectorWindow extends DebugToolWindow {
	static inline var FOOTER_HEIGHT = 48;

	public var zoom(default, set):Float = 1;

	var _zoomCenter:FlxPoint = FlxPoint.get();

	var _canvas(get, never):BitmapData;
	var _canvasBitmap:Bitmap;
	var _entries:Array<TreeVisEntry> = [];
	var _curIndex:Int = 0;
	var _curEntry(get, never):TreeVisEntry;
	var _curBitmap(get, never):BitmapData;
	var _point:FlxPoint = FlxPoint.get();
	var _lastMousePos:FlxPoint = FlxPoint.get();
	var _curMouseOffset:FlxPoint = FlxPoint.get();
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

	var footerText:String = "";

	public var onClick = new FlxTypedSignal<(String, Int, Int) -> Void>();

	public function new(icon:BitmapData) {
		super("BTree Inspector", icon);

		minSize.x = 165;
		minSize.y = Window.HEADER_HEIGHT + FOOTER_HEIGHT + 1;

		_canvasBitmap = new Bitmap(new BitmapData(Std.int(width), Std.int(height - Window.HEADER_HEIGHT - FOOTER_HEIGHT), true, FlxColor.TRANSPARENT));
		_canvasBitmap.x = 0;
		_canvasBitmap.y = Window.HEADER_HEIGHT;
		addChild(_canvasBitmap);

		createHeaderUI();
		createFooterUI();

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
			refreshCanvas();
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
		if (_middleMouseDown) {
			var delta = FlxPoint.get(mouseX, mouseY);
			_curMouseOffset.add(delta.subtract(_lastMousePos));
			refreshCanvas();
			_lastMousePos.set(mouseX, mouseY);
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

		var newWidth = Std.int(_width - _canvasBitmap.x);
		var newHeight = Std.int(_height - _canvasBitmap.y - _footer.height);

		if (newWidth > 0 && newHeight > 0) {
			_canvasBitmap.bitmapData = new BitmapData(newWidth, newHeight, true, FlxColor.TRANSPARENT);
			refreshCanvas(_curIndex);
		}

		_ui.x = _header.width - _ui.width - 5;

		_footer.width = _width;
		_footer.y = _height - _footer.height;

		resizeTexts();
	}

	public function resizeTexts():Void {
		_dimensionsText.x = _header.width / 2 - _dimensionsText.textWidth / 2;
		_dimensionsText.visible = (_width > 200);

		_footerText.y = _height - _footer.height;
		_footerText.x = 0;

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

	inline function resetSettings():Void {
		zoom = Math.min(_canvas.height / _curEntry.bitmap.height, _canvas.width / _curEntry.bitmap.width);
		_curMouseOffset.set();
	}

	/**
	 * Add a BitmapData to the log
	 */
	public function add(bmp:BitmapData, name:String = ""):Bool {
		if (bmp == null) {
			return false;
		}
		setVisible(true);
		_entries.push({bitmap: bmp, name: name});
		resetSettings();
		return refreshCanvas();
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

		refreshCanvas(_curIndex);
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

		setCanvasTopLeft();

		_matrix.identity();
		// _matrix.translate(-_zoomCenter.x, -_zoomCenter.y);
		_matrix.scale(zoom, zoom);
		// _matrix.translate(_zoomCenter.x, _zoomCenter.y);
		_matrix.translate(_point.x, _point.y);

		drawBoundingBox(_curBitmap);
		_canvas.draw(_curBitmap, _matrix, null, null, _canvas.rect, false);

		_canvas.draw(FlxSpriteUtil.flashGfxSprite, _matrix, null, null, _canvas.rect, false);

		refreshTexts();

		return true;
	}

	function setCanvasTopLeft() {
		_point.x = (_canvas.width / 2) - (_curBitmap.width * zoom / 2);
		_point.y = (_canvas.height / 2) - (_curBitmap.height * zoom / 2);

		_point.add(_curMouseOffset);
	}

	function refreshTexts():Void {
		_counterText.text = '${_curIndex + 1}/${_entries.length}';

		var entryName:String = _curEntry != null ? _curEntry.name : "";
		var name:String = (entryName == "") ? "" : '"$entryName" | ';
		_dimensionsText.text = _curEntry.name;

		_footerText.text = footerText;

		resizeTexts();
	}

	public function setInfoText(text:String) {
		footerText = text;
		refreshTexts();
	}

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
		setCanvasTopLeft();
		_point.subtract(mouseX, mouseY - _header.height);
		// this adjusts for zoom and flips the XY so that they are in the positive direction
		_point.scale(-1 / zoom);

		onClick.dispatch(_curEntry.name, cast _point.x, cast _point.y);
	}

	function onMouseWheel(e:MouseEvent):Void {
		zoom += FlxMath.signOf(e.delta) * 0.25 * zoom;

		// sets our zoom center. Feels like this needs to take zoom into account
		_zoomCenter.copyFrom(_point).subtract(mouseX, mouseY - _header.height);
		refreshCanvas();
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
}

typedef TreeVisEntry = {
	bitmap:BitmapData,
	name:String,
}
#end
