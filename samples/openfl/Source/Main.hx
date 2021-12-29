/**
 * Copyright (c) 2013 Level Up Labs, LLC
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 * 
 */

package;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.DisplayObject;
import flash.display.SimpleButton;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;
import firetongue.FireTongue;
import firetongue.Replace;
import openfl.Assets;
import openfl.display.Shape;

class Main extends Sprite
{
	private var tongue:FireTongue;
	private var locales:Array<String>;
	private var text:TextField;

	private var nonexistant:String = "ERROR";

	public function new()
	{
		super();
		addEventListener(Event.ADDED_TO_STAGE, onInit, false, 0, true);
	}

	public function onInit(e:Event):Void
	{
		text = new TextField();
		text.width = 800;
		text.height = 400;
		text.y = (600 - text.height) / 2;
		addChild(text);

		// firetongue will try to automatically detect a framework, in this case, OpenFL
		tongue = new FireTongue();
		// tongue = new FireTongue(OPENFL);					// explicitly request OpenFL asset loading (works on native, flash, & HTML5 targets)
		// tongue = new FireTongue(VanillaSys);				// use sys.io.File and sys.Filesystem (works w/ any framework, but not on flash & HTML5 targets)

		tongue.initialize({
			locale: "en-US",
			finishedCallback: onFinish,
			checkMissing: true
		});

		locales = tongue.locales;
		var xx:Float = 0;

		var i:Int = 0;
		var lastx:Float = 0;
		var lasty:Float = 0;
		for (locale in locales)
		{
			var img = Assets.getBitmapData(tongue.getIcon(locale));

			var img2:BitmapData = new BitmapData(img.width * 2, img.height * 2, false, 0xff000000);
			var matrix:Matrix = new Matrix();
			matrix.identity();
			matrix.scale(2, 2);
			img2.draw(img, matrix);

			var up:Bitmap = new Bitmap(img2);
			var img3:BitmapData = img2.clone();
			img3.draw(img2, null, new ColorTransform(1, 1, 1, 1, 64, 64, 64, 0));
			var over:Bitmap = new Bitmap(img3);
			var down:Bitmap = new Bitmap(img2);

			var mb = new MyButton(up, over, down);

			mb.y = 4;
			mb.x = xx + 4;
			xx += (mb.width + 4);

			mb.name = "Locale" + i;

			addChild(mb);
			mb.addEventListener(MouseEvent.CLICK, onClick);
			i++;

			lastx = mb.x + mb.width + 4;
			lasty = mb.y;
		}

		var xgraphic:Shape = new Shape();
		xgraphic.graphics.beginFill(0xFF0000);
		xgraphic.graphics.drawRect(0, 0, 80, 32);
		xgraphic.graphics.lineStyle(3, 0x000000);
		xgraphic.graphics.moveTo(0, 0);
		xgraphic.graphics.lineTo(80, 32);
		xgraphic.graphics.moveTo(80, 0);
		xgraphic.graphics.lineTo(0, 32);

		var xgraphic2:Shape = new Shape();
		xgraphic2.graphics.beginFill(0xFF8080);
		xgraphic2.graphics.drawRect(0, 0, 80, 32);
		xgraphic2.graphics.lineStyle(3, 0x808080);
		xgraphic2.graphics.moveTo(0, 0);
		xgraphic2.graphics.lineTo(80, 32);
		xgraphic2.graphics.moveTo(80, 0);
		xgraphic2.graphics.lineTo(0, 32);

		var mb2 = new MyButton(xgraphic, xgraphic2, null);
		addChild(mb2);
		mb2.x = lastx;
		mb2.y = lasty;
		mb2.addEventListener(MouseEvent.CLICK, onClick2);
	}

	private function onClick2(e:MouseEvent):Void
	{
		tongue.init({
			locale: nonexistant,
			finishedCallback: onFinish2,
			checkMissing: true
		});
	}

	private function onClick(e:MouseEvent):Void
	{
		var i = Std.parseInt(cast(e.currentTarget, Sprite).name.charAt(6));
		var locale:String = "";
		if (i >= 0 && i < locales.length)
		{
			locale = locales[i];
			tongue.init({
				locale: locale,
				finishedCallback: onFinish,
				checkMissing: true
			});
		}
	}

	private function onFinish2():Void
	{
		onFinish();
		text.text = "Could not find locale \"" + nonexistant + "\", closest match was:\n" + text.text;
	}

	private function onFinish():Void
	{
		var context = "data";

		text.text = tongue.locale + "\n";
		text.text += tongue.get("$INSTRUCTIONS", context) + "\n\n";
		text.text += tongue.get("$HELLO_WORLD", context) + "\n";
		text.text += tongue.get("$TEST_STRING", context) + "\n";

		if (tongue.missingFiles != null)
		{
			var str:String = tongue.get("$missingFiles", context);
			str = Replace.flags(str, ["<X>"], [Std.string(tongue.missingFiles.length)]);
			text.text += str + "\n";
			for (file in tongue.missingFiles)
			{
				text.text += "    " + file + "\n";
			}
		}

		if (tongue.missingFlags != null)
		{
			var missingFlags = tongue.missingFlags;

			var miss_str:String = tongue.get("$missingFlags", context);

			var count:Int = 0;
			var flag_str:String = "";

			for (key in missingFlags.keys())
			{
				var list:Array<String> = missingFlags.get(key);
				count += list.length;
				for (flag in list)
				{
					flag_str += "    Context(" + key + "): " + flag + "\n";
				}
			}

			miss_str = Replace.flags(miss_str, ["<X>"], [Std.string(count)]);
			text.text += miss_str + "\n";
			text.text += flag_str + "\n";
		}
	}
}
