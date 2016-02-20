package firetongue;

import firetongue.FireTongue.Framework;

/**
 * ...
 * @author 
 */
class Getter
{
	private var framework:Framework;
	private var checkFile_Other:String->Bool;
	private var getText_Other:String->String;
	private var getDirectoryContents_Other:String->Array<String>;
	
	public function new(?framework_:Framework, checkFile:String->Bool, getText:String->String=null, getDirectoryContents:String->Array<String>=null) 
	{
		if (framework_ == null)
		{
			#if sys
				framework = VanillaSys;
			#elseif openfl
				framework = OpenFL;
			#elseif lime
				framework = Lime;
			#else
				framework = Other;
			#end
		}
		
		checkFile_Other = checkFile;
		getText_Other = getText;
		getDirectoryContents_Other = getDirectoryContents;
	}
	
	public function destroy()
	{
		getText_Other = null;
		getDirectoryContents_Other = null;
	}
	
	public function checkFile(filename:String):Bool
	{
		return switch(framework)
		{
			case Lime:       checkFile_Lime(filename);
			case OpenFL:     checkFile_OpenFL(filename);
			case VanillaSys: checkFile_VanillaSys(filename);
			case Other:      checkFile_Other != null ? checkFile_Other(filename) : false;
			default: false;
		}
	}
	
	public function getText(filename:String):String
	{
		return switch(framework)
		{
			case Lime:       getText_Lime(filename);
			case OpenFL:     getText_OpenFL(filename);
			case VanillaSys: getText_VanillaSys(filename);
			case Other:      getText_Other != null ? getText_Other(filename) : null;
			default: null;
		}
	}
	
	public function getDirectoryContents(path:String):Array<String>
	{
		trace("getDirectoryContents(" + path+")");
		return switch(framework)
		{
			case Lime:       getDirectoryContents_Lime(path);
			case OpenFL:     getDirectoryContents_OpenFL(path);
			case VanillaSys: getDirectoryContents_VanillaSys(path);
			case Other:      getDirectoryContents_Other != null ? getDirectoryContents_Other(path) : [];
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
	
	/*******OpenFL*******/
	
	public function getDirectoryContents_OpenFL(path:String):Array<String>
	{
		#if openfl
			return limitPath(openfl.Assets.list(TEXT), path);
		#else
			return null;
		#end
	}
	
	public function getText_OpenFL(filename:String):String
	{
		#if openfl
			return openfl.Assets.getText(filename);
		#else
			return null;
		#end
	}
	
	public function checkFile_OpenFL(filename:String):Bool
	{
		#if lime
			return openfl.Assets.exists(filename);
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