package bitdecay.flixel.debug.tools.btree;

#if debug
import bitdecay.behavior.tree.BTExecutor;
import bitdecay.behavior.tree.Node;
import bitdecay.behavior.tree.NodeStatus;
import bitdecay.behavior.tree.composite.*;
import bitdecay.behavior.tree.decorator.*;
import bitdecay.behavior.tree.leaf.*;
import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.math.FlxAngle;
import flixel.math.FlxMatrix;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import openfl.display.BitmapData;
import openfl.display.BlendMode;
import openfl.display.Shape;

class BTreeVisualizer extends FlxBasic {
	var exec:BTExecutor;

	public var dirty:Bool = false;
	public var focusNode:Node = null;
	public var treeGraph:BitmapData;
	public var activationImage:BitmapData;
	public var composite:BitmapData;

	var borderGap = 3;
	
	// helper to draw lines onto our bitmaps
	var shapeDrawer = new Shape();

	var boxes = new Array<FlxRect>();
	var parentMap:Map<Node, Node> = [];
	var ownerMap:Map<Node, FlxRect> = [];

	var maxWidth = 0.0;
	var maxHeight = 0.0;

	var spacing = 10;

	var redraws = 0;

	var iconStamp:FlxSprite;
	var iconMap:Map<String, Int> = [
		Type.getClassName(Repeater) => 0,
		Type.getClassName(Parallel) => 10,
		Type.getClassName(Selector) => 1,
		Type.getClassName(Sequence) => 11,
		Type.getClassName(TimeLimit) => 2,
		Type.getClassName(Wait) => 12,
		Type.getClassName(SetVariable) => 3,
		Type.getClassName(IsVarNull) => 13,
		Type.getClassName(RemoveVariable) => 23,
		Type.getClassName(Action) => 4,
		Type.getClassName(StatusAction) => 14,
		Type.getClassName(Subtree) => 5,
		Type.getClassName(HierarchicalContext) => 15,
		Type.getClassName(Inverter) => 6,
		Type.getClassName(Interrupter) => 16,
		Type.getClassName(Success) => 7,
		Type.getClassName(Succeeder) => 17,
		Type.getClassName(Fail) => 8,
		Type.getClassName(Failer) => 18,
	];

	var focusColor = FlxColor.MAGENTA;
	var statusColorMap:Map<NodeStatus, FlxColor> = [
		RUNNING => FlxColor.YELLOW,
		SUCCESS => FlxColor.BLUE.getDarkened(.5),
		FAIL => FlxColor.RED.getDarkened(.5),
		UNKNOWN => FlxColor.BLACK
	];

	public function new(exec:BTExecutor) {
		super();
		this.exec = exec;

		iconStamp = new FlxSprite();
		@:privateAccess
		iconStamp.loadGraphic(BTreeInspector.nodeIconBitmap, true, 16, 16);

		exec.addChangeListener(drawActivationLine);
		exec.addPostProcessListener(() -> {
			if (redraws > 0) {
				// only go through the bother of drawing our lines and clearing the graphics
				// if we actually have something to draw
				redraws = 0;
				composite.draw(shapeDrawer);
				shapeDrawer.graphics.clear();
			}
		});
	}

	function drawActivationLine(parent:Node, child:Node, status:NodeStatus) {
		redraws++;
		drawLineBetweenNodes(parent, child, statusColorMap.get(status));
		dirty = true;
	}

	function makeNodeBox(n:Node, depth:Int, row:Int):FlxRect {
		var box = FlxRect.get(depth * (iconStamp.width + spacing) + borderGap, row * (iconStamp.width + spacing) + borderGap, iconStamp.width, iconStamp.width);
		maxWidth = Math.max(maxWidth, box.right + borderGap);
		maxHeight = Math.max(maxHeight, box.bottom + borderGap);
		boxes.push(box);
		ownerMap.set(n, box);
		return box;
	};

	override function update(elapsed:Float) {
		super.update(elapsed);
	}

	public function nodeAtPoint(x:Int, y:Int):Node {
		for (node => box in ownerMap) {
			if (box.containsXY(x, y)) {
				return node;
			}
		}

		return null;
	}

	function exploreNode(n:Node, depth:Int, row:Int):Int {
		makeNodeBox(n, depth, row);
		@:privateAccess
		var children = n.getChildren();
		for (i in 0...children.length) {
			if (i > 0) {
				row += 1;
			}
			row = exploreNode(children[i], depth + 1, row);
		}
		return row;
	};

	function drawLineBetweenNodes(parent:Node, child:Node, color:FlxColor = FlxColor.BLUE) {
		var gfx = shapeDrawer.graphics;
		var cRect = ownerMap.get(child);
		gfx.lineStyle(2, color);

		if (parent != null) {
			var pRect = ownerMap.get(parent);
			gfx.moveTo(pRect.right + 1, pRect.top + pRect.height / 2);
			gfx.lineTo(pRect.right + spacing / 2, pRect.top + pRect.height / 2);
			gfx.lineTo(pRect.right + spacing / 2, cRect.top + cRect.height / 2);
			gfx.lineTo(cRect.left - 1, cRect.top + cRect.height / 2);
		}

		// gfx.drawRoundRect(cRect.left-1, cRect.top-1, cRect.width+2, cRect.height+2, cRect.width / 2, cRect.height / 2);
		if (child == focusNode) {
			gfx.lineStyle(2, focusColor);
		}
		
		gfx.drawRect(cRect.left - 1, cRect.top - 1, cRect.width + 2, cRect.height + 2);
	}

	function buildTreeGraphic() {
		treeGraph = new BitmapData(Std.int(maxWidth), Std.int(maxHeight));
		treeGraph.floodFill(0, 0, FlxColor.TRANSPARENT);

		activationImage = new BitmapData(Std.int(maxWidth), Std.int(maxHeight));
		activationImage.floodFill(0, 0, FlxColor.TRANSPARENT);

		composite = new BitmapData(Std.int(maxWidth), Std.int(maxHeight));
		composite.floodFill(0, 0, FlxColor.TRANSPARENT);

		for (node => rect in ownerMap) {
			var nodeClass = Type.getClassName(Type.getClass(node));
			if (iconMap.exists(nodeClass)) {
				iconStamp.animation.frameIndex = iconMap.get(nodeClass);
			}

			iconStamp.drawFrame();
			var _matrix = new FlxMatrix();
			_matrix.identity();
			_matrix.translate(-iconStamp.origin.x, -iconStamp.origin.y);
			_matrix.scale(iconStamp.scale.x, iconStamp.scale.y);
			if (iconStamp.angle != 0) {
				_matrix.rotate(iconStamp.angle * FlxAngle.TO_RAD);
			}
			_matrix.translate(rect.x + iconStamp.origin.x, rect.y + iconStamp.origin.y);
			var brushBlend:BlendMode = iconStamp.blend;
			treeGraph.draw(iconStamp.framePixels, _matrix, null, brushBlend, null, iconStamp.antialiasing);
		}

		shapeDrawer.graphics.clear();
		for (node => rect in ownerMap) {
			@:privateAccess
			var children = node.getChildren();
			for (i in 0...children.length) {
				var child = children[i];
				parentMap.set(child, node);
				drawLineBetweenNodes(node, child, FlxColor.BLACK);
			}
		}
		treeGraph.draw(shapeDrawer);

		// start our composite showing exactly our untraversed graph
		composite.draw(treeGraph);
	}

	public function build() {
		@:privateAccess
		exploreNode(exec.root, 0, 0);
		buildTreeGraphic();
	}
}
#end
