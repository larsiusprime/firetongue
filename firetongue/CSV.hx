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

package firetongue;

/**
 * ...
 * @author Lars Doucet
 */
class CSV 
{
	public var fields:Array<String>;
	public var grid:Array<Array<String>>;
	
	/**
	 * Parses CSV formatted string into a useable data structure
	 * @param	input csv-formatted string
	 * @param	delimeter string that separates cells
	 */
	
	public function new(input:String,delimeter:String=',') 
	{
		if(input != ""){
			var rgx:EReg = ~/,(?=(?:[^\x22]*\x22[^\x22]*\x22)*(?![^\x22]*\x22))/gm;
			// Matches a well formed CSV cell, ie "thing1" or "thing ,, 5" etc
			// "\x22" is the invocation for the double-quote mark.
			// UTF-8 ONLY!!!!
			
			//You can provide your own customer delimeter, but we generally don't recommend it
			if (delimeter != ",") {
				rgx = new EReg(delimeter + '(?=(?:[^\x22]*\x22[^\x22]*\x22)*(?![^\x22]*\x22))',"gm");
			}
			
			// Get all the cells
			var cells:Array<String> = rgx.split(input);
			processCells(cells);
		}
	}
	
	private function processCells(cells:Array<String>):Void{
		var row:Int = 0;
		var col:Int = 0;
		var newline:Bool = false;
		var row_array:Array<String>=null;
		
		grid = new Array<Array<String>>();
		fields = new Array<String>();
		
		for (i in 0...cells.length)
		{
			newline = false;
			
			//If the first character is a line break, we are at a new row
			var firstchar:String = cells[i].substr(0, 2);
				
			if (firstchar == "\n\r" || firstchar == "\r\n") {
				newline = true;
				cells[i] = cells[i].substr(2, cells[i].length - 2);	//strip off the newline
			}else { 
				firstchar = cells[i].substr(0, 1);
				if (firstchar == "\n" || firstchar == "\r") {
					newline = true;
					cells[i] = cells[i].substr(1, cells[i].length - 1);	//strip off the newline
				}
			}
			
			if (newline) {
				if (row_array != null) {
					grid.push(row_array);	//add the built up row array
				}
				row_array = new Array<String>();
				col = 0;
				row++;
			}
			
			var cell:String = "";
			if(_quoted){
				cell = cells[i].substr(1, cells[i].length - 2);
			}else {
				cell = cells[i];
			}
			
			if (row == 0) 
			{
				fields.push(cell);		//get the fields
			}else {
				row_array.push(cell);	//get the row cells
			}
		}
		
		if (row_array != null) {
			grid.push(row_array);
		}
		
		clearArray(cells);
		cells = null;
	}
	
	public function destroy():Void {
		clearArray(grid);
		clearArray(fields);
		grid = null;
		fields = null;
	}
	
	private function clearArray(array:Array<Dynamic>):Void {
		if (array == null) return;
		var i:Int = array.length - 1; while (i >= 0) 
		{
			destroyThing(array[i]);
			array[i] = null;
			array.splice(i, 1);
			i--;
		}array = null;
	}
	
	private function destroyThing(thing:Dynamic):Void {
		if (thing == null) return;
		
		if (Std.is(thing, Array))
		{
			clearArray(thing);
		}
		
		thing = null;
	}
	
	private var _quoted:Bool = true;
}