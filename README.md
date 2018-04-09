SMuFL-Browser
================

SMuFL-Browser is a web based viewer for the [Standard Music Font Layout specification](http://www.smufl.org) which facilitates searching and browsing of musical symbols. Additionally it serves as a [TEI](http://www.tei-c.org) reference for the SMuFL specification so encoders can easily add musical symbols to their texts. For that purpose a set of ANT tasks has been developed for creating TEI charDecl descriptions from SMuFL.


Docker Image
-----------

There is a Docker image available at https://hub.docker.com/r/stadlerpeter/smufl-browser/ which you can run with

```
docker run --rm -it \
    -p 8080:8080 \
    --name smufl-browser \
    stadlerpeter/smufl-browser    
```

This will make your local SMuFL-Browser available at `http://localhost:8080`.  

This image is derived from `stadlerpeter/existdb` and adds some SMuFL-browser specific settings 
for a production ready environment with SMuFL-browser as the root app.
For more details about available options see https://github.com/peterstadler/existdb-docker


Dependencies
-----------

* [Apache ANT](http://ant.apache.org)
* [XML Shell](http://www.xmlsh.org/HomePage)
* [Saxon](http://www.saxonica.com)

If you want to run the app your own you also need the [eXist-db](http://exist-db.org) XML database. Please use a recent build from 2015 since the [HTML5 serializer](https://github.com/eXist-db/exist/pull/433) has been modified.


ANT Tasks
---------

For working with the ANT tasks you need to have the above dependencies installed. Then, copy `build.properties` to `local.build.properties` and modify paths and version numbers according to your system and to match the desired SMuFL version and download location.

### Target `charDecl`

This will create a TEI file based on the template charDecl.xml.template with charDecl elements (one for each SMuFL range). This task relies on Saxon and XML Shell.

### Target `otf2png`

This will create png images from the Bravura font through a small program written by [Alexander Erhard](https://github.com/aerhard).

### Target `xar`

This will create all the above and bundle it as an eXist app package.


Credits
-------
Credits are due to Daniel Spreadbury and his great work on the SMuFL specification. 
The functionality of the SMuFL-Browser was highly inspired by James Cummings' work on the [ENRICH Gaiji Bank](http://www.manuscriptorium.com/apps/gbank/).


License
-------

This work is available under dual license: [BSD 2-Clause](http://opensource.org/licenses/BSD-2-Clause) and [Creative Commons Attribution 3.0 Unported License (CC BY 3.0)](http://creativecommons.org/licenses/by/3.0/)