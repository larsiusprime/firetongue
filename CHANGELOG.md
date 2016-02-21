2.0.0
------------------------------
* Removed all 3rd-party library dependencies
* Refactored loading logic into Getter.hx class
  * OpenFL, Lime, NME, and VanillaSys (haxe standard library for sys targets) loading methods supported by default
  * Custom loading methods can be provided by the user
* Updated documentation
* Added ability to do partial redirects with <RE>[] syntax
* Fix clearIndex() functionality on neko
* Fix "find closest locale" to match closest alphabetical match
* Fix HTML5 and OpenFL next support
* Prevent crash when using non-existent locale
* Fixed bug where <Q> is not replaced correctly with '"'
* Fixed bug in flash target
* Cleanup TSV/CSV processing
* TSV/CSV files no longer have to end each line with a delimeter
* Updated example
  * uses TSV rather than CSV
  * demonstrate missing locale

1.0.0
------------------------------
* Initial haxelib release
