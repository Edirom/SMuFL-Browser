SMuFL-Browser
================

SMuFL-Browser is a web based viewer for the [Standard Music Font Layout specification](http://www.smufl.org) which facilitates searching and browsing of musical symbols. Additionally it serves as a [TEI](http://www.tei-c.org) reference for the SMuFL specification so encoders can easily add musical symbols to their texts. For that purpose a set of ANT tasks has been developed for creating TEI charDecl descriptions from SMuFL.


Credits
-------
Credits are due to Daniel Spreadbruy and his great work on the SMuFL specification. 
The functionality of the SMuFL-Browser was highly inspired by James Cummings' work on the [ENRICH Gaiji Bank](http://www.manuscriptorium.com/apps/gbank/).


Dependencies
-----------

* [Apache ANT](http://ant.apache.org)
* [XML Shell](http://www.xmlsh.org/HomePage)
* [Saxon](http://www.saxonica.com)
* [ImageMagick](http://www.imagemagick.org) (only needed for creating glyph images)
* FontForge (only needed for creating glyph images)

If you want to run the app your own you also need the [eXist-db](http://exist-db.org) XML database.




ANT Tasks
---------

For working with the ANT tasks you need to have the above dependencies installed. Then, copy `build.properties` to `local.build.properties` and modify paths and version numbers according to your system and to match the desired SMuFL version and download location.

All resulting files will be stored within the `build.dir` which defaults to `./build`.

### Target `charDecl`

This will create a TEI file based on the template charDecl.xml.template with charDecl elements (one for each SMuFL range). This task relies on Saxon and XML Shell.

### Target `otf2eps`

This will create eps shapes from the Bravura font glyphs via FontForge.

### Target `eps2png`

This will create png images from the eps shapes via ImageMagick.

### Target `xar`

This will create all the above and bundle it as an eXist app package.

License
-------

This work is available under dual license: [BSD 2-Clause](http://opensource.org/licenses/BSD-2-Clause) and [Creative Commons Attribution 3.0 Unported License (CC BY 3.0)](http://creativecommons.org/licenses/by/3.0/)