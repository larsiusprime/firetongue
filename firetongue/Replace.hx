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

import flash.display.Sprite;

class Replace
{
	/**
	 * Simple class to do variable replacements for localization
	 * 
	 * USAGE:
		 * var str:String = fire_tongue.get("$GOT_X_GOLD"); //str now = "You got <X> gold coins!"
		 * str = Replace.flags(str,["<X>"],[num_coins]);	//num_coins = "10"
		 * 
		 * //str now = "You got 10 gold coins!"
	 * 
	 * This method is preferably to schemes that do this:
	 * (str = "You got" + num_coins + " gold coins!")
	 *  
	 * Even if you translate the sentence fragments, each language has
	 * its own unique word order and sentence structure, so trying to embed
	 * that in code is a lost cuase. It's better to just let the translator 
	 * specify where the variable should fall, and replace it accordingly. 
	 */
	
	public function new ()
	{
		//does nothing
	}
	
	/**
	 * Replace all of the given flags found in the string with corresponding values
	 * @param	string	the string to process
	 * @param	flags	the flags we want to find in the string
	 * @param	values	the values to replace those flags with
	 * @return
	 */
	public static function flags(string:String, flags:Array<String>, values:Array<String>):String
	{
		var j:Int = 0;
		while (j < flags.length)
		{
			var flag = flags[j];
			var value = values[j];
			while (string.indexOf(flag) != -1)
			{
				string = StringTools.replace(string, flag, value);
			}
			j++;
		}
		return string;
	}
}