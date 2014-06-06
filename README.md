FireTongue
==========

A translation/localization framework written in Haxe

Installation 
--
Haxelib:

    haxelib install firetongue
    
Using latest git version:

    haxelib git firetongue https://github.com/larsiusprime/firetongue

Running the sample
--
Navigate to the sample directory and run:

    openfl build <platform> project.xml

Where "platform" is flash, windows, mac, etc.

Usage
--
    var tongue:FireTongue = new FireTongue();
    tongue.init("en-US",onLoaded);

    function onLoaded():Void{
        trace(tongue.get("$HELLO_WORLD"));  //outputs "Hello, World!"
    }

Of course, this assumes that you've done the proper setup.

Setup
--
In your OpenFL assets directory, create a folder setup like this:

* assets/
    * locales/
        * _flags/
        * en-US/
        * nb-NO/
        * index.xml

Note that folders like "en-US" and "nb-NO" are content folders for specific locales, in this case American English (en-US) and Norwegian Bokmål (nb-NO). You don't need those two specifically, I just used them as an example. You should provide any other locales, such as French French (fr-FR) or British English (en-GB) in the same location.

The **_flags** folder is where you should store flag icons for your locales. I strongly recommend [this set](http://www.famfamfam.com/lab/icons/flags/) from [famfamfam](http://www.famfamfam.com ), and I've included some of those in the sample project. 

The **_index.xml** file contains details about your localization setup, and the sample has an example with plenty of comments to document the procedure. 

As for your localization files themselves, the contents should look like this:

* en-US/
    * file1.tsv
    * file2.tsv
    * fonts.xml

Provide as many tsv files as you like, as well as a fonts.xml file. The TSV files contain your actual localization data, and the fonts.xml specifies font replacement rules.

Here's the en-US version of the sample projects's data.tsv file:

    flag	content
    $INSTRUCTIONS	Click a flag to load text from that locale.<N>Several files are intentionally missing from various locales.<N>This showcases the <LQ>missing file check<RQ> feature.	
    $HELLO_WORLD	Hello, World!	
    $TEST_STRING	My mom took the elevator to the defense department.	
    $MISSING_FLAGS	<X> localization flags are missing:	
    $MISSING_FILES	<X> localization files are missing:	
    $ANOTHER_STRING	Another string	
    $MORE_STRINGS	More strings	
    $LOOK_MORE_STRINGS	Look, even more strings!	

(Note that each cell ends with a TAB character, and each line ends with a TAB and then an endline)

CSV format is also allowed, which would look like this:

    "flag","content",
    "$INSTRUCTIONS","Click a flag to load text from that locale.<N>Several files are intentionally missing from various locales.<N>This showcases the <LQ>missing file check<RQ> feature.",
    "$HELLO_WORLD","Hello, World!",
    "$TEST_STRING","My mom took the elevator to the defense department.",
    "$MISSING_FLAGS","<X> localization flags are missing:",
    "$MISSING_FILES","<X> localization files are missing:",
    "$ANOTHER_STRING","Another string",
    "$MORE_STRINGS","More strings",
    "$LOOK_MORE_STRINGS","Look, even more strings!",

This creates a database of localization information, pairing "flags" with values. Instead of putting hard-coded text directly into your game code, you instead put a localization flag, like "$INSTRUCTIONS". Then, right before the text is displayed, you run FireTongue.get() and pass in your flag to get the localized string in the current locale. 

TSV/CSV Formatting
--


This is **extremely** important. You need to format these files perfectly or they won't work. 

First, read this:

[The Absolute Minimum Every Software Developer Must Know About Unicode and Character Sets (No Excuses!)](http://www.joelonsoftware.com/articles/Unicode.html)

**Use UTF-8 encoding ONLY!!!!!!**

Also, just because some spreadsheet program accepts your crazy custom TSV/CSV format doesn't mean that it's correct, and it could easily make FireTongue choke. FireTongue supports exactly two specific formats -- TSV, and CSV, subject to these rules:

###TSV
*Properly* formatted firetongue TSV files:

* Do NOT wrap cells in quotes or any other sort of formatting.
* Separate each cell with a single standard tab character, (	) 0x09 in UTF-8
    * Do not use spaces, multiple tabs, a mixture of tabs and spaces, or any other whitespace!
* End each line with a comma and endline
    * FireTongue accepts both windows and unix style endlines (theoretically) 

The TSV format is preferred because it is simpler and faster for both humans and computers to create, read, and parse. When properly formatted, no regular expressions are needed to parse TSV, only a String.split() command.

That said a specific CSV format is also available.

###CSV
*Properly* formatted firetongue CSV files:

* Wrap each cell in a standard double-quote character, ( " ), 0x22 in UTF-8
    * Do not use the single-quote ( ' ) or left/right quotes (“ ”) or anything else!
* Separate each cell with a standard comma character ( , ), 0x2C in UTF-8
* End each line with a comma and endline
    * FireTongue accepts both windows and unix style endlines (theoretically)

If you follow the above rules, you should be able to put just about anything inside of your translation strings and FireTongue will be able to parse it correctly, including commas! FireTongue is *supposed* to be smart enough to handle situations like this:

    "$EVIL_STRING","I will break it with commas, and "quotation marks" !!!",

But I wouldn't push it. Use these characters instead of quotes if you can: “ ”, or else use one of firetongue's special replacement characters to deal with these situations:

    <Q>  = Standard single quotation mark ( " )
    <LQ> = Fancy left quotation mark ( “ )
    <RQ> = Fancy right quotation mark ( ” )
    <C>  = Standard comma
    <N>  = Line break
    <T>  = Tab

FireTongue will automatically look for those characters and replace them on the fly. This is way easier than trying to get the parser to not choke on a cell with tons of standard commas, quotation marks, and line breaks inside of it.

Finally, all firetongue TSV/CSV files MUST begin with two header fields -- "flag" and "content", like this:

TSV:

    flag	content	
    
CSV:

    "flag","content",


Advanced Use
--
Here's some fancy other things you can do with FireTongue:

**Variable replacement**

Sometimes you want to print out a dynamic phrase, like, "Collect X apples!" where X could be 15, 20, anything. Usually, people do something like this:

    str = "Collect " + num_apples + " apples!";

This is a big no-no, because you're encoding grammar in the least flexibile part of your system, the code itself. Not only do words themselves change in different languages, but also grammar, word order, and sentence structure. For example, in ["Yoda-ish"](http://www.yodaspeak.co.uk/), that sentence would be "X apples, collect you must! Yeeeessss!" 

To avoid this, you let the translator specify where the variable should fall in the sentence. So in en-US it would be:

    $COLLECT_X_APPLES	Collect <X> apples!	

But in yo-DA (the fictional locale name for Dagoban Yoda-ish)

    $COLLECT_X_APPLES	<X> apples, collect you must! Yeeeessss!	

So here's how you would handle this with firetongue:

    import firetongue.Replace;

    str = fire_tongue_instance.get("$COLLECT_X_APPLES");
    str = Replace.flags(str,["<X>"],[Std.string(num_apples)]);

The "Replace" class lets you feed in an array of custom variable names that match what's in the translation string, as well as an array of corresponding replacement values. 

In this way, you can use the same invocation call to properly localize a variety of different languages with distinct grammar. As an additional tip, don't use code to create plurals, such as tacking on "s" on the end of things. Instead, create a separate locale flag for the plural version of something's name and leave that job to the translator. Because many languages have other rules like gender and case, the more you can leave the work up to the translator rather than your code, the better.

**Font replacement**

By itself, Firetongue doesn't really deal with fonts - properly loading them and using them is up to you. However, you can use FireTongue to create font replacement **rules**, which you can then look up at runtime while you are building interfaces or something, and use this to swap out both fonts and font sizes at the last minute. 

(More documentation to follow).

**Flixel-UI integration**

FireTongue and [Flixel-UI](https://github.com/haxeflixel/flixel-ui) are specifically designed to work together, though this is set up so that they don't actually depend on each other to compile and run.

A demo project, available here in [flixel-demos](https://github.com/HaxeFlixel/flixel-demos/tree/master/User%20Interface/RPG%20Interface) and on the [HaxeFlixel website](http://haxeflixel.com/demos/RPGInterface/) demonstrates this integration.

(More documentation to follow)

**Missing Files**

If firetongue can't find a file on a get() call, it will by default return that file to you. You can force it to throw an error by setting the third parameter to false;

When you load your files, you can tell FireTongue to check for missing files and flags:

    public function init(
        locale_:String,        
        finished_:Dynamic=null, 
        check_missing_:Bool=false, 
        replace_missing_:Bool = false, 
        directory_:String=""
    ):Void{
		
*Check Missing*:

    check_missing_

If this is true, FireTongue will check this locale's information against the default locale (specified in index.xml) and look for missing files and flags. It will then generate two public lists: 

    _missing_flags, _missing_files

*Replace Missing*:

    replace_missing

When a flag is found to be missing, rather than leave the entry blank, FireTongue will replace it with the version from the default locale (This only works if check missing is activated, too).
