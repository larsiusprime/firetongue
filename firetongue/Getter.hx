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

import firetongue.FireTongue.Framework;
#if (lime >= "7.0.0")
import lime.utils.Assets as LimeAssets;
#elseif (lime && !lime_legacy)
import lime.Assets as LimeAssets;
#end

/**
 * ...
 * @author 
 */
class Getter
{
	private var framework:Framework;
	private var checkFile_Custom:String->Bool;
	private var getText_Custom:String->String;
	private var getDirectoryContents_Custom:String->Array<String>;
	
	public function new(?framework_:Framework, checkFile_:String->Bool, getText_:String->String=null, getDirectoryContents_:String->Array<String>=null) 
	{
		if (framework_ == null)
		{
			#if nme
				framework = NME;
			#elseif (openfl || openfl_legacy)
				framework = OpenFL;
			#elseif lime
				framework = Lime;
			#elseif sys
				framework = VanillaSys;
			#else
				framework = Custom;
			#end
		}
		else {
			framework = framework_;
		}
		
		checkFile_Custom = checkFile_;
		getText_Custom = getText_;
		getDirectoryContents_Custom = getDirectoryContents_;
	}
	
	public function destroy()
	{
		checkFile_Custom = null;
		getText_Custom = null;
		getDirectoryContents_Custom = null;
	}
	
	public function checkFile(filename:String):Bool
	{
		if (checkFile_Custom != null)
		{
			return checkFile_Custom(filename);
		}
		return switch(framework)
		{
			case OpenFL:       checkFile_OpenFL(filename);
			case Lime:         checkFile_Lime(filename);
			case NME:          checkFile_NME(filename);
			case VanillaSys:   checkFile_VanillaSys(filename);
			default: false;
		}
	}
	
	public function getText(filename:String):String
	{
		if (getText_Custom != null)
		{
			return getText_Custom(filename);
		}
		return switch(framework)
		{
			case OpenFL:       getText_OpenFL(filename);
			case Lime:         getText_Lime(filename);
			case NME:          getText_NME(filename);
			case VanillaSys:   getText_VanillaSys(filename);
			default: null;
		}
	}
	
	public function getDirectoryContents(path:String):Array<String>
	{
		if (getDirectoryContents_Custom != null)
		{
			return getDirectoryContents_Custom(path);
		}
		return switch(framework)
		{
			case OpenFL:       getDirectoryContents_OpenFL(path);
			case Lime:         getDirectoryContents_Lime(path);
			case NME:          getDirectoryContents_NME(path);
			case VanillaSys:   getDirectoryContents_VanillaSys(path);
			default: [];
		}
	}
	
	/*******OpenFL*******/
	
	public function getDirectoryContents_OpenFL(path):Array<String>
	{
		#if (!nme && (openfl || openfl_legacy))
			return limitPath(openfl.Assets.list(TEXT), path);
		#else
			return null;
		#end
	}
	
	public function getText_OpenFL(filename:String):String
	{
		#if (openfl || openfl_legacy)
			return openfl.Assets.getText(filename);
		#else
			return null;
		#end
	}
	
	public function checkFile_OpenFL(filename:String):Bool
	{
		#if (openfl || openfl_legacy)
			return openfl.Assets.exists(filename);
		#else
			return false;
		#end
	}
	
	/*******Lime*******/
	
	public function getDirectoryContents_Lime(path):Array<String>
	{
		#if (lime && !lime_legacy)
			return limitPath(LimeAssets.list(TEXT), path);
		#else
			return null;
		#end
	}
	
	public function getText_Lime(filename:String):String
	{
		#if (lime && !lime_legacy)
			return LimeAssets.getText(filename);
		#else
			return null;
		#end
	}
	
	public function checkFile_Lime(filename:String):Bool
	{
		#if (lime && !lime_legacy)
			return LimeAssets.exists(filename);
		#else
			return false;
		#end
	}
	
	/*******NME*******/
	
	public function getDirectoryContents_NME(path):Array<String>
	{
		#if nme
			return limitPath([for (x in nme.Assets.list(TEXT)) x], path);
		#else
			return null;
		#end
	}
	
	public function getText_NME(filename:String):String
	{
		#if nme
			return nme.Assets.getText(filename);
		#else
			return null;
		#end
	}
	
	public function checkFile_NME(filename:String):Bool
	{
		#if nme
			return nme.Assets.exists(filename);
		#else
			return false;
		#end
	}
	
	/*******VanillaSys******/
	
	public function getDirectoryContents_VanillaSys(path:String):Array<String>
	{
		#if sys
			if (sys.FileSystem.exists(path))
			{
				return sys.FileSystem.readDirectory(path);
			}
		#end
		return null;
	}
	
	public function getText_VanillaSys(filename:String):String
	{
		#if sys
			if (sys.FileSystem.exists(filename))
			{
				return sys.io.File.getContent(filename);
			}
		#end
		return null;
	}
	
	public function checkFile_VanillaSys(filename:String):Bool
	{
		#if sys
			return sys.FileSystem.exists(filename);
		#else
			return false;
		#end
	}
	
	/*******PRIVATE*******/
	
	
	private function limitPath(arr:Array<String>, path:String):Array<String>
	{
		var arr2 = [];
		
		path = StringTools.replace(path, "\\", "/");
		
		for (str in arr)
		{
			str = StringTools.replace(str, "\\", "/");
			
			if (str.indexOf(path) == 0)
			{
				arr2.push(str);
			}
		}
		
		return arr2;
	}
}
