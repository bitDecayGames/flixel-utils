package bitdecay.flixel.debug.tools.draw;

import flixel.util.FlxSignal.FlxTypedSignal;
#if FLX_DEBUG
import bitdecay.flixel.debug.tools.draw.DebugDraw;
import flixel.FlxG;
import flixel.system.debug.DebuggerUtil;
import flixel.system.debug.Window;
import flixel.util.FlxColor;
import openfl.display.BitmapData;
import openfl.events.MouseEvent;
import openfl.text.TextField;

/**
 * A simple window that provides toggle buttons for each custom debug draw layers
**/
class DebugDrawWindow extends DebugToolWindow {
	/**
	 * How often to update the stats, in ms. The lower, the more performance-intense!
	 */
	static inline var UPDATE_DELAY:Int = 250;

	public static inline var TEXT_SIZE:Int = 11;

	private var callCountLabel:TextField;

	private var collapseLabel:TextField;
	private var collapsed:Bool = false;
	private var fullSizeMin:Float = 0;
	private var collapsedSizeMin:Float = 0;

	private var labels = new Map<String, TextField>();

	public var onLayerToggle = new FlxTypedSignal<(String, Bool) -> Void>();
	public var onCollapseToggle = new FlxTypedSignal<(Bool) -> Void>();

	var gutter = 5;
	var buttonStartY:Int = 0;

	public function new(icon:BitmapData) {
		super("Layers", icon, 0, 0, false);

		var nextY:Int = Std.int(_header.height) + gutter;

		collapseLabel = DebuggerUtil.createTextField(gutter, nextY, FlxColor.BLACK, TEXT_SIZE);
		collapseLabel.border = true;
		collapseLabel.borderColor = FlxColor.BLACK;
		collapseLabel.background = true;
		collapseLabel.backgroundColor = FlxColor.WHITE;
		collapseLabel.text = "Collapse";
		collapseLabel.addEventListener(MouseEvent.CLICK, (me) -> {
			collapsed = !collapsed;
			updateCollapse();
		});
		addChild(collapseLabel);

		nextY += Std.int(collapseLabel.height + gutter);

		addChild(callCountLabel = DebuggerUtil.createTextField(gutter, nextY, FlxColor.WHITE, TEXT_SIZE));
		callCountLabel.text = "Draw Calls: ---";

		minSize.x = callCountLabel.width;

		nextY += Std.int(callCountLabel.height + gutter);

		buttonStartY = nextY;

		loadData();
		updateCollapse();
	}

	public function setLayers(layers:Map<String, Bool>) {
		minSize.x = callCountLabel.width;

		var nextY = buttonStartY;

		for (layerName => layerOn in layers) {
			var layerLabel = DebuggerUtil.createTextField(gutter, nextY, FlxColor.BLACK, TEXT_SIZE);
			var layerEnabled = layerOn;
			addChild(layerLabel);
			layerLabel.border = true;
			layerLabel.borderColor = FlxColor.BLACK;
			layerLabel.background = true;
			layerLabel.backgroundColor = FlxColor.WHITE;
			layerLabel.text = layerName;
			layerLabel.addEventListener(MouseEvent.CLICK, (me) -> {
				layerEnabled = !layerEnabled;
				layerLabel.backgroundColor = layerEnabled ? FlxColor.WHITE : FlxColor.GRAY;
				onLayerToggle.dispatch(layerName, layerEnabled);
			});
			labels.set(layerName, layerLabel);
			layerLabel.backgroundColor = DebugDraw.layer_enabled[layerName] ? FlxColor.WHITE : FlxColor.GRAY;

			nextY += Std.int(layerLabel.height + gutter);
			minSize.x = Math.max(minSize.x, layerLabel.width);
		}

		minSize.x += gutter * 2;
		fullSizeMin = nextY;
	}

	var _currentTime:Int;
	var _lastTime:Int = 0;
	var _updateTimer:Int = 0;

	override function update() {
		super.update();

		var time:Int = _currentTime = FlxG.game.ticks;
		var elapsed:Int = time - _lastTime;

		if (elapsed > UPDATE_DELAY) {
			elapsed = UPDATE_DELAY;
		}
		_lastTime = time;

		_updateTimer += elapsed;

		if (_updateTimer > UPDATE_DELAY) {
			callCountLabel.text = 'Draw Calls: ${DebugDraw.ME.lastCallCount}';
		}
	}

	function updateCollapse() {
			if (collapsed) {
				collapseLabel.text = "Expand";
				minSize.y = collapsedSizeMin;
				maxSize.y = collapsedSizeMin;
			} else {
				collapseLabel.text = "Collapse";
				minSize.y = fullSizeMin;
				maxSize.y = fullSizeMin;
			}
			collapseLabel.visible = false;
			collapseLabel.visible = true;

			for (l in labels) {
				l.visible = !collapsed;
			}

			updateSize();
			bound();
			reposition(x, y);

			onCollapseToggle.dispatch(collapsed);
	}


	function loadData() {
		if (!FlxG.save.isBound)
			return;

		if (FlxG.save.data.bitdecayDebug == null)
		{
			initDebugLayerSave();
		}

		for (key => value in DebugDraw.layer_enabled) {
			if (!FlxG.save.data.bitdecayDebug.layers.exists(key)) {
				FlxG.save.data.bitdecayDebug.layers.set(key, value);
			}

			if (!FlxG.save.data.bitdecayDebug.layers.get(key)) {
				DebugDraw.layer_enabled[key] = false;
				labels.get(key).backgroundColor = FlxColor.GRAY;
			}
		}

		collapsed = FlxG.save.data.bitdecayDebug.collapsed;
		reposition(FlxG.save.data.bitdecayDebug.windowX, FlxG.save.data.bitdecayDebug.windowY);
	}

	function initDebugLayerSave() {
		FlxG.save.data.bitdecayDebug = {
			enabled: false,
			collapsed: false,
			windowX: 0,
			windowY: 0,
			layers: [for (name => _ in DebugDraw.layer_enabled) name=>true ]
		};
		FlxG.save.flush();
	}

	override function reposition(X:Float, Y:Float) {
		super.reposition(X, Y);

		FlxG.save.data.bitdecayDebug.windowX = X;
		FlxG.save.data.bitdecayDebug.windowY = Y;
		FlxG.save.flush();
	}
}
#end
