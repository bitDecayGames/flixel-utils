package bitdecay.flixel.temporal;

import flixel.math.FlxMath;

class TimeFormatter {
	/**
	 * Lovingly taken from the FlxStringUtils to handle rounding consistently with NG
	 *
	 * Format seconds as minutes with a colon, an optionally with milliseconds too.
	 *
	 * @param	Seconds		The number of seconds (for example, time remaining, time spent, etc).
	 * @param	ShowMS		Whether to show milliseconds after a "." as well.  Default value is false.
	 * @return	A nicely formatted String, like "1:03".
	 */
	 public static function formatTime(Seconds:Float, ShowMS:Bool = false):String {
		Seconds = roundTime(Seconds);
		var timeString:String = Std.int(Seconds / 60) + ":";
		var timeStringHelper:Int = Std.int(Seconds) % 60;
		if (timeStringHelper < 10) {
			timeString += "0";
		}
		timeString += timeStringHelper;
		if (ShowMS) {
			timeString += ".";

			var ms = (Seconds - Std.int(Seconds)) * 100;
			var rounded = Math.round(ms);
			timeStringHelper = rounded;
			if (timeStringHelper < 10) {
				timeString += "0";
			}
			timeString += timeStringHelper;
		}

		return timeString;
	}

	public static function roundTime(seconds:Float):Float {
		return FlxMath.roundDecimal(seconds, 2);
	}
}