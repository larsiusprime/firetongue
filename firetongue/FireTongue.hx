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

#if haxe4
import haxe.xml.Access as Fast;
#else
import haxe.xml.Fast;
#end
#if sys
import sys.FileSystem;
import sys.io.File;
#end
import firetongue.format.CSV;
import firetongue.format.TSV;

typedef FiretongueParams =
{
	/**
	 * desired locale string, ie, "en-US"
	 */
	locale:String,

	/**
	 * (optional) callback which is executed when the locale is loaded
	 		* note you can specify additional callbacks by calling `addFinishedCallback(...)`
	 */
	?finishedCallback:Void->Void,
	/**
	 * (optional) if true, compares current locale against default locale for missing files/flags
	 */
	?checkMissing:Bool,
	/**
	 * (optional) if true, replaces any missing files & flags with values from the default locale
	 */
	?replaceMissing:Bool,
	/**
	 * (optional) path to look for locale
	 */
	?directory:String
}

typedef FontData =
{
	name:String,
	size:Int
}

/**
 * FireTongue is a Haxe port of the localization framework used in Defender's Quest. 
 *
 * Provide all your data in a localization folder in the correct format, and then
 * FireTongue will parse it and make it available to you at runtime.
 *
 * Basic usage (see documentation for more details):
 *
 * //somewhere in your code: 
 * tongue = new FireTongue();
 * tongue.initialize({
 * 		locale: "en-US",
 * 		finishedCallback: onFinish
 * });
 *
 * function onFinish():Void
 * {
 *    trace(tongue.get("HELLO_WORLD"));
 * }
 *
 * @author Lars Doucet
 */
class FireTongue
{
	/**
	 * locale to fall back on if needed
	 */
	public static var defaultLocale:String = "en-US";

	/**
	 * has this been loaded yet
	 */
	public var isLoaded(default, null):Bool;

	/**
	 * the current locale in ISO 639 4-letter code, ie, "en-US"
	 */
	public var locale(default, null):String;

	/**
	 * all the locales available
	 */
	public var locales(get, null):Array<String>;

	/**
	 * filled with filenames during initialization for any files found missing
	 */
	public var missingFiles(default, null):Array<String>;

	/**
	 * filled with flags during initialization for any flags found missing
	 */
	public var missingFlags(default, null):Map<String, Array<String>>;

	/**
	 * what text case (if any) to process flags with when getting strings
	 */
	public var forceFlagsToCase(default, null):Case;

	/**
	 * Custom string replacement function to use internally -- uses StringTools.replace() by default if null
	 */
	public var replaceFunction:String->String->String->String;

	/**
	 * Creates a new Firetongue instance.
	 * @param	framework (optional): Your haxe framework, ie: OpenFL, Lime, VanillaSys, etc. Leave null for firetongue to make a best guess, or supply your own loading functions to ignore this parameter entirely.
	 * @param	checkFile (optional) custom function to check if a file exists
	 * @param	getText (optional) custom function to load a text file
	 * @param	getDirectoryContents (optional) custom function to list the contents of a directory
	 * @param	forceCase (optional) what case to force for flags in CSV/TSV files, and in the get() function -- default is to force uppercase.
	 */
	public function new(?framework:Framework, ?checkFile:String->Bool, ?getText:String->String, ?getDirectoryContents:String->Array<String>,
			?forceCase:Case = Case.Upper)
	{
		forceFlagsToCase = forceCase;
		getter = new Getter(framework, checkFile, getText, getDirectoryContents);
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
	 * DEPRECATED! Initialize the localization structure
	 * @param	locale_ desired locale string, ie, "en-US"
	 * @param	finished_ callback for when it's done loading stuff
	 * @param	checkMissing_ if true, compares current locale against default locale for missing files/flags
	 * @param	replaceMissing_ if true, replaces any missing files & flags with values from the default locale
	 * @param	asynchLoadMethod_ (optional) a method for loading the files asynchronously
	 * @param	directory_ (optional) path to look for locale
	 */
	@:deprecated('init has been deprecated. Use initialize instead.')
	public inline function init(locale_:String, finished_:Void->Void = null, checkMissing_:Bool = false, replaceMissing_:Bool = false,
			?asynchLoadMethod_:Array<LoadTask>->Void, ?directory_:String = "assets/locales/"):Void
	{
		initialize({
			locale: locale_,
			finishedCallback: finished_,
			checkMissing: checkMissing_,
			replaceMissing: replaceMissing_,
			directory: directory_
		});
	}

	/**
	 * Initialize the localization structure
	 * @param	params initialization parameters
	 */
	public function initialize(params:FiretongueParams):Void
	{
		var dirStr = params.directory;
		if (dirStr == null || dirStr == "")
		{
			dirStr = "assets/locales/";
		}

		locale = localeFormat(params.locale);
		directory = dirStr;

		if (isLoaded)
		{
			clearData(); // if we have an existing locale already loaded, clear it out first
		}

		addFinishedCallback(params.finishedCallback);

		checkMissing = false;
		replaceMissing = false;

		if (locale != defaultLocale)
		{
			checkMissing = params.checkMissing;
			replaceMissing = params.replaceMissing;
		}

		if (checkMissing)
		{
			missingFiles = [];
			missingFlags = new Map<String, Array<String>>();
		}

		startLoad();
	}

	/**
	 * Provide a localization flag to get the proper text in the current locale.
	 * @param	flag a flag string, like "HELLO_WORLD"
	 * @param	context a string specifying which index, in case you want that
	 * @param	safe if true, suppresses errors and returns the untranslated flag if not found
	 * @return  the translated string
	 */
	public function get(flag:String, context:String = "data", safe:Bool = true):String
	{
		if (flag == null)
		{
			return null;
		}

		var orig_flag:String = flag;
		flag = switch (forceFlagsToCase)
		{
			case Upper: flag.toUpperCase();
			case Lower: flag.toLowerCase();
			default: flag;
		}

		if (context == "index")
		{
			return matchIndexString(flag);
		}

		var index:Map<String, String>;
		index = indexData.get(context);
		if (index == null)
		{
			return flag;
		}

		var str:String = "";
		try
		{
			str = index.get(flag);

			if (str != null && str != "")
			{
				var redirectStr = tryRedirect(index, str);
				if (redirectStr != null)
				{
					str = redirectStr;
				}
				else
				{
					if (safe)
					{
						str = flag;
					}
					else
					{
						str = redirectStr;
					}
				}

				// Replace standard stuff:

				var fix_a:Array<String> = ["<N>", "<T>", "<LQ>", "<RQ>", "<C>", "<Q>"];
				var fix_b:Array<String> = ["\n", "\t", "“", "”", ",", '"'];

				if (str != null && str != "")
				{
					for (i in 0...fix_a.length)
					{
						while (str.indexOf(fix_a[i]) != -1)
						{
							str = doReplace(str, fix_a[i], fix_b[i]);
						}
					}
				}
			}
		}
		catch (e:Dynamic)
		{
			if (safe)
			{
				return orig_flag;
			}
			else
			{
				throw("LocaleData.getText(" + flag + "," + context + ")");
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
	 * @param str 
	 * @param size 
	 * @return FontData
	 */
	public function getFontData(str:String, ?size:Int = 1):FontData
	{
		var replace:FontData = {
			name: "",
			size: size
		}

		try
		{
			var xml:Fast = indexFont.get(str);
			if (xml != null && xml.hasNode.font)
			{
				replace.name = xml.node.font.att.replace;

				if (xml.node.font.hasNode.size)
				{
					for (sizeNode in xml.node.font.nodes.size)
					{
						var sizestr:String = Std.string(size);
						if (sizeNode.att.value == sizestr)
						{
							var replacestr:String = sizeNode.att.replace;
							if (replacestr != "" && replacestr != null)
							{
								replace.size = Std.parseInt(replacestr);
								if (replace.size == 0)
								{
									replace.size = size;
								}
							}
						}
					}
				}
			}
			if (replace.name == "" || replace.name == null)
			{
				replace.name = str;
			}
		}
		catch (e:Dynamic)
		{
			replace.name = str;
			replace.size = size;
		}

		return replace;
	}

	/**
	 * DEPRECATED! Use `getFontData(str, size).name` instead;
	 * @param str 
	 * @return FontData
	 */
	@:deprecated('getFont is deprecated. Use getFontData instead.')
	public function getFont(str:String):String
	{
		return getFontData(str).name;
	}

	/**
	 * DEPRECATED! Use `getFontData(str, size).size` instead;
	 */
	@:deprecated('getFontSize is deprecated. Use getFontData instead.')
	public function getFontSize(str:String, size:Int):Int
	{
		return getFontData(str, size).size;
	}

	/**
	 * Get a locale (flag) icon's asset file path
	 * @param	locale_id
	 * @return
	 */
	public function getIcon(locale_id:String):String
	{
		return indexIcons.get(locale_id);
	}

	/**
	 * Returns a copy of the specified locale definition's xml node
	 * @param	targetLocale	the locale in question, ie "en-US"
	 * @return
	 */
	public function getIndexNode(targetLocale:String = ""):Xml
	{
		var node:Fast = indexLocales.get(targetLocale);
		return Xml.parse(node.x.toString());
	}

	/**
	 * Gets an attribute from the specified locale definition's xml node
	 * @param	targetLocale	the locale in question, ie "en-US"
	 * @param	attribute	the attribute you want, ie "volunteer"
	 * @param	child	(optional) the name of a child node if you want to read from that instead of the main root
	 * @return
	 */
	public function getIndexAttribute(targetLocale:String, attribute:String, ?child:String = ""):String
	{
		var node:Fast = indexLocales.get(targetLocale);

		if (child != null && node.hasNode.resolve(child))
		{
			node = node.node.resolve(child);
		}

		if (node != null && node.has.resolve(attribute))
		{
			return node.att.resolve(attribute);
		}
		return "";
	}

	/**
	 * 
	 * @param	flag
	 * @return
	 */
	public function getIndexString(indexString:IndexString, targetLocale:String = "", currLocale:String = ""):String
	{
		if (currLocale == "")
		{
			currLocale = locale;
		}

		if (targetLocale == "")
		{
			targetLocale = locale;
		}

		// get the locale entry for the target locale from the index
		var lindex:Fast = indexLocales.get(targetLocale);

		var currLangNode:Fast = null;
		var nativeNode:Fast = null;

		if (lindex.hasNode.label)
		{
			for (lNode in lindex.nodes.label) // look through each label
			{
				if (lNode.has.id)
				{
					var lnid:String = lNode.att.id;
					if (lnid.indexOf(currLocale) != -1) // if it matches the CURRENT locale
					{
						currLangNode = lNode; // labels in CURRENT language
					}
					if (lnid.indexOf(targetLocale) != -1) // if it matches its own NATIVE locale
					{
						nativeNode = lNode; // labels in NATIVE language
					}
					if (currLangNode != null && nativeNode != null)
					{
						break;
					}
				}
			}
		}

		switch (indexString)
		{
			case IndexString.TheWordLanguage:
				// return the localized word "LANGUAGE"
				if (lindex.hasNode.ui && lindex.node.ui.has.language)
				{
					return lindex.node.ui.att.language;
				}
			case IndexString.TheWordRegion:
				// return the localized word "REGION"
				if (lindex.hasNode.ui && lindex.node.ui.has.region)
				{
					return lindex.node.ui.att.region;
				}
			case IndexString.Language:
				// return the name of this language in CURRENT language
				if (currLangNode != null && currLangNode.has.language)
				{
					return currLangNode.att.language;
				}
			case IndexString.LanguageNative:
				// return the name of this language in NATIVE language
				if (nativeNode != null && nativeNode.has.language)
				{
					return nativeNode.att.language;
				}
			case IndexString.Region:
				// return the name of this region in CURRENT language
				if (currLangNode != null && nativeNode.has.region)
				{
					return currLangNode.att.region;
				}
			case IndexString.RegionNative:
				// return the name of this region in NATIVE language
				if (nativeNode != null && nativeNode.has.region)
				{
					return nativeNode.att.region;
				}
			case IndexString.LanguageBilingual:
				// return the name of this language in both CURRENT and NATIVE, if different
				var lang:String = "";
				var langnative:String = "";
				if (nativeNode != null && nativeNode.has.language)
				{
					langnative = nativeNode.att.language;
				}
				if (currLangNode != null && currLangNode.has.language)
				{
					lang = currLangNode.att.language;
				}
				if (lang == langnative)
				{
					return lang;
				}
				else
				{
					return lang + " (" + langnative + ")";
				}
			case IndexString.LanguageRegion:
				// return something like "Inglés (Estados Unidos)" in CURRENT language (ex: curr=spanish native=english)
				var lang:String = getIndexString(targetLocale, Language);
				var reg:String = getIndexString(targetLocale, Region);
				return lang + "(" + reg + ")";
			case IndexString.LanguageRegionNative:
				// return something like "English (United States)" in NATIVE language (ex: curr=spanish native=english)
				var lang:String = getIndexString(targetLocale, LanguageNative);
				var reg:String = getIndexString(targetLocale, RegionNative);
				return lang + "(" + reg + ")";
			default:
				// donothing
		}
		return Std.string(indexString);
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
			var str:String = indexNotes[id + "_" + locale + "_body"];
			return Replace.flags(str, ["$N"], ["\n"]);
		}
		catch (e:String)
		{
			return "ERROR:(" + id + ") for (" + locale + ") body not found";
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
			var str:String = indexNotes[id + "_" + locale + "_title"];
			return Replace.flags(str, ["$N"], ["\n"]);
		}
		catch (e:String)
		{
			return "ERROR:(" + id + ") for (" + locale + ") title not found";
		}
		return "";
	}

	/******PRIVATE******/
	private var getter:Getter;

	// All of the game's localization data
	private var indexData:Map<String, Map<String, String>>;

	// All of the locale entries
	private var indexLocales:Map<String, Fast>;

	// All of the text notations
	private var indexNotes:Map<String, String>;

	// All of the icons from various languages
	private var indexIcons:Map<String, String>;

	// Any custom images loaded
	private var indexImages:Map<String, String>;

	// Font replacement rules
	private var indexFont:Map<String, Fast>;

	private var finishedCallbacks:Array<Void->Void> = [];

	private var listFiles:Array<Fast>;
	private var filesLoaded:Int = 0;

	private var checkMissing:Bool = false;
	private var replaceMissing:Bool = false;

	public var directory(default, null):String = "assets/locales";

	private function doReplace(s:String, sub:String, by:String):String
	{
		if (replaceFunction != null)
		{
			return replaceFunction(s, sub, by);
		}
		return StringTools.replace(s, sub, by);
	}

	/**
	 * Clear all the current localization data. 
	 * @param	hard Also clear all the index-related data, restoring it to a pre-initialized state.
	 */
	private function clearData(hard:Bool = false):Void
	{
		if (listFiles != null)
		{
			while (listFiles.length > 0)
			{
				listFiles.pop();
			}
			listFiles = null;
		}

		isLoaded = false;
		filesLoaded = 0;

		for (sub_key in indexData.keys())
		{
			var subindex:Map<String, Dynamic> = indexData.get(sub_key);
			indexData.remove(sub_key);
			clearMap(subindex);
			subindex = null;
		}

		clearMap(indexImages);
		clearMap(indexFont);

		indexImages = null;
		indexFont = null;

		if (hard)
		{
			clearMap(indexLocales);
			clearMap(indexIcons);
			clearMap(indexNotes);
			indexLocales = null;
			indexIcons = null;
			indexNotes = null;
		}

		clearMap(missingFlags);
		if (missingFiles != null)
		{
			while (missingFiles.length > 0)
			{
				missingFiles.pop();
			}
		}

		missingFiles = null;
		missingFlags = null;
	}

	private function clearMap<T1, T2>(map:Map<T1, T2>, ?onRemove:T2->Void):Void
	{
		if (map == null)
			return;

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
	private inline function copyFast(fast:Fast):Fast
	{
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

	private function findClosestExistingLocale(localeStr:String, testFile:String):String
	{
		var paths:Array<String> = null;
		var bestLocale:String = "";
		var bestDiff:Float = Math.POSITIVE_INFINITY;

		paths = getDirectoryContents("");

		if (paths != null)
		{
			var localeCandidates:Array<String> = [];

			for (str in paths)
			{
				var newLocale:String = doReplace(str, directory, "");
				newLocale = doReplace(newLocale, "\\", "/");
				var split:Array<String> = newLocale.split("/");
				if (split != null && split.length > 0)
				{
					newLocale = split[0];
					if (false == (newLocale.length == 5 && newLocale.charAt(2) == "-"))
					{
						newLocale = "";
					}
				}
				if (newLocale.indexOf("_") != 0 && newLocale.indexOf(".") == -1)
				{
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

			for (loc in localeCandidates)
			{
				var diff = stringDiff(localeStr, loc, false);
				if (diff < bestDiff)
				{
					bestDiff = diff;
					bestLocale = loc;
				}
			}
		}

		return bestLocale;
	}

	private function get_locales():Array<String>
	{
		var arr:Array<String> = [];
		for (key in indexLocales.keys())
		{
			arr.push(key);
		}
		return arr;
	}

	private function getDirectoryContents(str):Array<String>
	{
		return getter.getDirectoryContents(directory + str);
	}

	/**
	 * Loads a file and processes its contents in the data structure
	 * @param	fileData <file> node entry from index.xml
	 * @param	checkVsDefault if true, will use to do safety check rather than immediately store the data
	 * @return
	 */
	private function loadFile(fileData:Fast, checkVsDefault:Bool = false):String
	{
		var fileName:String = fileData.node.file.att.value;
		var fileType:String = fileName.substr(fileName.length - 3, 3);
		var fileID:String = fileData.node.file.att.id;

		var raw_data:String = "";

		var loc:String = locale;
		if (checkVsDefault)
		{
			loc = defaultLocale;
		}

		switch (fileType)
		{
			case "txt", "tsv":
				var raw_data = null;
				var raw_data = loadText(loc + "/" + fileName);
				if (raw_data != "" && raw_data != null)
				{
					var tsv:TSV = new TSV(raw_data);
					processCSV(tsv, fileID, checkVsDefault);
				}
				else if (checkMissing)
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
					processCSV(csv, fileID, checkVsDefault);
				}
				else if (checkMissing)
				{
					logMissingFile(fileName);
				}
			case "xml":
				if (!checkVsDefault) // xml (ie font rules) don't need safety checks
				{
					var raw_data = loadText(loc + "/" + fileName);
					if (raw_data != "" && raw_data != null)
					{
						var xml:Fast = new Fast(Xml.parse(raw_data));
						processXML(xml, fileID);
					}
					else if (checkMissing)
					{
						logMissingFile(fileName);
					}
				}
			case "png":
				var asset = directory + loc + "/" + fileName;
				if (loadImage(asset))
				{
					processPNG(asset, fileID, checkVsDefault);
				}
				else if (checkMissing)
				{
					logMissingFile(fileName);
				}
		}
		return fileName;
	}

	private function loadImage(fname:String):Bool
	{
		if (getter.checkFile(fname))
		{
			return true;
		}

		#if debug
		trace("ERROR: loadImage(" + fname + ") failed");
		#end
		if (checkMissing)
		{
			logMissingFile(fname);
		}

		return false;
	}

	/**
	 * Loads and processes the index file
	 */
	private function loadIndex():Void
	{
		var index:String = loadText("index.xml");
		var xml:Fast = null;

		listFiles = new Array<Fast>();

		if (index == "" || index == null)
		{
			throw("Couldn't load index.xml!");
		}
		else
		{
			xml = new Fast(Xml.parse(index));

			// Create a list of file metadata from the list in the index
			if (xml.hasNode.data && xml.node.data.hasNode.file)
			{
				for (fileNode in xml.node.data.nodes.file)
				{
					listFiles.push(copyFast(fileNode));
				}
			}
		}

		if (indexLocales == null)
		{
			indexLocales = new Map<String, Fast>();
		}
		if (indexNotes == null)
		{
			indexNotes = new Map<String, String>();
		}
		if (indexIcons == null)
		{
			indexIcons = new Map<String, String>();
		}
		if (indexImages == null)
		{
			indexImages = new Map<String, String>();
		}

		var id:String = "";

		for (localeNode in xml.node.data.nodes.locale)
		{
			id = localeNode.att.id;
			indexLocales.set(id, localeNode);

			// load & store the icon image existence

			var iconAsset = directory + "_icons/" + id + ".png";
			var flagAsset = directory + "_flags/" + id + ".png";

			if (loadImage(iconAsset))
			{
				indexIcons.set(id, iconAsset);
			}
			else if (loadImage(flagAsset))
			{
				indexIcons.set(id, flagAsset);
			}
			else
			{
				indexIcons.set(id, null);
			}

			var isDefault:Bool = localeNode.has.is_default && localeNode.att.is_default == "true";
			if (isDefault)
			{
				defaultLocale = id;
			}
		}

		// If default locale is not defined yet, make it American English
		if (defaultLocale == "")
		{
			defaultLocale = "en-US";
		}

		// If the current locale is not defined yet, make it the default
		if (locale == "")
		{
			locale = defaultLocale;
		}

		// Load and store all the translation notes
		for (noteNode in xml.node.data.nodes.note)
		{
			id = noteNode.att.id;
			for (textNode in noteNode.nodes.text)
			{
				var lid:String = textNode.att.id;
				var larr:Array<String> = null;
				if (lid.indexOf(",") != -1)
				{
					larr = lid.split(",");
				}
				else
				{
					larr = [lid];
				}
				var title:String = textNode.att.title;
				var body:String = textNode.att.body;
				for (eachLid in larr)
				{
					indexNotes.set(id + "_" + eachLid + "_title", title);
					indexNotes.set(id + "_" + eachLid + "_body", body);
				}
			}
		}
	}

	private function loadRootDirectory():Void
	{
		var firstFile = listFiles[0];
		var value:String = "";

		if (firstFile == null)
			return;

		if (firstFile.hasNode.file && firstFile.node.file.has.value)
		{
			value = firstFile.node.file.att.value;
		}
		if (value != "")
		{
			var testText:String = null;
			try
			{
				testText = loadText(locale + "/" + value);
			}
			catch (msg:Dynamic)
			{
				testText = null;
			}
			if (testText == "" || testText == null)
			{
				#if debug
				trace("ERROR: default locale(" + locale + ") not found, searching for closest match...");
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
		try
		{
			return getter.getText(directory + fname);
		}
		catch (msg:Dynamic)
		{
			return null;
		}
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
		if (missingFiles == null)
		{
			missingFiles = [];
		}
		missingFiles.push(fname);
	}

	private function logMissingFlag(id:String, flag:String):Void
	{
		if (missingFlags == null)
		{
			missingFlags = new Map<String, Array<String>>();
		}

		if (missingFlags.exists(id) == false)
		{
			missingFlags.set(id, new Array<String>());
		}
		var list:Array<String> = missingFlags.get(id);
		list.push(flag);
	}

	private function matchIndexString(str:String):String
	{
		var orig_str = str;
		var arr:Array<String> = [
			IndexString.Language,
			IndexString.LanguageBilingual,
			IndexString.LanguageNative,
			IndexString.LanguageRegion,
			IndexString.LanguageRegionNative,
			IndexString.Region,
			IndexString.RegionNative,
			IndexString.TheWordLanguage,
			IndexString.TheWordRegion
		];
		for (str2 in arr)
		{
			if (str.indexOf(str2) == 0)
			{
				var tempstr = doReplace(orig_str, str2, "");
				if (tempstr != "" && tempstr.indexOf(":") == 0)
				{
					tempstr = tempstr.substr(1, tempstr.length - 1);
					var loc = "";
					for (key in indexLocales.keys())
					{
						if (key.toUpperCase() == tempstr.toUpperCase())
						{
							loc = key;
						}
					}
					if (loc != "")
					{
						return getIndexString(str2, loc);
					}
				}
			}
		}
		return orig_str;
	}

	private function onLoadFile():Void
	{
		filesLoaded++;

		if (filesLoaded == listFiles.length)
		{
			// Do this only after all files are loaded.
			isLoaded = true;

			if (checkMissing)
			{
				if (missingFiles.length == 0)
				{
					missingFiles = null;
				}
				var i:Int = 0;
				for (key in missingFlags.keys())
				{
					i++;
				}
				if (i == 0)
				{
					missingFlags = null;
				}
			}

			if (finishedCallbacks.length > 0)
			{
				for (finishedCb in finishedCallbacks)
				{
					try
					{
						finishedCb();
					}
					catch (msg:String)
					{
						#if debug
						trace("ERROR msg = " + msg);
						#end
					}
				}
			}
		}
	}

	public function addFinishedCallback(callback:Void->Void):Void
	{
		if (callback != null && finishedCallbacks.indexOf(callback) == -1)
			finishedCallbacks.push(callback);
	}

	public function removeFinishedCallback(callback:Void->Void):Void
	{
		finishedCallbacks.remove(callback);
	}

	public function clearFinishedCallbacks():Void
	{
		finishedCallbacks = [];
	}

	private function printIndex(id:String, index:Map<String, Dynamic>):Void
	{
		#if debug
		trace("printIndex(" + id + ")");

		for (key in index.keys())
		{
			trace("..." + key + "," + index.get(key));
		}
		#end
	}

	/**
	 * Process this data file and populate localization fields
	 * @param	csv
	 * @param	id
	 * @param	checkVsDefault
	 */
	private function processCSV(csv:CSV, id:String, checkVsDefault:Bool = false):Void
	{
		var flag:String = "";
		var field_num:Int = csv.fields.length;

		if (indexData.exists(id) == false)
		{
			indexData.set(id, new Map<String, String>()); // create the index for this id
		}

		var index:Map<String, String> = indexData.get(id);
		var real_fields:Int = 1;

		// count the number of non-comment fields
		// (ignore 1st field, which is flag root field)
		for (fieldi in 1...csv.fields.length)
		{
			var field:String = csv.fields[fieldi];
			if (field != "comment")
			{
				real_fields++;
			}
		}

		// Go through each row
		for (rowi in 0...csv.grid.length)
		{
			var row:Array<String> = csv.grid[rowi];

			// Get the flag root
			flag = row[0];

			if (real_fields > 2)
			{
				// Count all non-comment fields as suffix fields to the flag root
				// Assume ("flag","suffix1","suffix2") pattern
				// Write each cell as flag_suffix1, flag_suffix2, etc.
				for (fieldi in 1...csv.fields.length)
				{
					var field:String = csv.fields[fieldi];
					if (field != "comment")
					{
						var newFlag = (flag + "_" + field);
						newFlag = switch (forceFlagsToCase)
						{
							case Upper: newFlag.toUpperCase();
							case Lower: newFlag.toLowerCase();
							default: newFlag;
						}
						writeIndex(index, newFlag, row[fieldi], id, checkVsDefault);
					}
				}
			}
			else if (real_fields == 2)
			{
				// If only two non-comment fields,
				// Assume it's the standard ("flag","value") pattern
				// Just write the first cell

				if (flag != null)
				{
					flag = switch (forceFlagsToCase)
					{
						case Upper: flag.toUpperCase();
						case Lower: flag.toLowerCase();
						default: flag;
					}
				}
				writeIndex(index, flag, row[1], id, checkVsDefault);
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
				indexFont.set(value, copyFast(fontNode));
			}
		}
	}

	private function processPNG(img:String, id:String, checkVsDefault:Bool = false):Void
	{
		if (checkVsDefault && checkMissing)
		{
			if (indexImages.exists(id) == false)
			{
				// image exists in default locale but not current locale
				logMissingFile(id);
				// log the missing PNG file
				if (replaceMissing)
				{
					// replace with default locale version if necessary
					indexImages.set(id, img);
				}
			}
		}
		else
		{
			// just store the image
			indexImages.set(id, img);
		}
	}

	private function processXML(xml:Fast, id:String):Void
	{
		// what this does depends on the id
		switch (id)
		{
			case "fonts":
				processFonts(xml);
			default:
				// donothing
		}
	}

	private function redirectSection(start:Int, end:Int, index:Map<String, String>, str:String):String
	{
		var flag = "";
		var match = "";

		if (start != 1 && end != -1 && end > start) // redirection exists
		{
			match = str.substring(start, end + 1);
			flag = str.substring(start + 5, end); // cut off the redirection and the brackets

			if (flag == "" || flag == null)
			{
				return null;
			}

			if (index.exists(flag))
			{
				var new_str = index.get(flag); // look it up again

				if (new_str != null)
				{
					// If we have whole-line redirects as the targets for our section redirect, we need to resolve those
					// completely before we substitute them into the parent string. If they contain further sectional redirects,
					// those will be caught & processed later
					while (new_str.indexOf("<RE>") != -1 && new_str.indexOf("<RE>[") == -1)
					{
						var new_str_redirect = redirectLine(index, new_str);
						if (new_str_redirect != null)
						{
							new_str = new_str_redirect;
						}
					}

					str = doReplace(str, match, new_str);
					return str;
				}
			}
		}
		return null;
	}

	private function redirectLine(index:Map<String, String>, str:String):String
	{
		str = doReplace(str, "<RE>", ""); // cut out the redirect
		if (index.exists(str))
		{
			return index.get(str); // look it up again
		}
		return null;
	}

	private function startLoad(?asynchMethod:Array<LoadTask>->Void):Void
	{
		// if we don't have a list of files, we need to process the index first
		if (listFiles == null)
		{
			loadIndex();
		}

		// we need new ones of these no matter what:
		indexData = new Map<String, Map<String, String>>();
		indexFont = new Map<String, Fast>();

		loadRootDirectory(); // make sure we can find our root directory

		// Load all the files in our list of files
		var tasks:Array<LoadTask> = [];

		for (fileNode in listFiles)
		{
			var value:String = "";
			if (fileNode.hasNode.file && fileNode.node.file.has.value)
			{
				value = fileNode.node.file.att.value;
			}
			if (value != "")
			{
				var task = {fileNode: fileNode, check: false};
				tasks.push(task);

				if (checkMissing)
				{
					task = {fileNode: fileNode, check: true};
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

	private function stringDiff(a:String, b:String, caseSensitive:Bool = true):Float
	{
		var totalDiff:Int = 0;

		if (a != "" && b == "")
			return Math.POSITIVE_INFINITY;

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
			if (b.length > i)
			{
				char_b = b.charAt(i);
			}
			var diff:Int = 0;
			if (char_a != char_b)
			{
				diff = Std.int(Math.abs(StringTools.fastCodeAt(char_a, 0) - StringTools.fastCodeAt(char_b, 0)));
			}
			totalDiff += diff * weight;
			weight = Std.int(weight / 10);
		}

		return totalDiff;
	}

	private function tryRedirect(index:Map<String, String>, str:String, failsafe:Int = 100):String
	{
		var orig:String = str;
		var last:String = null;

		// keep processing until no redirection tokens are detected, or the failsafe is tripped
		while (str != null && str.indexOf("<RE>") != -1 && failsafe > 0)
		{
			last = str;

			var sectionStart = str.indexOf("<RE>[");
			var sectionEnd = str.indexOf("]");
			if (sectionStart != -1 && sectionEnd != -1 && sectionEnd > sectionStart)
			{
				// replace the portion inside a redirect section token
				str = redirectSection(sectionStart, sectionEnd, index, str);
			}
			else
			{
				// treat it like a whole-line redirect
				str = redirectLine(index, str);
			}
			failsafe--;
		}
		if (failsafe <= 0)
		{
			trace("WARNING! > " + failsafe + " redirections detected when processing (" + orig + "), failsafe tripped!");
			str = orig;
		}

		if (str == null && last != null)
		{
			str = last;
		}
		return str;
	}

	private function writeIndex(index:Map<String, String>, flag:String, value:String, id:String, checkVsDefault:Bool = false):Void
	{
		if (flag == null)
		{
			return;
		}

		if (checkVsDefault && checkMissing)
		{
			// flag exists in default locale but not current locale
			if (index.exists(flag) == false)
			{
				logMissingFlag(id, flag);
				if (replaceMissing)
				{
					index.set(flag, value);
				}
			}
		}
		else
		{
			// just store the flag/translation pair
			index.set(flag, value);
		}
	}
}

@:enum
abstract IndexString(String) from String to String
{
	var TheWordLanguage = "$UI_LANGUAGE";
	var TheWordRegion = "$UI_REGION";
	var Language = "$LANGUAGE";
	var LanguageNative = "$LANGUAGE_NATIVE";
	var Region = "$REGION";
	var RegionNative = "$REGION_NATIVE";
	var LanguageBilingual = "$LANGUAGE_BILINGUAL";
	var LanguageRegion = "$LANGUAGE_REGION";
	var LanguageRegionNative = "$LANGUAGE_REGION_NATIVE";
}

enum Framework
{
	VanillaSys;
	OPENFL;
	LIME;
	NME;
	CUSTOM;
	// add more frameworks as they are supported ... maybe?
}

@:enum
abstract Case(Int) from Int to Int
{
	var Upper = 1;
	var Lower = -1;
	var Unchanged = 0;
}

typedef LoadTask =
{
	fileNode:Fast,
	check:Bool
}
