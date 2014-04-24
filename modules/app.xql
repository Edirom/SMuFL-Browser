xquery version "3.0";

module namespace app="http://edirom.de/smufl-browser/templates";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://edirom.de/smufl-browser/config" at "config.xqm";
import module namespace functx="http://www.functx.com";

declare namespace tei="http://www.tei-c.org/ns/1.0";

(:~
 : This is a sample templating function. It will be called by the templating module if
 : it encounters an HTML element with an attribute data-template="app:test" 
 : or class="app:test" (deprecated). The function has to take at least 2 default
 : parameters. Additional parameters will be mapped to matching request or session parameters.
 : 
 : @param $node the HTML node with the attribute which triggered this call
 : @param $model a map containing arbitrary data - used to pass information between template calls
 :)
declare function app:test($node as node(), $model as map(*)) {
    <p>Dummy template output generated by function app:test at {current-dateTime()}. The templating
        function was triggered by the class attribute <code>class="app:test"</code>.</p>
};

declare function app:charID($node as node(), $model as map(*)) as element(h1) {
    <h1>{map:get($model, 'char')/normalize-space(@xml:id)}</h1>
};

declare function app:charDesc($node as node(), $model as map(*)) as element(dl) {
    let $char := map:get($model, 'char')
    return 
        <dl class="charDesc">
            <dt>Character name</dt>
            <dd>{normalize-space($char/tei:charName)}</dd>
            <dt>Range</dt>
            <dd>{normalize-space($char/ancestor::tei:charDecl/tei:desc)}</dd>
            <dt>SMuFL codepoint</dt>
            <dd>{normalize-space($char/tei:mapping[@type='smufl'])}</dd>
            <dt>HTML entity (hex)</dt>
            <dd>{'&amp;#x' || substring-after(normalize-space($char/tei:mapping[@type='smufl']), 'U+') || ';'}</dd>
            {if($char/tei:mapping[@type='unicode']) then ( 
            <dt>Unicode</dt>,
            <dd>{normalize-space($char/tei:mapping[@type='unicode'])}</dd>)
            else ()}
            <dt>Classes</dt>
            <dd>{string-join($char//tei:item/normalize-space(), ', ')}</dd>
            <dt>TEI code for embedding</dt>
            <dd><code>&lt;g ref="{'http://edirom.de/smufl-browser/' || normalize-space($char/@xml:id) || '.xml'}"/&gt;</code></dd>
        </dl>
};

declare function app:charImage($node as node(), $model as map(*)) as element(img) {
    let $char := map:get($model, 'char')
    let $url := functx:substring-after-last($char/tei:graphic/normalize-space(@url), '/')
    return 
        <img src="{concat('resources/images/', $url)}" class="charImage"/>
};

declare %templates:wrap function app:ranges-list($node as node(), $model as map(*)) as element(option)* {
    let $ranges := $config:charDecl//tei:desc
    return 
        for $range in $ranges
        order by $range ascending
        return 
            <option>{normalize-space($range)}</option>
};

declare %templates:wrap function app:glyphnames-list($node as node(), $model as map(*)) as element(option)* {
    let $glyphs := $config:charDecl//tei:char
    return 
        for $glyph in $glyphs
        order by $glyph/@xml:id ascending
        return 
            <option>{normalize-space($glyph/@xml:id)}</option>
};

declare %templates:wrap function app:classes-list($node as node(), $model as map(*)) as element(option)* {
    let $classes := distinct-values($config:charDecl//tei:item)
    return 
        for $class in $classes
        order by $class ascending
        return 
            <option>{normalize-space($class)}</option>
};

declare %templates:wrap function app:list-chars($node as node(), $model as map(*)) as map(*){
    map { "chars" := subsequence($config:charDecl//tei:char, 1, 20) }
};

