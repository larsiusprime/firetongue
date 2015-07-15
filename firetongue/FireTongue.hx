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

import firetongue.FireTongue.LoadTask;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Loader;
import flash.errors.Error;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import flash.net.URLLoader;
import flash.net.URLLoaderDataFormat;
import flash.net.URLRequest;
import haxe.xml.Fast;
import openfl.Assets;
#if (cpp || neko)
	import sys.FileSystem;
	import sys.io.File;
#end

/**
 * FireTongue is a Haxe port of the localization framework used in Defender's Quest. 
 *
 * Provide all your data in a localization folder in the correct format, and then
 * FireTongue will parse it and make it available to you at runtime.
 *
 * Usage:
 *
 * //somewhere in your code: 
 * tongue = new FireTongue();
 * tongue.init("en-US",onFinish);
 *
 * function onFinish():Void
 * {
 *    trace(tongue.get("$HELLO_WORLD"));
 * }
 *
 * @author Lars Doucet
 */


/*
 * TO TEST:
 * If files are missing, optionally load them from the default locale
 * Provide a list of missing files and flags when compared to the default locale
 * Handle loading an active mod's localization data separately from the core game
 * (perhaps the user should just make two FireTongue instances for this)
 */

class FireTongue
{
	public static var default_locale:String = "en-US";					//locale to fall back on if needed
	public var isLoaded(default, null):Bool;							//has this been loaded yet
	public var locale(default, null):String;							//the current locale, ie, "en-US"
	public var locales(get, null):Array<String>;						//list of all the locales available
	public var missing_files(default, null):Array<String>;				//filled during initialization if files are missing
	public var missing_flags(default, null):Map<String,Array<String>>;	//filled during initialization if flags are missing
	
	public function new() 
	{
		//does nothing
	}
	
	/**
	 * Clear all the current localization data. 
	 * @param	hard Also clear all the index-related data, restoring it to a pre-initialized state.
	 */
	
	public function clear(hard:Bool):Void
	{
		clearData(hard);
	}
	
	/**
	 * Initialize the localization structure
	 * @param	locale_ desired locale string, ie, "en-US"
	 * @param	finished_ callback for when it's done loading stuff
	 * @param	check_missing_ if true, compares against default locale for missing files/flags
	 * @param	replace_missing_ if true, replaces any missing files & flags with default locale values
	 * @param	asynchLoadMethod_ a method for loading the files asynchronously (optional)
	 * @param	directory_ alternate directory to look for locale (optional). Otherwise, is "assets/"
	 */
	
	public function init(locale_:String, finished_:Dynamic = null, check_missing_:Bool = false, replace_missing_:Bool = false, ?asynchLoadMethod_:Array<LoadTask>->Void, ?directory_:String = ""):Void
	{
		#if debug
			trace("LocaleData.init(" + locale_ + "," + finished_ + "," + check_missing_ + "," + replace_missing_ +"," +directory_+")");
		#end
		
		locale = localeFormat(locale_);
		_directory = directory_;
		
		if (isLoaded)
		{
			clearData();	//if we have an existing locale already loaded, clear it out first
		}
		
		_callback_finished = finished_;
		
		_check_missing = false;
		_replace_missing = false;
		
		if (locale != default_locale)
		{
			_check_missing = check_missing_;
			_replace_missing = replace_missing_;
		}
		
		if (_check_missing)
		{
			missing_files = new Array<String>();
			missing_flags = new Map<String,Array<String>>();
		}
		
		startLoad();
	}
	
	/**
	 * Provide a localization flag to get the proper text in the current locale.
	 * @param	flag a flag string, like "$HELLO"
	 * @param	context a string specifying which index, in case you want that
	 * @param	safe if true, suppresses errors and returns the untranslated flag if not found
	 * @return  the translated string
	 */
	
	public function get(flag:String, context:String = "data", safe:Bool = true):String
	{
		var orig_flag:String = flag;
		flag = flag.toUpperCase();
		
		if (context == "index")
		{
			return getIndexString(flag);
		}
		
		var index:Map<String,String>;
		index = _index_data.get(context);
		if (index == null)
		{
			if (!safe)
			{
				throw new Error("no localization context \"+data+\"");
			}
			else
			{
				return flag;
			}
		}
		
		var str:String = "";
		try
		{
			str = index.get(flag);
			
			if (str != null && str != "")
			{
				//Replace standard stuff:
				
				if (str.indexOf("<RE>") == 0)					//it's a redirect
				{
					var done:Bool = false;
					var failsafe:Int = 0;
					str = StringTools.replace(str, "<RE>", "");	//cut out the redirect
					while (!done)
					{
						var new_str:String = index.get(str);	//look it up again
						if (new_str != null && new_str != "") 	//string exists
						{
							str = new_str;
							if (str.indexOf("<RE>") != 0)			//if it's not ANOTHER redirect, stop looking
							{
								done = true;
							}
							else
							{
								//another redirect, keep looking
								str = StringTools.replace(str, "<RE>", "");
							}
						}
						else										//give up
						{
							done = true;
							str = new_str;
						}
						failsafe++;
						if (failsafe > 100)							//max recursion: 100
						{
							done = true;
							str = new_str;
						}
					}
				}
				
				if (str.indexOf("<RE>[") != -1)			//it's a redirect in the middle of the flag with bracket notation
				{
					var done:Bool = false;
					var failsafe:Int = 0;
					while (!done)
					{
						var start:Int = str.indexOf("<RE>[");
						var end:Int = str.lastIndexOf("]");
						if (start != 1 && end != -1)				//redirection exists
						{
							var new_str = str.substring(start + 5, end);	//cut off the redirection and the brackets
							new_str = index.get(new_str);						//look it up again
							if (new_str == null || new_str == "")		//give up
							{
								done = true;
							}
							else if (new_str.indexOf("<RE>[") == -1)	//another redirect, keep going
							{
								done = true;
							}
							str = new_str;
						}
						failsafe++;
						if (failsafe > 100)		//max recursion: 100
						{
							done = true;
						}
					}
				}
				
				var fix_a:Array<String> = ["<N>","<T>","<LQ>","<RQ>","<C>","<Q>"];
				var fix_b:Array<String> = ["\n","\t","“","”",",",'"'];
				
				if (str != null && str != "") {
					for (i in 0...fix_a.length) {
						while (str.indexOf(fix_a[i]) != -1) {
							str = StringTools.replace(str, fix_a[i], fix_b[i]);
						}
					}
				}
			}
		}
		catch (e:Error)
		{
			if (safe)
			{
				return orig_flag;
			}
			else 
			{
				throw new Error("LocaleData.getText(" + flag + "," + context + ")");
			}
		}
		
		index = null;
		
		if (str == null)
		{
			if (safe)
			{
				return orig_flag;
			}
		}
		
		return str;
	}
	/**
	 * Get a font name, honoring locale replacement rules
	 * @param	str
	 * @return
	 */
	
	public function getFont(str:String):String
	{
		var replace:String = "";
		try
		{
			var xml:Fast = _index_font.get(str);
			if (xml != null && xml.hasNode.font)
			{
				replace = xml.node.font.att.replace;
			}
			if (replace == "" || replace == null)
			{
				replace = str;
			}
		}
		catch (e:Error)
		{
			replace = str;
		}
		return replace;
	}
	
	public function getFontSize(str:String, size:Int):Int
	{
		var replace:Int = size;
		try
		{
			var xml:Fast = _index_font.get(str);
			if (xml != null && xml.hasNode.font && xml.node.font.hasNode.size)
			{
				for (sizeNode in xml.node.font.nodes.size)
				{
					var sizestr:String = Std.string(size);
					if (sizeNode.att.value == sizestr)
					{
						var replacestr:String = sizeNode.att.replace;
						if (replacestr != "" && replacestr != null)
						{
							replace = Std.parseInt(replacestr);
							if (replace == 0)
							{
								replace = size;
							}
						}
						
					}
				}
			}
		}
		catch (e:Error)
		{
			replace = size;
		}
		return replace;
	}
	
	/**
	 * Get a locale (flag) icon
	 * @param	locale_id
	 * @return
	 */
	
	public function getIcon(locale_id:String):BitmapData
	{
		return _index_icons.get(locale_id);
	}
	
	public function getIndexString(flag:String):String
	{
		var str:String = "";
		
		var arr:Array<String> = null;
		if (flag.indexOf(":") != 0) {
			arr = flag.split(":");
			if (arr != null && arr.length == 2) {
				var target_locale:String = localeFormat(arr[1]);
				var index_flag:String = arr[0];
				
				//get the locale entry for the target locale from the index
				var lindex:Fast = _index_locales.get(target_locale);
				
				var currLangNode:Fast = null;
				var nativeNode:Fast = null;
				
				if (lindex.hasNode.label) {
					for (lNode in lindex.nodes.label) {			//look through each label
						if (lNode.has.id) {
							var lnid:String = lNode.att.id;
							if (lnid.indexOf(locale) != -1) {	//if it matches the CURRENT locale
								currLangNode = lNode;			//labels in CURRENT language
							}
							if (lnid.indexOf(target_locale) != -1) {	//if it matches its own NATIVE locale
								nativeNode = lNode;						//labels in NATIVE language
							}
							if (currLangNode != null && nativeNode != null) {
								break;	
							}
						}
					}
				}	
				
				switch(index_flag) {
				case "$UI_LANGUAGE":	//return the localized word "LANGUAGE"
					if (nativeNode.hasNode.ui && nativeNode.node.ui.has.language) {
						return currLangNode.node.ui.att.language;
					}
				case "$UI_REGION":		//return the localized word "REGION"
					if (nativeNode.hasNode.ui && nativeNode.node.ui.has.region) {
						return currLangNode.node.ui.att.region;
					}
				case "$LANGUAGE":		//return the name of this language in CURRENT language
					if (currLangNode != null && currLangNode.has.language) {
						return currLangNode.att.language;
					}
				case "$LANGUAGE_NATIVE"://return the name of this language in NATIVE language
					if (nativeNode != null && nativeNode.has.language) {
						return nativeNode.att.language;
					}
				case "$REGION":			//return the name of this region in CURRENT language
					if (currLangNode != null && nativeNode.has.region) {
						return currLangNode.att.region;
					}
				case "$REGION_NATIVE":	//return the name of this region in NATIVE language
					if (nativeNode != null && nativeNode.has.region) {
						return nativeNode.att.region;
					}
				case "$LANGUAGE_BILINGUAL": //return the name of this language in both CURRENT and NATIVE, if different
					var lang:String = "";
					var langnative:String = "";
					if (nativeNode != null && nativeNode.has.language) {
						langnative = nativeNode.att.language;
					}							
					if (currLangNode != null && currLangNode.has.language) {
						lang = currLangNode.att.language;
					}
					if (lang == langnative) {
						return lang;
					}else{
						return lang + " (" + langnative + ")";
					}
				case "$LANGUAGE(REGION)":	//return something like "Inglés (Estados Unidos)" in CURRENT language (ex: curr=spanish native=english)
					var lang:String = getIndexString("$LANGUAGE:"+target_locale);
					var reg:String = getIndexString("$REGION:" + target_locale);
					return lang + "(" + reg + ")";
				case "$LANGUAGE(REGION)_NATIVE": //return something like "English (United States)" in NATIVE language (ex: curr=spanish native=english)
					var lang:String = getIndexString("$LANGUAGE_NATIVE:"+target_locale);
					var reg:String = getIndexString("$REGION_NATIVE:" + target_locale);
					return lang + "(" + reg + ")";
				}
			}
		}
		
		return flag;
	}
	
	/**
	 * Get the body of a localization note (locale menu purposes)
	 * @param	locale
	 * @param	id
	 * @return
	 */
	
	public function getNoteBody(locale:String, id:String):String
	{
		try
		{
			var str:String = _index_notes[id + "_" + locale + "_body"];
			return Replace.flags(str, ["$N"], ["\n"]);
		}
		catch (e:String)
		{
			return "ERROR:("+id+") for (" + locale + ") body not found";
		}
		return "";
	}
	
	/**
	 * Get the title of a localization note (locale menu purposes)
	 * @param	locale
	 * @param	id
	 * @return
	 */
	
	public function getNoteTitle(locale:String, id:String):String
	{
		try
		{
			var str:String = _index_notes[id + "_" + locale + "_title"];
			return Replace.flags(str, ["$N"], ["\n"]);
		}
		catch (e:String)
		{
			return "ERROR:("+id+") for (" + locale + ") title not found";
		}
		return "";
	}
	
	/******PRIVATE******/
	
	//All of the game's localization data
	private var _index_data:Map < String, Map < String, String >> ;
	
	//All of the locale entries
	private var _index_locales:Map<String,Fast>;
	
	//All of the text notations
	private var _index_notes:Map<String,String>;
	
	//All of the icons from various languages
	private var _index_icons:Map<String,BitmapData>;
	
	//Any custom images loaded
	private var _index_images:Map<String,BitmapData>;
	
	//Font replacement rules
	private var _index_font:Map<String,Fast>;
	
	private var _callback_finished:Dynamic;
	
	private var _list_files:Array<Fast>;
	private var _files_loaded:Int = 0;
	
	private var _safety_bit:Int = 0;
	
	private var _check_missing:Bool = false;
	private var _replace_missing:Bool = false;
	
	private var _directory:String = "";
	
	private function clearBitmapDataMap(map:Map<String, BitmapData>):Void
	{
		clearMap(map, function (bitmapData:BitmapData)
		{
			if (bitmapData != null) bitmapData.dispose();
		});
	}
	
	/**
	 * Clear all the current localization data. 
	 * @param	hard Also clear all the index-related data, restoring it to a pre-initialized state.
	 */
	
	private function clearData(hard:Bool = false):Void
	{
		_callback_finished = null;
		
		if (_list_files != null)
		{
			while (_list_files.length > 0)
			{
				_list_files.pop();
			}
			_list_files = null;
		}
		
		isLoaded = false;
		_files_loaded = 0;
		
		for (sub_key in _index_data.keys()) 
		{
			var sub_index:Map<String,Dynamic> = _index_data.get(sub_key);
			_index_data.remove(sub_key);
			clearMap(sub_index);
			sub_index = null;
		}
		
		clearBitmapDataMap(_index_images);
		clearMap(_index_font);
		
		_index_images = null;
		_index_font = null;
		
		if (hard)
		{
			clearMap(_index_locales);
			clearBitmapDataMap(_index_icons);
			clearMap(_index_notes);
			_index_locales = null;
			_index_icons = null;
			_index_notes = null;
		}
		
		clearMap(missing_flags);
		if (missing_files != null)
		{
			while (missing_files.length > 0)
			{
				missing_files.pop();
			}
		}
		
		missing_files = null;
		missing_flags = null;
	}
	
	private function clearMap<T1, T2>(map:Map<T1, T2>, ?onRemove:T2->Void):Void
	{
		if (map == null) return;
		
		for (key in map.keys())
		{
			var element = map.get(key);
			if (onRemove != null)
			{
				onRemove(element);
			}
			map.remove(key);
		}
	}
	
	/**
	 * Just a quick way to deep-copy a Fast object
	 * @param	fast
	 * @return
	 */
	
	private inline function copyFast(fast:Fast):Fast {
		return new Fast(Xml.parse(fast.x.toString()));
	}
	
	private function doTasks(tasks:Array<LoadTask>):Void
	{
		for (i in 0...tasks.length)
		{
			var t:LoadTask = tasks[i];
			loadFile(t.fileNode, t.check);
			onLoadFile();
		}
	}
	
	private function findClosestExistingLocale(localeStr:String,testFile:String):String
	{
		var paths:Array<String> = null;
		var dirpath:String = "";
		var bestLocale:String = "";
		var bestDiff:Float = Math.POSITIVE_INFINITY;
		#if (cpp || neko)
		dirpath = "assets/locales";
		#elseif flash
		dirpath = "assets/locales/";
		#end
		
		#if debug
		trace("--> looking in: " + dirpath);
		#end
		
		paths = getDirectoryContents(dirpath);
		
		var localeCandidates:Array<String> = [];
		
		for (str in paths) {
			str = StringTools.replace(str, dirpath, "");
			var newLocale:String = "";
			#if flash
			if (str.indexOf("/") != -1) {
				newLocale = str.substr(0, str.indexOf("/"));
			}
			#elseif(cpp || neko)
			newLocale = str;
			#end
			if(newLocale.indexOf("_") != 0 && newLocale.indexOf(".") == -1){
				if (localeCandidates.indexOf(newLocale) == -1)
				{
					localeCandidates.push(newLocale);
				}
			}
		}
		
		#if debug
		trace("--> candidates: " + localeCandidates);
		#end
		
		bestLocale = localeStr;
		bestDiff = Math.POSITIVE_INFINITY;
		
		for (loc in localeCandidates) {
			var diff:Int = stringDiff(localeStr, loc, false);
			if (diff < bestDiff) {
				bestDiff = diff;
				bestLocale = loc;
			}
		}
		
		return bestLocale;
	}
	
	private function get_locales():Array<String>
	{
		var arr:Array<String> = [];
		for (key in _index_locales.keys())
		{
			arr.push(key);
		}
		return arr;
	}
	
	private function getDirectoryContents(str):Array<String>
	{
		#if (cpp || neko)
			return FileSystem.readDirectory(_directory + str);
		#else
			var arr:Array<String> = [];
			var libraryArr:Array<String> = null;
			#if (openfl >= "2.0.0") 
				libraryArr = Assets.list(TEXT);
			#else
				var defaultLibrary:AssetLibrary = Assets.libraries.get("default");
				if (defaultLibrary != null)
				{
					libraryArr = defaultLibrary.list(TEXT)
				}
			#end
			if (libraryArr != null) {
				for (str in libraryArr)
				{
					arr.push(str);
				}
			}
			return arr;
		#end
	}
	
	/**
	 * Loads a file and processes its contents in the data structure
	 * @param	fileData <file> node entry from index.xml
	 * @param	check_vs_default if true, will use to do safety check rather than immediately store the data
	 * @return
	 */
	
	private function loadFile(fileData:Fast, check_vs_default:Bool = false):String
	{
		var fileName:String = fileData.node.file.att.value;
		var fileType:String = fileName.substr(fileName.length - 3, 3);
		var fileID:String = fileData.node.file.att.id;
		
		var raw_data:String = "";
		
		var loc:String = locale;
		if (check_vs_default)
		{
			loc = default_locale;
		}
		
		switch(fileType)
		{
		case "txt","tsv":
			var raw_data = loadText(loc + "/" + fileName);
			if (raw_data != "" && raw_data != null)
			{
				var tsv:TSV = new TSV(raw_data);
				processCSV(tsv, fileID, check_vs_default);
			}
			else if (_check_missing)
			{
				logMissingFile(fileName);
			}
		case "csv":
			var raw_data = loadText(loc + "/" + fileName);
			var delimeter:String = ",";
			if (fileData.node.file.has.delimeter)
			{
				delimeter = fileData.node.file.att.delimeter;
			}
			if (raw_data != "" && raw_data != null)
			{
				var csv:CSV = new CSV(raw_data, delimeter);
				processCSV(csv, fileID, check_vs_default);
			}
			else if (_check_missing)
			{
				logMissingFile(fileName);
			}
		case "xml":
			if(!check_vs_default){	//xml (ie font rules) don't need safety checks
				var raw_data = loadText(loc + "/" + fileName);
				var xml:Fast = new Fast(Xml.parse(raw_data));
				if (raw_data != "" && raw_data != null)
				{
					processXML(xml, fileID);
				}
				else if (_check_missing)
				{
					logMissingFile(fileName);
				}
			}
		case "png":
			var bmp_data = loadImage(loc + "/" + fileName);
			if (bmp_data != null)
			{
				processPNG(bmp_data, fileID, check_vs_default);
			}
			else if (_check_missing)
			{
				logMissingFile(fileName);
			}
		}
		return fileName;
	}
	
	private function loadImage(fname:String):BitmapData{
		var img:BitmapData = null; 
		try
		{
			if (_directory == "")
			{
				img = Assets.getBitmapData("assets/locales/" + fname);
			}else {
				#if (cpp || neko)
				if (FileSystem.exists(_directory + "locales/" + fname))
				{
					#if (lime_legacy || hybrid)
						img = BitmapData.load(_directory + "locales/" + fname);
					#else
						img = BitmapData.fromFile(_directory + "locales/" + fname);
					#end
				}
				#end
			}	
		}
		catch (e:Error)
		{
			#if debug
			trace("ERROR: loadImage(" + fname + ") failed");
			#end
			if (_check_missing)
			{
				logMissingFile(fname);
			}
		}
		return img;
	}
	
	/**
	 * Loads and processes the index file
	 */
	
	private function loadIndex():Void
	{
		var index:String = loadText("index.xml");
		var xml:Fast = null;
		
		_list_files = new Array<Fast>();
		
		if (index == "" || index == null) {
			throw new Error("Couldn't load index.xml!");
		}else {
			xml = new Fast(Xml.parse(index));
			
			//Create a list of file metadata from the list in the index
			if(xml.hasNode.data && xml.node.data.hasNode.file){
				for (fileNode in xml.node.data.nodes.file) {
					_list_files.push(copyFast(fileNode));
				}
			}
		}
		
		if (_index_locales == null) {
			_index_locales = new Map<String,Fast>();
		}
		if (_index_notes == null) {
			_index_notes = new Map<String,String>();
		}			
		if (_index_icons == null) {
			_index_icons = new Map<String,BitmapData>();
		}
		if (_index_images == null) {
			_index_images = new Map<String,BitmapData>();
		}
		
		var id:String = "";
		
		for (localeNode in xml.node.data.nodes.locale) {
			id = localeNode.att.id;
			_index_locales.set(id, localeNode);
			
			//load & store the flag image
			var flag:BitmapData = loadImage("_flags/" + id + ".png");
			_index_icons.set(id, flag); 
			
			
			var isDefault:Bool = localeNode.has.is_default && localeNode.att.is_default == "true";
			if (isDefault) {
				default_locale = id;
			}
		}
		
		//If default locale is not defined yet, make it American English
		if (default_locale == "") {
			default_locale = "en-US";
		}
		
		//If the current locale is not defined yet, make it the default
		if (locale == "") {
			locale = default_locale;
		}
		
		//Load and store all the translation notes
		for (noteNode in xml.node.data.nodes.note) {
			id = noteNode.att.id;
			for (textNode in noteNode.nodes.text) {
				var lid:String = textNode.att.id;
				var larr:Array<String> = null;
				if (lid.indexOf(",") != -1) {
					larr = lid.split(",");
				}else {
					larr = [lid];
				}
				var title:String = textNode.att.title;
				var body:String = textNode.att.body;
				for (each_lid in larr) {
					_index_notes.set(id + "_" + each_lid + "_title", title);
					_index_notes.set(id + "_" + each_lid + "_body", body);
				}
			}
		}
	}
	
	private function loadRootDirectory():Void
	{
		var firstFile = _list_files[0];
		var value:String = "";
		if (firstFile.hasNode.file && firstFile.node.file.has.value)
		{
			value = firstFile.node.file.att.value;
		}
		if (value != "")
		{
			var testText:String = loadText(locale+"/"+value);
			if (testText == "" || testText == null)
			{
				#if debug
					trace("ERROR: default locale(" + locale+") not found, searching for closest match...");
				#end
				var newLocale:String = findClosestExistingLocale(locale, value);
				#if debug
					trace("--> going with: " + newLocale);
				#end
				if (newLocale != "")
				{
					locale = newLocale;
				}
			}
		}
	}
	
	private function loadText(fname:String):String
	{
		var text:String = "";
		try
		{
			if (_directory == "")
			{
				text = Assets.getText("assets/locales/" + fname);
			}
			else
			{
				#if (cpp || neko)
				if(FileSystem.exists(_directory+"locales/" + fname)){
					text = File.getContent(_directory+"locales/" + fname);
				}
				#end
			}
		}
		catch (e:Dynamic)
		{
			#if debug
			trace("ERROR: loadText(" + fname + ") failed");
			#end
		}
		return text;
	}
	
	private function localeFormat(str:String):String
	{
		var arr:Array<String> = str.split("-");
		if (arr != null && arr.length == 2)
		{
			str = arr[0].toLowerCase() + "-" + arr[1].toUpperCase();
		}
		return str;
	}
	
	private function logMissingFile(fname:String):Void
	{
		if (missing_files == null)
		{
			missing_files = [];
		}
		missing_files.push(fname);
	}
	
	private function logMissingFlag(id:String, flag:String):Void
	{
		if (missing_flags == null)
		{
			missing_flags = new Map<String,Array<String>>();
		}
		
		if(missing_flags.exists(id) == false)
		{
			missing_flags.set(id, new Array<String>());
		}
		var list:Array<String> = missing_flags.get(id);
		list.push(flag);
	}
	
	private function onLoadFile():Void
	{
		_files_loaded++;
		
		if (_files_loaded == _list_files.length)
		{
			isLoaded = true;
			
			if (_check_missing)
			{
				if (missing_files.length == 0)
				{
					missing_files = null;
				}
				var i:Int = 0;
				for (key in missing_flags.keys())
				{
					i++;
				}
				if (i == 0)
				{
					missing_flags = null;
				}
			}
			
			if (_callback_finished != null)
			{
				try
				{
					_callback_finished();
				}
				catch (msg:String)
				{
					trace("ERROR msg = " + msg);
				}
			}
		}
	}
	
	private function printIndex(id:String, index:Map < String, Dynamic > ):Void
	{
		#if debug
		trace("printIndex(" + id + ")");
		
		for (key in index.keys()) {
			trace("..." + key + "," + index.get(key));
		}
		#end
	}
	
	/**
	 * Process this data file and populate localization fields
	 * @param	csv
	 * @param	id
	 * @param	check_vs_default
	 */
	
	private function processCSV(csv:CSV, id:String, check_vs_default:Bool = false):Void
	{
		var flag:String = "";
		var field_num:Int = csv.fields.length;
		
		if (_index_data.exists(id) == false)
		{
			_index_data.set(id, new Map<String,String>());	//create the index for this id
		}
		
		var _index:Map<String,String> = _index_data.get(id);
		var _real_fields:Int = 1;
		
		//count the number of non-comment fields 
		//(ignore 1st field, which is flag root field)
		for (fieldi in 1...csv.fields.length)
		{
			var field:String = csv.fields[fieldi];
			if (field != "comment")
			{
				_real_fields++;
			}
		}
		
		//Go through each row
		for (rowi in 0...csv.grid.length)
		{
			var row:Array<String> = csv.grid[rowi];
			
			//Get the flag root
			flag = row[0];
			
			if (_real_fields > 2)
			{
				//Count all non-comment fields as suffix fields to the flag root
				//Assume ("flag","suffix1","suffix2") pattern
				//Write each cell as flag_suffix1, flag_suffix2, etc.
				for (fieldi in 1...csv.fields.length)
				{
					var field:String = csv.fields[fieldi];
					if (field != "comment")
					{
						writeIndex(_index, (flag + "_" + field).toUpperCase(), row[fieldi],id,check_vs_default);
					}
				}
			}
			else if (_real_fields == 2)
			{
				//If only two non-comment fields, 
				//Assume it's the standard ("flag","value") pattern
				//Just write the first cell
				writeIndex(_index, flag, row[1], id, check_vs_default);
			}
		}
		
		csv.destroy();
		csv = null;
	}
	
	private function processFonts(xml:Fast):Void
	{
		if (xml != null && xml.hasNode.data && xml.node.data.hasNode.font)
		{
			for (fontNode in xml.node.data.nodes.font)
			{
				var value:String = fontNode.att.value;
				_index_font.set(value, copyFast(fontNode));
			}
		}
	}
	
	private function processPNG(img:BitmapData, id:String, check_vs_default:Bool = false):Void
	{
		if (check_vs_default && _check_missing)
		{
			if (_index_images.exists(id) == false)
			{
				//image exists in default locale but not current locale
				logMissingFile(id);
				//log the missing PNG file
				if (_replace_missing)
				{
					//replace with default locale version if necessary
					_index_images.set(id, img);
				}
			}
		}
		else
		{
			//just store the image
			_index_images.set(id, img);
		}
	}
	
	private function processXML(xml:Fast, id:String):Void
	{
		//what this does depends on the id
		switch(id) {
		case "fonts":
			processFonts(xml);
		default:
			//donothing
		}
	}
	
	private function startLoad(?asynchMethod:Array<LoadTask>->Void):Void
	{
		//if we don't have a list of files, we need to process the index first
		if (_list_files == null)
		{
			loadIndex();
		}
		
		//we need new ones of these no matter what:
		_index_data = new Map<String,Map<String,String>>();
		_index_font = new Map<String,Fast>();
		
		loadRootDirectory();		//make sure we can find our root directory
		
		//Load all the files in our list of files
		var tasks:Array<LoadTask> = [];
		
		for (fileNode in _list_files)
		{
			var value:String = "";
			if (fileNode.hasNode.file && fileNode.node.file.has.value)
			{
				value = fileNode.node.file.att.value;
			}
			if (value != "")
			{
				var task = {fileNode:fileNode, check:false};
				tasks.push(task);
				
				if (_check_missing)
				{
					task = {fileNode:fileNode, check:true};
					tasks.push(task);
				}
			}
			else
			{
				#if debug
				trace("ERROR: undefined file in localization index");
				#end
			}
		}
		
		if (asynchMethod != null)
		{
			asynchMethod(tasks);
		}
		else
		{
			doTasks(tasks);
		}
	}
	
	private function stringDiff(a:String, b:String, caseSensitive:Bool = true):Int
	{
		var totalDiff:Int = 0;
		if (caseSensitive == false)
		{
			a = a.toLowerCase();
			b = b.toLowerCase();
		}
		
		var weight:Int = 1;
		var max:Int = Std.int(Math.max(a.length, b.length));
		for (j in 0...max)
		{
			weight *= 10;
		}
		
		for (i in 0...a.length)
		{
			var char_a:String = a.charAt(i);
			var char_b:String = "";
			if (b.length > i) {
				char_b = b.charAt(i);
			}
			var diff:Int = 0;
			if (char_a != char_b)
			{
				diff = Std.int(Math.abs(StringTools.fastCodeAt(char_a,0) - StringTools.fastCodeAt(char_b,0)));
			}
			totalDiff += diff * weight;
			weight = Std.int(weight/10);
		}
		return totalDiff;
	}
	
	private function writeIndex(_index:Map<String,String>, flag:String, value:String, id:String, check_vs_default:Bool = false):Void
	{
		if (flag == null)
		{
			return;
		}
		
		if (check_vs_default && _check_missing)
		{
			//flag exists in default locale but not current locale
			if (_index.exists(flag) == false)
			{
				logMissingFlag(id, flag);
				if (_replace_missing)
				{
					_index.set(flag, value);
				}
			}
		}
		else
		{
			//just store the flag/translation pair
			_index.set(flag, value);
		}
	}
}

typedef LoadTask = {fileNode:Fast,check:Bool}