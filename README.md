FireTongue
==========

A framework-agnostic translation/localization library for Haxe

Installation 
--
Haxelib:

    haxelib install firetongue
    
Using latest git version:

    haxelib git firetongue https://github.com/larsiusprime/firetongue

Running the sample
--
Navigate to the sample directory, and run:

    lime test <platform>

Where "platform" is flash, windows, mac, linux, neko, html5, etc.

Although the included samples uses OpenFL, Firetongue works with any Haxe framework (or no framework at all!)

Usage
--

First, create a new firetongue instance:

```haxe
    var tongue:FireTongue = new FireTongue();
```

Passing no parameters to the Firetongue constructor will make it try to guess your framework for the purpose of loading your files, but you can specify the framework yourself, and/or provide your own loading functions in the Firetongue constructor.

Then, initialize it with your chosen locale and a callback:
```haxe
    tongue.init("en-US",onLoaded);
   
    ...
    
    function onLoaded():Void{
        trace(tongue.get("$HELLO_WORLD","data"));  
        //outputs "Hello, World!" 
        //(which is stored in the flag $HELLO_WORD in a file indexed by context id "data")
    }
```

Of course, this assumes that you've done the proper setup.

Setup
--
In your OpenFL assets directory, create a folder setup like this:

* assets/
    * locales/
        * _icons/
        * en-US/
        * nb-NO/
        * index.xml

Note that folders like "en-US" and "nb-NO" are content folders for specific locales, in this case American English (en-US) and Norwegian Bokmål (nb-NO). You don't need those two specifically, I just used them as an example. You should provide any other locales, such as French French (fr-FR) or British English (en-GB) in the same location.

The **_icons** folder is where you can optionally store icons for your locales.

*NOTE: In previous releases this folder was called "_flags", and for backwards compatibility reasons, using the old folder name will still work. However, after talking with a few friends and doing some research, I'm no longer recommending using national flags as icons for languages by default.*

The **_index.xml** file contains details about your localization setup, and the sample has an example with plenty of comments to document the procedure. 

#### Contexts:

Notably, at the beginning of your index.xml you should list the files you are loading:

````xml
<file id="data" value="data.tsv"/>
<file id="data" value="more_data.tsv"/>
<file id="other" value="other_data.tsv"/> 
````

This loads your data into different "contexts," in case you have the same flags in different files. The context is specified by the "id" attribute -- you can think of this as similar to a "namespace."

Whenever you call the FireTongue.get() function, the second parameter specifies the context, and its default value is "data" if not specified.

**YOU MUST** supply a proper context id for your files, and if you choose some value other than "data" you *must* specify it when you call FireTongue.get().

---

As for your localization files themselves, the contents should look like this:

* en-US/
    * file1.tsv
    * file2.tsv
    * fonts.xml

Provide as many tsv files as you like, as well as a fonts.xml file. The TSV files contain your actual localization data, and the fonts.xml specifies font replacement rules.

Here's the en-US version of the sample projects's data.tsv file:

```tsv
    flag	content
    $INSTRUCTIONS	Click a flag to load text from that locale.<N>Several files are intentionally missing from various locales.<N>This showcases the <LQ>missing file check<RQ> feature.	
    $HELLO_WORLD	Hello, World!	
    $TEST_STRING	My mom took the elevator to the defense department.	
    $MISSING_FLAGS	<X> localization flags are missing:	
    $MISSING_FILES	<X> localization files are missing:	
    $ANOTHER_STRING	Another string	
    $MORE_STRINGS	More strings	
    $LOOK_MORE_STRINGS	Look, even more strings!
```

(Note that each cell ends with a TAB character, and each line ends with a TAB and then an endline)

CSV format is also allowed, which would look like this:

```csv
    "flag","content",
    "$INSTRUCTIONS","Click a flag to load text from that locale.<N>Several files are intentionally missing from various locales.<N>This showcases the <LQ>missing file check<RQ> feature.",
    "$HELLO_WORLD","Hello, World!",
    "$TEST_STRING","My mom took the elevator to the defense department.",
    "$MISSING_FLAGS","<X> localization flags are missing:",
    "$MISSING_FILES","<X> localization files are missing:",
    "$ANOTHER_STRING","Another string",
    "$MORE_STRINGS","More strings",
    "$LOOK_MORE_STRINGS","Look, even more strings!",
```

This creates a database of localization information, pairing "flags" with values. Instead of putting hard-coded text directly into your application code, you instead put a localization flag, like "$INSTRUCTIONS". Then, right before the text is displayed, you run FireTongue.get() and pass in your flag to get the localized string in the current locale. 

TSV/CSV Formatting
--


This is **extremely** important. You need to format these files perfectly or they won't work. 

First, read this:

[The Absolute Minimum Every Software Developer Must Know About Unicode and Character Sets (No Excuses!)](http://www.joelonsoftware.com/articles/Unicode.html)

**Use UTF-8 encoding ONLY!!!!!!**

Also, just because some spreadsheet program accepts your crazy custom TSV/CSV format doesn't mean that it's correct, and it could easily make FireTongue choke. FireTongue supports exactly two specific formats -- TSV, and CSV, subject to these rules:

### TSV
*Properly* formatted firetongue TSV files:

* Do NOT wrap cells in quotes or any other sort of formatting.
* Separate each cell with a single standard tab character, (	) 0x09 in UTF-8
    * Do not use spaces, multiple tabs, a mixture of tabs and spaces, or any other whitespace!
* End each line with an endline
    * FireTongue accepts both windows and unix style endlines (theoretically) 
    * *(Previously you needed to end each line with a (TAB + endline), firetongue now works with or without this)*
* Do NOT include line breaks within cells. Use the special firetongue token \<N\> instead.

The TSV format is preferred because it is simpler and faster for both humans and computers to create, read, and parse. When properly formatted, no regular expressions are needed to parse TSV, only a String.split() command.

All that said, a specific CSV file format is also supported.

### CSV
*Properly* formatted firetongue CSV files:

* Wrap each cell in a standard double-quote character, ( " ), 0x22 in UTF-8
    * Do not use the single-quote ( ' ) or left/right quotes (“ ”) or anything else!
* Separate each cell with a standard comma character ( , ), 0x2C in UTF-8
* End each line with an endline
    * FireTongue accepts both windows and unix style endlines (theoretically)
     * *(Previously you needed to end each line with a (comma + endline), firetongue now works with or without this)*

If you follow the above rules, you should be able to put just about anything inside of your translation strings and FireTongue will be able to parse it correctly, including commas! FireTongue is *supposed* to be smart enough to handle situations like this:

```csv
    "$EVIL_STRING","I will break it with commas, and "quotation marks" !!!",
```

But I wouldn't push it. Use these characters instead of quotes if you can: “ ”, or else use one of firetongue's special replacement characters to deal with these situations:

    <Q>  = Standard single quotation mark ( " )
    <LQ> = Fancy left quotation mark ( “ )
    <RQ> = Fancy right quotation mark ( ” )
    <C>  = Standard comma
    <N>  = Line break
    <T>  = Tab

FireTongue will automatically look for those characters and replace them on the fly. This is way easier than trying to get the parser to not choke on a cell with tons of standard commas, quotation marks, and line breaks inside of it.

Finally, all firetongue TSV/CSV files should begin with just two header fields -- "flag" and "content", like this:

TSV:

```tsv
    flag	content
```
    
CSV:

```csv
    "flag","content"
```

Alternately, if you supply more than one content column the field names will be treated as as automatic suffixes appended to the root flag.

i.e, this:

```tsv
    flag	name	description	effect
    $POTION	potion	a green potion	heals 15 HP
```

...is equivalent to this:

```tsv
    flag	content
    $POTION_NAME	potion
    $POTION_DESCRIPTION	a green potion
    $POTION_EFFECT	heals 15 HP
```


#### Exporting TSV files from Excel

First, click "save as --> other formats":<br>
![](/readme_assets/excel_saveas.png)

Select Text (tab delimeted)<br>
![](/readme_assets/excel_tsv.png)

Even though this is marked as a .txt file, it is really a TSV format. Firetongue assumes all ".txt" files are TSV-formatted.

### Exporting TSV files from LibreOffice

First, click "Save as", then select CSV Format. In LibreOffice, TSV format is a special kind of CSV, so both formats start with the same option.<br>
![](/readme_assets/libre_csv.png)

Enter ".tsv" as the file extension and make sure to check "automatic file name extension" and "edit filter settings".<br>
![](/readme_assets/libre_tsv.png)

You'll see something like this come up. It has already select {Tab} as the delimeter for you! Make sure the character set is Unicode (UTF-8), and make sure Text delimeter is blank. (It might be a quotation mark). Make sure "quote all text cells" is NOT checked.<br>
![](/readme_assets/libre_tsv_2.png)

### Exporting CSV files

We recommend you use TSV files as they are the best supported, fastest parsing, and least bug-prone format.

If you insist on making CSV files, you can generate them from Excel and LibreOffice in a simlar way to the TSV process outline above. 

Do note that Excel in particular is not recommended for CSV files as it likes to only selectively quote fields (ie, it only puts quotation marks around fields if they have a comma in them), whereas Firetongue's CSV format requires ALL fields to be quoted. Excel seems to do okay if you stick to the TSV file format.

LibreOffice gives you full control over the export of TSV/CSV files, letting you set field and text delimters and quoting rules.

Advanced Use
--
Here's some fancy other things you can do with FireTongue:

**Variable replacement**

Sometimes you want to print out a dynamic phrase, like, "Collect X apples!" where X could be 15, 20, anything. Usually, people do something like this:

```haxe
    str = "Collect " + num_apples + " apples!";
```

This is a big no-no, because you're encoding grammar in the least flexibile part of your system, the code itself. Not only do words themselves change in different languages, but also grammar, word order, and sentence structure. For example, in ["Yoda-ish"](http://www.yodaspeak.co.uk/), that sentence would be "X apples, collect you must! Yeeeessss!" 

To avoid this, you let the translator specify where the variable should fall in the sentence. So in en-US it would be:

```tsv
    $COLLECT_X_APPLES	Collect <X> apples!
```

But in yo-DA (the fictional locale name for Dagoban Yoda-ish)

```tsv
    $COLLECT_X_APPLES	<X> apples, collect you must! Yeeeessss!	
```

So here's how you would handle this with firetongue:

```haxe
    import firetongue.Replace;

    str = fire_tongue_instance.get("$COLLECT_X_APPLES");
    str = Replace.flags(str,["<X>"],[Std.string(num_apples)]);
```

The "Replace" class lets you feed in an array of custom variable names that match what's in the translation string, as well as an array of corresponding replacement values. 

In this way, you can use the same invocation call to properly localize a variety of different languages with distinct grammar. As an additional tip, don't use code to create plurals, such as tacking on "s" on the end of things. Instead, create a separate locale flag for the plural version of something's name and leave that job to the translator. Because many languages have other rules like gender and case, the more you can leave the work up to the translator rather than your code, the better.

As a further example, consider a scenario where you want to print something like this:

    "1 red fish"
    "2 blue fish"
    
You should *not* do it like this:

```haxe
string = count + color + noun;
```

Here we've got an unknown number and an unknown adjective, both of which could change how the noun appears in various different languages, and this doesn't even consider gender, case, and other messy issues with declention. Trying to account for all this complexity in code is madness, so a smarter approach might be to use the code to generate localization flag *permutations.* 

For instance -- if count, colors and nouns are chosen from a known set, then you could set up localization flags like this:

```tsv
    $1_RED_FISH	1 red fish
    $2_RED_FISH	2 red fish
    $1_BLUE_FISH	1 blue fish
    $2_BLUE_FISH	2 blue fish
    $1_RED_CAT	1 red cat
    $2_RED_CAT	2 red cats
    $1_BLUE_CAT	1 blue cat
    $2_BLUE_CAT	2 blue cats
```

And construct your get call like this:

```haxe
flag = "$"+count+"_"+color+"_"+noun;
string = ft.get(flag);
```

As you can see above, even in English the word "cat" differs from "fish" in how the plural case should be treated. A system like this allows you to offload the complexity of word interaction and sentence structure to your translator, as it should be.

As a final note, Firetongue is not magic and is not a replacement for foresight and careful design. Consider MySQL -- it's a powerful tool to store & look up database information, but you still have to carefully design your database schema yourself. Firetongue is the same way -- it has tools to enable advanced workflows with flexibility for the widest possibility of languages, but ultimately getting those details right for your project and languages is up to you.

**Redirect tokens**

Sometimes you'll have a lot of repeated words or phrases in your localizations, but you still want to have unique flags for each entry because different languages might have different homonyms. For example, English has the words "Meat" and "Flesh", but German only has the word "Fleisch" for both of those.

en-US:
```tsv
$MEAT	meat
$FLESH	flesh
```

de-DE:
```tsv
$MEAT	Fleisch
$FLESH	Fleisch
```

This can build up to a lot of repetition over time. So, you can use redirect flags to make firetongue use the same entry in more than one place:

```tsv
$MEAT	Fleisch
$FLESH	<RE>$MEAT
```

This way the translator only needs to enter the word "fleisch" once and it will return correctly when either the `$MEAT` or `$FLESH` flag is requested. This cuts down on duplication errors.

The `<RE>$FLAG` syntax will redirect the *entire entry*, and only works if the cell begins with `<RE>` followed by a valid localization flag (no whitespace in between) and nothing else after.

There is an alternate syntax if you want to use redirection to apply to only part of an entry:

en-US:
```tsv
$GOBLIN	goblin
$ANGRY_GOBLIN angry <RE>[$GOBLIN]
$CRAZY_GOBLIN crazy <RE>[$GOBLIN]
$UGLY_GOBLIN ugly <RE>[$GOBLIN]
```

In this example `$ANGRY_GOBLIN` will return `angry goblin`. Again, don't try to be too clever with this, just use it to cut down on basic copy & paste tedium. I've found it's quite useful for frequently repeated large blocks of text, like enemy descriptions that are shared by multiple enemy types.

For this syntax to work, a cell must contain the `<RE>` token, immediately followed by a square-bracketed valid localization flag, like this: `[$SOME_FLAG]`. The entire `<RE>[$SOME_FLAG]` string will be replaced by the redirected text. You can have multiple of these in a single cell.

**User Experience & Index Strings**

When your application first loads up, you might not be able to accurately assume the user's native language. We've found a best practice is to present something like this:

![Localization prompt from *Defender's Quest*](/readme_assets/dqlocale.png)

- A default locale is chosen to initialize Firetongue (in this case "en-US")
- A list of locales is presented to the user, each locale line consisting of:
  - A regional flag image
  - The native name for the language ("English", "Español", "Italiano")
  - In parenthesis, the localized name for the language ("Spanish", "Italian")
  - The localized name of the region ("Spain", "Italy")
  
Selecting a new locale should update the menu choices in real time. This makes it easy for the user to recognize and select their preferred language, even if they cannot read the default language. It also keeps the user from getting hopelessly lost if they make a mistake.

Firetongue does not provide any such interface (nor should it as it is not a GUI library), but it makes it easy to build one.

`getIndexString(targetLocale,indexString)` can fetch these sorts of labels by passing a locale and a member of the `IndexString` enum:

```haxe
enum IndexString
{
	TheWordLanguage;
	TheWordRegion;
	Language;
	LanguageNative;
	Region;
	RegionNative;
	LanguageBilingual;
	LanguageRegion;
	LanguageRegionNative;
}
```

The only file necessary to generate these values is your properly filled index.xml file.

```xml
	<!--American English-->
	<locale id="en-US" is_default="true" sort="0">	
		<contributors value="Lars Doucet, Level Up Labs"/>
		<ui language="Language" region="Region" accept="Okay" />
		<label id="en-US,en-GB,en-CA" language="English" region="United States"/>
		<label id="nb-NO" language="Engelsk" region="U.S.A."/>
	</locale>
	
	<!--Norwegian Bokmål-->
	<locale id="nb-NO" sort="6">
		<contributors value="Lars Doucet, Level Up Labs"/>
		<ui language="Språk" region="Område"/>
		<label id="en-US,en-GB,en-CA,yo-DA" language="Norwegian" region="Norway (Bokmål)"/>
		<label id="nb-NO" language="Norsk" region="Norge (Bokmål)"/>
	</locale>
```

You can alse define custom locale notes (for i.e. tooltips) in index.xml:

```xml
	<note id="volunteer">
		<!--This means that a fan or other volunteer submitted this to us-->
		<text id="en-US,en-GB,en-CA,yo-DA" title="VOLUNTEER" body="This is a volunteer fan translation.$N$NContributors:"/>
		<text id="nb-NO" title="FRIVILLIG" body="Dette er en frivillig oversettelse.$N$NBidragsytere:"/>
	</note>

	<note id="official">
		<!--This means that we solicited and paid the translator for an official translation-->
		<text id="en-US,en-GB,en-CA,yo-DA" title="OFFICIAL" body="This is an official (paid) translation.$N$NContributors:"/>
		<text id="nb-US" title="OFFISIELL" body="Dette er en offisiell (betalt) oversettelse.$N$NBidragsytere:"/>
	</note>
```

...and fetch them with `getNoteTitle(locale,id)` and `getNoteBody(locale,id)`.

These particular localization metadata values are specified in index.xml rather than in TSV/CSV files to aid with the bootstrapping process.

**Font replacement**

By itself, Firetongue doesn't really deal with fonts - properly loading them and using them is up to you. However, you can use FireTongue to create font replacement **rules**, which you can then look up at runtime while you are building interfaces or something, and use this to swap out both fonts and font sizes at the last minute. 

Your fonts.xml file should look something like this:

````xml
<?xml version="1.0" encoding="utf-8" ?>
<data>
	<font value="verdana" replace="arial">
	    <size value="12" replace="14"/>
	    <size value="13" replace="16"/>
	</font>
</data>
````

Then at runtime you can call:

```haxe
var oldfont = "verdana";
var newfont = tongue.getFont(oldfont);  //returns "comicsans"

var oldsize = 12;
var newsize = tongue.getFontSize(oldsize); //returns 14
```

You would most likely want to integrate this with a user interface library. In practice this can be used to make, say, German text smaller by default, or to put in a different font for cyrillic text with Russian, support asian font sets, etc.

**Flixel-UI integration**

FireTongue and [Flixel-UI](https://github.com/haxeflixel/flixel-ui) are specifically designed to work together, though this is set up so that they don't actually depend on each other to compile and run.

A demo project, available here in [flixel-demos](https://github.com/HaxeFlixel/flixel-demos/tree/master/UserInterface/RPGInterface/source) and on the [HaxeFlixel website](http://haxeflixel.com/demos/RPGInterface/) demonstrates this integration.

For more information, see Flixel-UI.

**Missing Files**

If firetongue can't find a file on a get() call, it will by default return that file to you. You can force it to throw an error by setting the third parameter to false;

When you load your files, you can tell FireTongue to check for missing files and flags:

```haxe
    public function init(
        locale_:String,        
        finished_:Dynamic=null, 
        check_missing_:Bool=false, 
        replace_missing_:Bool = false, 
        directory_:String=""
    ):Void{
```
		
*Check Missing*:

    check_missing_

If this is true, FireTongue will check this locale's information against the default locale (specified in index.xml) and look for missing files and flags. It will then generate two public lists: 

    _missing_flags, _missing_files

*Replace Missing*:

    replace_missing

When a flag is found to be missing, rather than leave the entry blank, FireTongue will replace it with the version from the default locale (This only works if check missing is activated, too).
