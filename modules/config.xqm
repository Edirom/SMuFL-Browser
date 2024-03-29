xquery version "3.0";

(:~
 : A set of helper functions to access the application context from
 : within a module.
 :)
module namespace config="http://smufl-browser.edirom.de/config";

declare namespace repo="http://exist-db.org/xquery/repo";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace system="http://exist-db.org/xquery/system";
declare namespace expath="http://expath.org/ns/pkg";
declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace templates="http://exist-db.org/xquery/html-templating";

(: 
    Determine the application root collection from the current module load path.
:)
declare variable $config:app-root := 
    let $rawPath := system:get-module-load-path()
    let $modulePath :=
        (: strip the xmldb: part :)
        if (starts-with($rawPath, "xmldb:exist://")) then
            if (starts-with($rawPath, "xmldb:exist://embedded-eXist-server")) then
                substring($rawPath, 36)
            else
                substring($rawPath, 15)
        else
            $rawPath
    return
        substring-before($modulePath, "/modules")
;

declare variable $config:data-root := $config:app-root || "/data";

declare variable $config:repo-descriptor := doc(concat($config:app-root, "/repo.xml"))/repo:meta;

declare variable $config:expath-descriptor := doc(concat($config:app-root, "/expath-pkg.xml"))/expath:package;

declare variable $config:charDecl := doc(concat($config:app-root, "/data/charDecl.xml"));

declare variable $config:valid-unicode-range-regex := '^([Ee][a-fA-F0-9]{3})|(1[dD]1[a-fA-F0-9]{2})|(266[defDEF])$';

declare variable $config:server-url := 'https://smufl-browser.edirom.de';

(:~
 : Resolve the given path using the current application context.
 : If the app resides in the file system,
 :)
declare function config:resolve($relPath as xs:string) {
    if (starts-with($config:app-root, "/db")) then
        doc(concat($config:app-root, "/", $relPath))
    else
        doc(concat("file://", $config:app-root, "/", $relPath))
};

(:~
 : Returns the repo.xml descriptor for the current application.
 :)
declare function config:repo-descriptor() as element(repo:meta) {
    $config:repo-descriptor
};

(:~
 : Returns the expath-pkg.xml descriptor for the current application.
 :)
declare function config:expath-descriptor() as element(expath:package) {
    $config:expath-descriptor
};

declare %templates:wrap function config:app-title($node as node(), $model as map(*)) as text() {
    $config:expath-descriptor/expath:title/text()
};

declare function config:app-meta($node as node(), $model as map(*)) as element()* {
    <meta xmlns="http://www.w3.org/1999/xhtml" name="description" content="{$config:repo-descriptor/repo:description/text()}"/>,
    for $author in $config:repo-descriptor/repo:author
    return
        <meta xmlns="http://www.w3.org/1999/xhtml" name="creator" content="{$author/text()}"/>
};

(:~
 : For debugging: generates a table showing all properties defined
 : in the application descriptors.
 :)
declare function config:app-info($node as node(), $model as map(*)) {
    let $expath := config:expath-descriptor()
    let $repo := config:repo-descriptor()
    return
        <table class="app-info">
            <tr>
                <td>app collection:</td>
                <td>{$config:app-root}</td>
            </tr>
            {
                for $attr in ($expath/@*, $expath/*, $repo/*)
                return
                    <tr>
                        <td>{node-name($attr)}:</td>
                        <td>{$attr/string()}</td>
                    </tr>
            }
            <tr>
                <td>Controller:</td>
                <td>{ request:get-attribute("$exist:controller") }</td>
            </tr>
        </table>
};

(:~
 : Lookup char by xml:id
 : 
 : @param $name the xml:id of a SMuFl character, e.g. '_accidentalBakiyeSharp'
 : The xml:id is identical to the charName with a prefixed underscore
 : @return the corresponding tei:char element if succesful, the empty sequence otherwise
~:)
declare function config:get-char-by-id($id as xs:string?) as element(tei:char)? {
    $config:charDecl//id($id)
};

(:~
 : Lookup char by name
 : 
 : @param $name the name of a SMuFl character, e.g. 'accidentalBakiyeSharp'
 : @return the corresponding tei:char element if succesful, the empty sequence otherwise
~:)
declare function config:get-char-by-name($name as xs:string?) as element(tei:char)? {
    $config:charDecl//tei:charName[.= $name]/parent::tei:char
};

(:~
 : Lookup char by codepoint
 : Codepoint can be given with or without leading 'U+'
 : 
 : @param $codepoint the codepoint of a SMuFl character, e.g. 'E445' or 'U+E445' for convenience
 : @return the corresponding tei:char element if succesful, the empty sequence otherwise 
~:)
declare function config:get-char-by-codepoint($codepoint as xs:string?) as element(tei:char)? {
    if(starts-with($codepoint, 'U+')) then $config:charDecl//tei:char[tei:mapping = $codepoint]
    else $config:charDecl//tei:char[tei:mapping = concat('U+', $codepoint)]
};
