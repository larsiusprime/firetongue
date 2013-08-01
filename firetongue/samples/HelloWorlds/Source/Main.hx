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

class Main extends Sprite {

	private var tongue:FireTongue;
	private var locales:Array<String>;
	private var text:TextField;
	
	public function new () {		
		super ();
		addEventListener(Event.ADDED_TO_STAGE, onInit, false, 0, true);	
	}
	
	public function onInit(e:Event):Void {
		text = new TextField();
		text.width = 800;
		text.y = (600 - text.height) / 2;
		addChild(text);
		
		tongue = new FireTongue();
		tongue.init("en-US", onFinish);			
				
		locales = tongue.locales;
		var xx:Float = 0;
		
		var i:Int = 0;
		for (locale in locales) {
			var img = tongue.getIcon(locale);
			
			var img2:BitmapData = new BitmapData(img.width * 3, img.height * 3, false, 0xff000000);
			var matrix:Matrix = new Matrix();
			matrix.identity();
			matrix.scale(3, 3);
			img2.draw(img, matrix);
			
			var up:Bitmap = new Bitmap(img2);						
			var img3:BitmapData = img2.clone();
			img3.draw(img2, null, new ColorTransform(1, 1, 1, 1, 64, 64, 64, 0));
			var over:Bitmap = new Bitmap(img3);
			var down:Bitmap = new Bitmap(img2);
			var hit:Bitmap = new Bitmap(img2);
			
			var sb:SimpleButton = new SimpleButton(up, over, down, hit);
						
			sb.y = 4;
			sb.x = xx + 4;
			xx += (sb.width + 4);
						
			addChild(sb);			
			
			sb.addEventListener(MouseEvent.CLICK, Reflect.field(this,"onClick"+i));
			i++;
		}
	}
	
	private function onClick0(e:MouseEvent):Void {onClick(0);}
	private function onClick1(e:MouseEvent):Void {onClick(1);}
	private function onClick2(e:MouseEvent):Void {onClick(2);}
	private function onClick3(e:MouseEvent):Void {onClick(3);}
	
	private function onClick(i:Int):Void {		
		trace("onClick(" + i + ")");
		var locale:String = "";
		if (i >= 0 && i < locales.length) {
			locale = locales[i];
			tongue.init(locale, onFinish);
		}	
	}
	
	private function onFinish():Void {
		text.text  = tongue.get("$HELLO_WORLD") + "\n";
		text.text += tongue.get("$TEST_STRING");
	}	
}