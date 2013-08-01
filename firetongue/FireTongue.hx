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
	import task.Task;
	import task.TaskList;
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
		 * private var tonuge:FireTongue;
		 * 
		 * //somewhere in your code: 
		 * tongue = new FireTongue();
		 * tongue.init("en-US",onFinish);		
		 *   
		 * function onFinish():Void{
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
		    (perhaps the user should just make two FireTongue instances for this)
	 */
	 
	class FireTongue
	{		
		private var _locale:String;
		
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
		
		private var _loaded:Bool = false;
					
		public static var default_locale:String = "en-US";
		
		private var _callback_finished:Dynamic;
			//private var _callback_progress:Dynamic;
			//private var _callback_error:Dynamic;
		
		private var _list_files:Array<Fast>;
		private var _files_loaded:Int = 0;		
		
		private var _safety_bit:Int = 0;
		
		//TODO:
		private var _check_missing:Bool = false;
		private var _replace_missing:Bool = false;
		private var _missing_flags:Map<String,Array<String>>;
		private var _missing_files:Array<String>;
		
		private var _directory:String = "";
				
		public function new() 
		{
			//does nothing
		}
		
		public function clear(hard:Bool):Void {
			clearData(hard);
		}
				
		public var isLoaded(get, null):Bool;		
		public function get_isLoaded():Bool {
			return _loaded;
		}
		
		public var locale(get, null):String;		
		public function get_locale():String {
			return _locale;
		}
		
		public var locales(get, null):Array<String>;
		public function get_locales():Array<String> {
			var arr:Array<String> = [];
			for (key in _index_locales.keys()) {
				arr.push(key);
			}return arr;
		}
		
		/*public var locale_index(get, null):Map<String,Fast>;
		public function get_locale_index():Map<String,Fast>{
			return _index_locales;
		}*/
				
		public var missing_files(get, null):Array<String>;
		public function get_missing_files():Array<String> {
			return _missing_files;	
		}
		
		public var missing_flags(get, null):Map < String, Array<String> > ;
		public function get_missing_flags():Map < String, Array<String> > {
			return _missing_flags;
		}
				
		/**
		 * Initialize the localization structure
		 * @param	locale_ desired locale string, ie, "en-US"
		 * @param	finished_ callback for when it's done loading stuff
		 * @param	check_missing_ if true, compares against default locale for missing files/flags
		 * @param   replace_missing_ if true, replaces any missing files & flags with default locale values
		 * @param	directory_ alternate directory to look for locale. Otherwise, is "assets/"
		 */
		
		public function init(locale_:String, finished_:Dynamic=null, check_missing_:Bool=false, replace_missing_:Bool = false, directory_:String=""):Void{
			#if debug
				trace("LocaleData.init(" + locale_ + "," + finished_ + "," + check_missing_ + "," + replace_missing_ +"," +directory_+")");
			#end
			
			_locale = locale_;
			_directory = directory_;			
			
			if (_loaded) {				
				clearData();	//if we have an existing locale already loaded, clear it out first			
			}
			
			_callback_finished = finished_;
		
			_check_missing = false;
			_replace_missing = false;
			
			if (_locale != default_locale) {				
				_check_missing = check_missing_;
				_replace_missing = replace_missing_;
			}
			
			if (_check_missing) {
				_missing_files = new Array<String>();
				_missing_flags = new Map<String,Array<String>>();
			}
			
			startLoad();
		}
		
		
		/*****LOOKUP FUNCTIONS*****/		
		
		/**
		 * Provide a localization flag to get the proper text in the current locale.
		 * @param	flag a flag string, like "$HELLO"
		 * @param	context a string specifying which index, in case you want that
		 * @param	safe if true, suppresses errors and returns the untranslated flag if not found
		 * @return  the translated string
		 */
		
		public function get(flag:String, context:String = "data", safe:Bool=true):String {
			var orig_flag:String = flag;
			flag = flag.toUpperCase();
			
			var index:Map<String,String>;						
			index = _index_data.get(context);
			if (index == null) {
				if (!safe) {
					throw new Error("no localization context \"+data+\"");
				}else {
					return flag;
				}
			}
			
			var str:String = "";
			try {			
				str = index.get(flag);
				
				if(str != null && str != ""){
					//Replace standard stuff:
				
					if (str.indexOf("<RE>") == 0) {	//it's a redirect
						var done:Bool = false;
						var failsafe:Int = 0;
						str = StringTools.replace(str, "<RE>", "");	//cut out the redirect
						while (!done) {
							var new_str:String = index.get(str);	//look it up again
							if (new_str != null && new_str != "") {	//string exists
								str = new_str;
								if (str.indexOf("<RE>") != 0) {			//if it's not ANOTHER redirect, stop looking
									done = true;
								}else {									
									//another redirect, keep looking
									str = StringTools.replace(str, "<RE>", "");
								}
							}else {				//give up
								done = true;
								str = new_str;
							}
							failsafe++;
							if (failsafe > 100) {	//max recursion: 100
								done = true;
								str = new_str;
							}
						}
					}
					
					var fix_a:Array<String> = ["<N>","<T>","<LQ>","<RQ>","<C>"];
					var fix_b:Array<String> = ["\n","\t","“","”",","];
					
					if (str != null && str != "") {
						for (i in 0...fix_a.length) {
							while (str.indexOf(fix_a[i]) != -1) {
								str = StringTools.replace(str, fix_a[i], fix_b[i]);
							}
						}
					}
				}							
			}catch (e:Error) {
				if (safe) {
					return orig_flag;
				}else {
					throw new Error("LocaleData.getText(" + flag + "," + context + ")");
				}
			}
			
			index = null;
			
			if (str == null) {
				#if debug
					trace("ERROR ERROR -- LocaleData.getText(" + flag + "," + context + ")");
				#end
				if (safe) {
					return orig_flag;
				}
			}
						
			return str;
		}
		
		/**
		 * Get the title of a localization note (locale menu purposes)
		 * @param	locale
		 * @param	id
		 * @return
		 */
		
		public function getNoteTitle(locale:String, id:String):String {
			try{
				var str:String = _index_notes[id + "_" + locale + "_title"];				
				return Replace.flags(str, ["$N"], ["\n"]);
			}catch (e:String) {
				return "ERROR:("+id+") for (" + locale + ") title not found";
			}
			return "";
		}
		
		/**
		 * Get the body of a localization note (locale menu purposes)
		 * @param	locale
		 * @param	id
		 * @return
		 */
				
		public function getNoteBody(locale:String, id:String):String {
			try {
				var str:String = _index_notes[id + "_" + locale + "_body"];					
				return Replace.flags(str, ["$N"], ["\n"]);
			}catch (e:String) {				
				return "ERROR:("+id+") for (" + locale + ") body not found";
			}
			return "";
		}
				
		/**
		 * Get a locale (flag) icon
		 * @param	locale_id
		 * @return
		 */
		
		public function getIcon(locale_id:String):BitmapData{						
			return _index_icons.get(locale_id);
		}
		
		public function getFont(str:String):String {
			var replace:String = "";
			try {
				var xml:Fast = _index_font.get(str);
				if (xml != null && xml.hasNode.font) {
					replace = xml.node.font.att.replace;
				}
				if (replace == "" || replace == null) {
					replace = str;
				}
			}catch (e:Error) {
				replace = str;
			}
			return replace;
		}
		
		public function getFontSize(str:String, size:Int):Int {
			var replace:Int = size;
			try {
				var xml:Fast = _index_font.get(str);
				if (xml != null && xml.hasNode.font && xml.node.font.hasNode.size) {
					for (sizeNode in xml.node.font.nodes.size) {
						var sizestr:String = Std.string(size);
						if (sizeNode.att.value == sizestr) {
							var replacestr:String = sizeNode.att.replace;							
							if(replacestr != "" && replacestr != null){
								replace = Std.parseInt(replacestr);
								if (replace == 0) {
									replace = size;	
								}
							}
							
						}
					}
				}
			}catch (e:Error) {
				replace = size;
			}
			return replace;
		}
		
	
		/******PRIVATE FUNCTIONS******/
		
		private function startLoad():Void {
			
			//if we don't have a list of files, we need to process the index first
			if(_list_files == null){	
				loadIndex();
			}

			//we need new ones of these no matter what:
			_index_data = new Map<String,Map<String,String>>();
			_index_font = new Map<String,Fast>();
			
			//Load all the files in our list of files
			var tasklist:TaskList = new TaskList();
			for (fileNode in _list_files) {
				var value:String = "";
				if (fileNode.hasNode.file && fileNode.node.file.has.value) {
					value = fileNode.node.file.att.value;
				}
				if (value != "") {
					var task:Task;
					task = new Task("load:" + value,loadFile,[fileNode],onLoadFile);							
					tasklist.addTask(task);
					if (_check_missing) {
						task = new Task("check:" + value, loadFile, [fileNode, true], onLoadFile);
						tasklist.addTask(task);
					}
				}else {
					#if debug
						trace("ERROR: undefined file in localization index");
					#end
				}
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
		
		private function loadImage(fname:String):BitmapData{
			var img:BitmapData = null; 
			try{
				if(_directory == ""){
					img = Assets.getBitmapData("assets/locales/" + fname);			
				}else {
					#if (cpp || neko)
						if (FileSystem.exists(_directory + "locales/" + fname)) {
							img = BitmapData.load(_directory + "locales/" + fname);
						}
					#end
				}	
			}catch (e:Error) {
				#if debug
					trace("ERROR: loadImage(" + fname + ") failed");
				#end
				if (_check_missing) {
					logMissingFile(fname);
				}
			}
			return img;
		}
		
		private function loadText(fname:String):String {
			var text:String = "";
			try{
				if (_directory == "") {
					text = Assets.getText("assets/locales/" + fname);
				}else {
					#if (cpp || neko)
						if(FileSystem.exists(_directory+"locales/" + fname)){
							text = File.getContent(_directory+"locales/" + fname);
						}
					#end
				}
			}catch(e:Dynamic){
				#if debug
					trace("ERROR: loadText(" + fname + ") failed");
				#end
			}
			return text;
		}
		
		/**
		 * Loads and processes the index file
		 */
		
		private function loadIndex():Void {
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
			if (_locale == "") {
				_locale = default_locale;
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
		
		private function printIndex(id:String,index:Map < String, Dynamic > ):Void {
			trace("printIndex(" + id + ")");
			
			for (key in index.keys()) {
				trace("..." + key + "," + index.get(key));
			}
		}
				
		/**
		 * Loads a file and processes its contents in the data structure
		 * @param	fileData <file> node entry from index.xml
		 * @param	check_vs_default if true, will use to do safety check rather than immediately store the data
		 * @return
		 */
		
		private function loadFile(fileData:Fast,check_vs_default:Bool=false):String{
						
			var fileName:String = fileData.node.file.att.value;
			var fileType:String = fileName.substr(fileName.length - 3, 3);
			var fileID:String = fileData.node.file.att.id;
			
			var raw_data:String = "";
			
			var loc:String = _locale;
			if (check_vs_default) {
				loc = default_locale;
			}
			
			switch(fileType) {
				case "csv":
					var raw_data = loadText(loc + "/" + fileName);
					var delimeter:String = ",";
					if (fileData.node.file.has.delimeter) {
						delimeter = fileData.node.file.att.delimeter;
					}
					if(raw_data != "" && raw_data != null){
						processCSV(raw_data, fileID, delimeter, check_vs_default);
					}else if (_check_missing) {
						logMissingFile(fileName);
					}
				case "xml":
					if(!check_vs_default){	//xml (ie font rules) don't need safety checks
						var raw_data = loadText(loc + "/" + fileName);
						var xml:Fast = new Fast(Xml.parse(raw_data));
						if(raw_data != "" && raw_data != null){
							processXML(xml, fileID);
						}else if (_check_missing) {
							logMissingFile(fileName);
						}
					}
				case "png":
					var bmp_data = loadImage(loc + "/" + fileName);
					if (bmp_data != null) {					
						processPNG(bmp_data, fileID, check_vs_default);						
					}else if(_check_missing){
						logMissingFile(fileName);
					}
			}			
			return fileName;
		}
		
		private function onLoadFile(result:String):Void {
			_files_loaded++;
			
			if (_files_loaded == _list_files.length) {
				
				_loaded = true;
		
				if (_check_missing) {
					if (_missing_files.length == 0) {
						_missing_files = null;
					}
					var i:Int = 0;
					for (key in _missing_flags.keys()) {
						i++;
					}
					if (i == 0) {
						_missing_flags = null;
					}
				}
				
				if (_callback_finished != null) {		
					_callback_finished();					
				}
			}			
		}
		
		private function processCSV(csv:String, id:String, delimeter:String = ",", check_vs_default:Bool=false):Void {
			var csv:CSV = new CSV(csv, delimeter);
			var flag:String = "";
			var field_num:Int = csv.fields.length;
			
			if (_index_data.exists(id) == false) {
				_index_data.set(id, new Map<String,String>());	//create the index for this id
			}
			
			var _index:Map<String,String> = _index_data.get(id);
			var _real_fields:Int = 1;
			
			//count the number of non-comment fields 
			//(ignore 1st field, which is flag root field)
			for (fieldi in 1...csv.fields.length) {
				var field:String = csv.fields[fieldi];
				if (field != "comment") {	
					_real_fields++;
				}
			}
			
			//Go through each row
			for (rowi in 0...csv.grid.length) {
				var row:Array<String> = csv.grid[rowi];
				
				//Get the flag root
				flag = row[0];
				
				if(_real_fields > 2){
					//Count all non-comment fields as suffix fields to the flag root
					//Assume ("flag","suffix1","suffix2") pattern
					//Write each cell as flag_suffix1, flag_suffix2, etc.
					for (fieldi in 1...csv.fields.length) {
						var field:String = csv.fields[fieldi];
						if (field != "comment") {							
							writeIndex(_index, flag + "_" + field, row[fieldi],id,check_vs_default);
						}
					}
				}else if(_real_fields == 2) {
					//If only two non-comment fields, 
					//Assume it's the standard ("flag","value") pattern
					//Just write the first cell
					writeIndex(_index, flag, row[1], id, check_vs_default);
				}
			}
			
			csv.destroy();
			csv = null;
		}
		
		private function writeIndex(_index:Map<String,String>,flag:String,value:String,id:String,check_vs_default:Bool=false):Void{
			if (check_vs_default && _check_missing) {
				//flag exists in default locale but not current locale
				if (_index.exists(flag) == false) {
					logMissingFlag(id, flag);
					if (_replace_missing) {
						_index.set(flag, value);
					}
				}
			}else {
				//just store the flag/translation pair
				_index.set(flag, value);
			}
		}
		
		private function logMissingFlag(id:String, flag:String):Void {
			if (_missing_flags.exists(id) == false) {
				_missing_flags.set(id, new Array<String>());
			}
			var list:Array<String> = _missing_flags.get(id);
			list.push(flag);
		}
		
		private function logMissingFile(fname:String):Void {
			_missing_files.push(fname);
		}
		
		private function processXML(xml:Fast, id:String):Void {
			//what this does depends on the id
			switch(id) {
				case "fonts":
					processFonts(xml);
				default:
					//donothing
			}
		}
		
		private function processPNG(img:BitmapData, id:String, check_vs_default:Bool=false):Void {
			if (check_vs_default && _check_missing) {
				if (_index_images.exists(id) == false) {	
					//image exists in default locale but not current locale				
					logMissingFile(id);			
					//log the missing PNG file					
					if (_replace_missing) {
						//replace with default locale version if necessary
						_index_images.set(id, img);
					}
				}
			}else {
				//just store the image
				_index_images.set(id, img);
			}
		}
		
		private function processFonts(xml:Fast):Void {
			if(xml != null && xml.hasNode.data && xml.node.data.hasNode.font){
				for (fontNode in xml.node.data.nodes.font) {
					var value:String = fontNode.att.value;
					_index_font.set(value, copyFast(fontNode));
				}
			}			
		}
		
		
		/*
		private function processFile():void {			
			var filename:String = _list_files[_curr_file];
			
			CONFIG::air {
				if(_stream_open){
					_file_stream_string = _file_stream.readUTFBytes(_file_stream.bytesAvailable);
					_file_stream.close(); 
					_stream_open = false;
				}
			}
			
			if (filename != "index.xml") {
				if (_locale == "") {		//STILL undefined?
					if (default_locale == "") {
						_locale = "en-US";		//fall back to English as safeguard
					}else {
						_locale = default_locale;
					}
				}				
			}
			
			//if safety_bit is 0, just loads the thing, if it's 1, processes the data,
			//but instead of storing it, checks it against existing data to look for
			//missing stuff
			
			switch(filename) {
				case "index.xml":
					processIndex();
					break;
				case "data_achievements.csv":
					processAchievements();
					break;
				case "data_defender.csv":
					processDefender();
					break;
				case "data_enemy.csv":
				case "data_enemy_plus.csv":
					processEnemy();
					break;
				case "data_items.csv":
					processItems();
					break;
				case "data_status_effects.csv":
					processStatus();
					break;
				case "data_bonus.csv":
					processBonus();
					break;
				case "cutscenes/scripts.csv":
				case "scripts.csv":
					processCutscenes();
					break;
				case "data_system.csv":
					processSystem();
					break;
				case "data_journal.csv":
					processJournal();
					break;
				case "maps.csv":
					processGeneric(_index_data);
					break;
				case "fonts.xml":
					processFonts();
					break;
				default:
					if (filename.indexOf(".png") != -1) {
						processImage();
					}
					break;
			}
			
			if (!_do_safe_check) {
				proceed();
			}else {
				if(default_locale != locale){
					if (_safety_bit == 0) {			//first run, load safety check
						var path:String = "locales" + _slash + default_locale + _slash;							
						
						if (Main.MOD_IS_ACTIVE && _mod_file_is_next){
							path = Main.MOD_DIR.nativePath + _slash + path;
						}else {
							path = File.applicationDirectory.nativePath + _slash + path;
						}
						
							loadFile(path + _list_files[_curr_file], onFileLoaded);			
						_safety_bit = 1;
					}else {							//second run, process safety check
						_safety_bit = 0;
						proceed();
					}
				}
			}
		}
		
		
		private function writeIndex(index:Object, flag:String, value:String):void {			
			var isFallThrough:Boolean = !_mod_file_is_next;
			if (Main.MOD_IS_ACTIVE == false) {
				isFallThrough = false;			//only deal with fallthrough logic if a mod is active!
			}
			
			if (_safety_bit == 0) {
				if (isFallThrough == true) {	
					//this is a backup entry, a "fall through" for mods.
					//only write this entry if you DON'T find a value already.
					//This plugs "missing" localization holes with default text.
					if (index[flag] == null) {
						index[flag] = value;
					}
				}else{
					index[flag] = value;		//write the entry
				}
			}else {
				if (index[flag]) {	
					//it exists, great
				}else {						//check entry
					if(value != ""){
						var file:String = _list_files[_curr_file];
						var i:int = _missing_list_files.indexOf(file);
						if (i == -1) {
							_missing_list.push("****** " + file.toUpperCase() + " ******");
							_missing_list_files.push(file);
						}
						_missing_list.push(flag);						
					}
				}
			}
		}	
			
	
		
		
		*/
		
		/**
		 * Clear all the current localization data. 
		 * @param	hard Also clear all the index-related data, restoring it to a pre-initialized state.
		 */
		
		private function clearData(hard:Bool=false):Void {
			_callback_finished = null;
			
			if(_list_files != null){
				while (_list_files.length > 0) {
					_list_files.pop();
				}
				_list_files = null;
			}
			
			_loaded = false;
			_files_loaded = 0;						
			
			for (sub_key in _index_data.keys()) {				
				var sub_index:Map<String,Dynamic> = _index_data.get(sub_key);
				_index_data.remove(sub_key);				
				clearIndex(sub_index);
				sub_index = null;
			}
			
			clearIndex(_index_images);
			clearIndex(_index_font);
			
			_index_images = null;
			_index_font = null;
			
			if (hard) {
				clearIndex(_index_locales);
				clearIndex(_index_icons);
				clearIndex(_index_notes);
				_index_locales = null;
				_index_icons = null;
				_index_notes = null;
			}
			
			clearIndex(_missing_flags);
			if(_missing_files != null){
				while (_missing_files.length > 0) {
					_missing_files.pop();
				}
			}
			
			_missing_files = null;
			_missing_flags = null;
		}
		
		/**
		 * Clear an index of its contents
		 * @param	index a Map
		 */
		
		private function clearIndex(index:Map < String, Dynamic > ):Void {
			if (index == null) return;
			
			for (key in index.keys()) {
				var thing:Dynamic = index.get(key);
				index.remove(thing);
				if (Std.is(thing, BitmapData)) {
					var img:BitmapData = cast(thing, BitmapData);
					img.dispose();
					img = null;
				}else if (Std.is(thing, Array)) {
					var arr:Array<Dynamic> = cast(thing, Array<Dynamic>);
					while (arr.length > 0) {
						arr.pop();						
					}
					arr = null;
				}
				thing = null;
			}
		}
		
	}

