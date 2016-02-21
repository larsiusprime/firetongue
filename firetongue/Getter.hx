package firetongue;

import firetongue.FireTongue.Framework;

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
			#if openfl
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
			case Lime, OpenFL: checkFile_Lime(filename);
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
			case Lime, OpenFL: getText_Lime(filename);
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
			case Lime, OpenFL: getDirectoryContents_Lime(path);
			case VanillaSys:   getDirectoryContents_VanillaSys(path);
			default: [];
		}
	}
	
	/*******Lime*******/
	
	public function getDirectoryContents_Lime(path):Array<String>
	{
		#if lime
			return limitPath(lime.Assets.list(TEXT), path);
		#else
			return null;
		#end
	}
	
	public function getText_Lime(filename:String):String
	{
		#if lime
			return lime.Assets.getText(filename);
		#else
			return null;
		#end
	}
	
	public function checkFile_Lime(filename:String):Bool
	{
		#if lime
			return lime.Assets.exists(filename);
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