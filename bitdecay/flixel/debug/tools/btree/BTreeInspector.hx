package bitdecay.flixel.debug.tools.btree;

import bitdecay.behavior.tree.Node;
import flixel.FlxG;
import haxe.io.Bytes;
import openfl.display.Loader;
import openfl.events.Event;
#if FLX_DEBUG
import bitdecay.behavior.tree.BTExecutor;
import bitdecay.flixel.debug.DebugTool.BaseToolData;
import openfl.display.BitmapData;
using flixel.util.FlxBitmapDataUtil;

/**
 * An output window that lets you paste BitmapData in the debugger overlay.
 */
class BTreeInspector extends DebugTool<BTreeInspectorWindow> {
	static var iconData = [
		[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
		[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
		[0.0, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.0],
		[0.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 0.0],
		[0.0, 1.0, 1.0, 1.0, 0.0, 1.0, 0.0, 1.0, 1.0, 1.0, 0.0],
		[0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0],
		[0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 1.0, 0.0],
		[0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.0, 1.0, 0.0],
		[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.0],
		[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
		[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	];

	// populated at runtime
	static var nodeIconBitmap:BitmapData = null;

	var pendingAdds:Map<String, BTExecutor> = [];

	var trees:Map<String, BTreeVisualizer> = [];

	var focusNode:Node = null;

	public function new() {
		super("btree", iconData);

		window.onClick.add(handleClick);

		FlxG.signals.preStateSwitch.add(clear);
	}

	function clear() {
		trees.clear();
		window.clear();
	}

	override function init() {
		super.init();

		@:privateAccess
		var bytes = haxe.crypto.Base64.decode(BTreeIconData.nodeIconData.split(",")[1]);
        var loader = new Loader();
        loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event) {
            nodeIconBitmap = cast(loader.content, openfl.display.Bitmap).bitmapData;
        });
        loader.loadBytes(bytes.getData());
	}

	override function loadData() {
		super.loadData();

		window.resize(window.width, window.height);

		// This probably isn't the right way to do this
		FlxG.plugins.addPlugin(this);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (nodeIconBitmap != null) {
			for (name => btree in pendingAdds) {
				var visualizer = new BTreeVisualizer(btree);
				visualizer.build();
				window.add(visualizer.composite, name);
				trees.set(name, visualizer);
			}
			pendingAdds.clear();
		}

		if (focusNode != null) {
			trace(Type.getClassName(Type.getClass(focusNode)));
			@:privateAccess
			window.setInfoText([Type.getClassName(Type.getClass(focusNode))].concat(focusNode.getDetail()).join("\n"));
		}

		@:privateAccess {
			for (name => treeVis in trees) {
				if (treeVis.dirty && window._curEntry.name == name) {
					treeVis.dirty = false;
					window.refreshCanvas();
					break;
				}
			}
		}
	}

	override function getDefaults():Dynamic {
		var defaults = super.getDefaults();
		defaults.googly = 1.25;
		return defaults;
	}

	function handleClick(name:String, x:Int, y:Int) {
		var vis = trees.get(name);
		focusNode = vis.nodeAtPoint(x, y);
	}

	override function makeWindow(icon:BitmapData):BTreeInspectorWindow {
		return new BTreeInspectorWindow(icon);
	}

	public function addTree(name:String, btree:BTExecutor) {
		pendingAdds.set(name, btree);
	}
}

typedef BTreeInspectorData = BaseToolData & {
	var ?googly:Float;
}
#end
