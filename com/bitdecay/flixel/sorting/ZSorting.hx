package com.bitdecay.flixel.sorting;

import flixel.util.FlxSort;
import flixel.FlxSprite;

enum VerticalReference {
	TOP;
	CENTER;
	BOTTOM;
}

class ZSorting {
	public static function getSort(vRef:VerticalReference): (Order:Int, FlxSprite, FlxSprite) -> Int {
		return (order:Int, s1:FlxSprite, s2:FlxSprite) -> {
			var val1 = s1.y;
			var val2 = s2.y;

			switch(vRef) {
				case TOP:
				case CENTER:
					val1 += s1.height / 2;
					val2 += s2.height / 2;
				case BOTTOM:
					val1 += s1.height;
					val2 += s2.height;
			}

			return FlxSort.byValues(order, val1, val2);
		}
	}
}