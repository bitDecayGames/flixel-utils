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
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets;
import flixel.util.FlxColor;
import openfl.display.BitmapData;
import openfl.display.BlendMode;
import openfl.display.Shape;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;
import openfl.text.TextField;
import openfl.text.TextFormat;

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
		Type.getClassName(Fallback) => 1,
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
		// Type.getClassName(Interrupter) => 16,
		Type.getClassName(Success) => 7,
		Type.getClassName(Succeeder) => 17,
		Type.getClassName(Fail) => 8,
		Type.getClassName(Failer) => 18,
		Type.getClassName(Condition) => 9,
	];

	var focusColor = FlxColor.MAGENTA;
	var statusColorMap:Map<NodeStatus, FlxColor> = [
		RUNNING => FlxColor.YELLOW,
		SUCCESS => FlxColor.BLUE.getDarkened(.5),
		FAIL => FlxColor.RED.getDarkened(.5),
		UNKNOWN => FlxColor.BLACK
	];
	var nodeColorMap:Map<String, FlxColor> = [
		Type.getClassName(HierarchicalContext) => FlxColor.PINK.getDarkened(),
	];

	public function new(exec:BTExecutor) {
		super();
		this.exec = exec;

		iconStamp = new FlxSprite();
		@:privateAccess
		iconStamp.loadGraphic(BTreeInspector.nodeIconBitmap, true, 16, 16);

		exec.addChangeListener(drawActivationLine);
	}

	function flushPendingDraws() {
		if (redraws > 0) {
			// only go through the bother of drawing our lines and clearing the graphics
			// if we actually have something to draw
			redraws = 0;
			activationImage.draw(shapeDrawer);
			shapeDrawer.graphics.clear();

			composite.fillRect(new Rectangle(0, 0, composite.width, composite.height), FlxColor.TRANSPARENT);
			composite.draw(treeGraph);
			composite.draw(activationImage);

			if (focusNode != null) {
				var cRect = ownerMap.get(focusNode);
				shapeDrawer.graphics.beginFill(FlxColor.MAGENTA, 0.5);
				shapeDrawer.graphics.drawRect(cRect.left, cRect.top, cRect.width, cRect.height);
				composite.draw(shapeDrawer);
				shapeDrawer.graphics.clear();
			}
		}
	}

	function drawActivationLine(parent:Node, child:Node, status:NodeStatus) {
		drawLineBetweenNodes(parent, child, statusColorMap.get(status));
		dirty = true;
	}

	// vertical offset persists to all further nodes
	var extraVertOffset = 0.0;

	// while extra horizontal on impacts children of this node directly
	function makeNodeBox(n:Node, depth:Int, row:Int, extraHorizontal:Int):Int {
		if (n.getName() != null && n.getName() != "") {
			extraVertOffset += 25;
			extraHorizontal += 10;
		}
		var box = FlxRect.get(depth * (iconStamp.width + spacing) + borderGap + extraHorizontal, row * (iconStamp.width + spacing) + borderGap + extraVertOffset, iconStamp.width, iconStamp.width);
		maxWidth = Math.max(maxWidth, box.right + borderGap);
		maxHeight = Math.max(maxHeight, box.bottom + borderGap);
		boxes.push(box);
		ownerMap.set(n, box);
		return extraHorizontal;
	};

	override function update(elapsed:Float) {
		super.update(elapsed);

		flushPendingDraws();
	}

	public function nodeAtPoint(x:Int, y:Int):Node {
		for (node => box in ownerMap) {
			if (box.containsXY(x, y)) {
				return node;
			}
		}

		return null;
	}

	function exploreNode(n:Node, depth:Int, row:Int, extraHorizontal:Int):Int {
		extraHorizontal = makeNodeBox(n, depth, row, extraHorizontal);
		@:privateAccess
		var children = n.getChildren();
		for (i in 0...children.length) {
			if (i > 0) {
				row += 1;
			}
			row = exploreNode(children[i], depth + 1, row, extraHorizontal);
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
		
		gfx.drawRect(cRect.left - 1, cRect.top - 1, cRect.width + 2, cRect.height + 2);
		redraws++;
		dirty = true;
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
			treeGraph.draw(iconStamp.framePixels, _matrix, null, brushBlend, null, true);

			drawNodeNameBox(node);
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

	// helpers for rendering text to our debug image
	var textField:TextField = null;
	var textMatrix = new Matrix();
	var textFormat:TextFormat = null;

	private function drawNodeNameBox(node:Node) {
		var name = node.getName();
		if (name == null || name == "") {
			return;
		}

		var cRect = ownerMap.get(node);
		var color = getNodeColor(node);

		if (textField == null) {
			textFormat = new TextFormat(FlxAssets.FONT_DEFAULT, 10, FlxColor.WHITE);
			textField = new TextField();
			textField.embedFonts = true;
		}

		textField.text = node.getName();
		// Set textFormat _after_ setting the text into the field to avoid weird defaults getting set
		// due to an empty stringtextField.setTextFormat(textFormat);
		textField.textColor = color;
		textField.width += 10; // for some reason our width was smaller than our text, so it was getting cut off


		textMatrix.identity(); // Reset our matrix
		textMatrix.translate(cRect.left - 2, cRect.top - 22);
		treeGraph.draw(textField, textMatrix);

		var gfx = shapeDrawer.graphics;
		gfx.lineStyle(2, color);
		var size = getChildLimits(node);
		gfx.drawRect(cRect.left - 7, cRect.top - 7, size.x + 10, size.y + 10);
		treeGraph.draw(shapeDrawer);
		shapeDrawer.graphics.clear();
	}

	private function getChildLimits(node:Node):FlxPoint {
		var max = FlxPoint.get();
		var hunt:(n:Node) -> Void;
		hunt = (n:Node) -> {
			var cRect = ownerMap.get(n);
			max.set(Math.max(max.x, cRect.right), Math.max(max.y, cRect.bottom));
			@:privateAccess
			for (c in n.getChildren()) {
				hunt(c);
			}
		}
		hunt(node);
		var nRect = ownerMap.get(node);
		max.subtract(nRect.left, nRect.top);
		return max;
	}

	public function build() {
		@:privateAccess
		exploreNode(exec.root, 0, 0, 0);
		buildTreeGraphic();
	}

	function getNodeColor(n:Node):FlxColor {
		var nodeClass = Type.getClassName(Type.getClass(n));
		if (nodeColorMap.exists(nodeClass)) {
			return nodeColorMap.get(nodeClass);
		}

		return FlxColor.WHITE;
	}
}
#end
