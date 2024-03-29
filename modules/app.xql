xquery version "3.0";

module namespace app="http://smufl-browser.edirom.de/app";

import module namespace templates="http://exist-db.org/xquery/html-templating";
import module namespace config="http://smufl-browser.edirom.de/config" at "config.xqm";
import module namespace functx="http://www.functx.com";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace map="http://www.w3.org/2005/xpath-functions/map";

declare variable $app:entriesPerPage := 10 ;

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
    <h1>{map:get($model, 'char')/normalize-space(tei:charName)}</h1>
};

declare function app:charDesc($node as node(), $model as map(*)) as element(dl) {
    let $char := map:get($model, 'char')
    return 
        <dl class="charDesc">
            <dt>Character name</dt>
            <dd>{normalize-space($char/tei:charName)}</dd>
            <dt>Character description</dt>
            <dd>{normalize-space($char/tei:desc)}</dd>
            <dt>SMuFL codepoint</dt>
            <dd>{normalize-space($char/tei:mapping[@type='smufl'])}</dd>
            <dt>HTML entity (hex)</dt>
            <dd>{'&amp;#x' || substring-after(normalize-space($char/tei:mapping[@type='smufl']), 'U+') || ';'}</dd>
            {if($char/tei:mapping[@type='unicode']) then ( 
            <dt>Unicode</dt>,
            <dd>{normalize-space($char/tei:mapping[@type='unicode'])}</dd>)
            else ()}
            <dt>Range</dt>
            <dd>{if($char/ancestor::tei:charDecl/tei:desc) then normalize-space($char/ancestor::tei:charDecl/tei:desc) else 'n.a.'}</dd>
            <dt>Classes</dt>
            <dd>{if($char//tei:item) then string-join($char//tei:item/normalize-space(), ', ') else 'n.a.'}</dd>
            <dt>TEI code for embedding</dt>
            <dd><code>&lt;g ref="{string-join(($config:server-url, normalize-space($char/tei:charName) || '.xml'), '/')}"/&gt;</code></dd>
        </dl>
};

declare function app:charImage($node as node(), $model as map(*)) as element(img) {
    let $char := map:get($model, 'char')
    let $url := $char/tei:graphic/normalize-space(@url)
    return 
        <img src="{$url}" class="charImage"/>
};

declare 
    %templates:wrap
    %templates:default("range", "all")
    function app:ranges-list($node as node(), $model as map(*), $range as xs:string*) as element(option)* {
        for $desc in $config:charDecl//tei:desc[parent::tei:charDecl]
        let $name := normalize-space($desc)
        order by $name ascending
        return 
            <option value="{$name}">{
                if($range = $name) then attribute {'selected'} {'selected'} 
                else (),
                $name
            }</option>
};

declare 
    %templates:wrap
    %templates:default("glyphname", "all")
    function app:glyphnames-list($node as node(), $model as map(*), $glyphname as xs:string*) as element(option)* {
        for $glyph in $config:charDecl//tei:char
        let $name := normalize-space($glyph/tei:charName)
        order by $name ascending
        return 
            <option value="{$name}">{
                if($glyphname = $name) then attribute {'selected'} {'selected'} 
                else (),
                $name
            }</option>
};

declare 
    %templates:wrap 
    %templates:default("class", "all")
    function app:classes-list($node as node(), $model as map(*), $class as xs:string*) as element(option)* {
        for $cl in distinct-values($config:charDecl//tei:item)
        let $name := normalize-space($cl)
        order by $name ascending
        return 
            <option value="{$name}">{
                if($class = $name) then attribute {'selected'} {'selected'} 
                else (),
                $name
            }</option>
};

declare 
    %templates:wrap
    %templates:default("range", "all")
    %templates:default("class", "all")
    %templates:default("glyphname", "all")
    function app:list-chars($node as node(), $model as map(*), $range as xs:string*, $class as xs:string*, $glyphname as xs:string*) as map(*) {
        let $chars := 
            if(($range,$class,$glyphname) != 'all') then (
                $config:charDecl//tei:item[. = $class]/ancestor::tei:char | 
                $config:charDecl//tei:desc[. = $range]/following-sibling::tei:char[@xml:id] |
                $config:charDecl//tei:charName[. = $glyphname]/parent::tei:char
            )
            else $config:charDecl//tei:char[@xml:id]
        return 
            map { "chars": $chars }
};

declare
    %templates:default("page", "1")
    function app:one-page($node as node(), $model as map(*), $page as xs:string) as map(*) {
        let $page := if($page castable as xs:int) then xs:int($page) else 1
        return
            map { "chars": subsequence($model('chars'), ($page - 1) * 10 + 1, $app:entriesPerPage) }
};


declare
    %templates:wrap
    %templates:default("page", "1")
    function app:pagination($node as node(), $model as map(*), $page as xs:string) as element(li)* {
        let $page := if($page castable as xs:int) then xs:int($page) else 1
        let $page-link := function ($page as xs:int){
            'index.html?page=' || $page || string-join(
                request:get-parameter-names()[. != 'page'] ! (
                    '&amp;' || string(.) || '=' || string-join(
                        request:get-parameter(., ''),
                        '&amp;' || string(.) || '=')
                    ), 
                '')
            }
        let $last-page := ceiling(count($model('chars')) div $app:entriesPerPage) 
        return (
            <li>{
                if($page le 1) then (
                    attribute {'class'}{'disabled'},
                    <span>&#x00AB; previous</span>
                )
                else <a href="{$page-link($page - 1)}">&#x00AB; previous</a> 
            }</li>,
            if($page gt 3) then <li><a href="{$page-link(1)}">1</a></li> else (),
            if($page gt 4) then <li><a href="{$page-link(2)}">2</a></li> else (),
            if($page gt 5) then <li><span>…</span></li> else (),
            ($page - 2, $page - 1)[. gt 0] ! <li><a href="{$page-link(.)}">{string(.)}</a></li>,
            <li class="active"><span>{$page}</span></li>,
            ($page + 1, $page + 2)[. le $last-page] ! <li><a href="{$page-link(.)}">{string(.)}</a></li>,
            if($page + 4 lt $last-page) then <li><span>…</span></li> else (),
            if($page + 3 lt $last-page) then <li><a href="{$page-link($last-page - 1)}">{$last-page - 1}</a></li> else (),
            if($page + 2 lt $last-page) then <li><a href="{$page-link($last-page)}">{$last-page}</a></li> else (),
            <li>{
                if($page ge $last-page) then (
                    attribute {'class'}{'disabled'},
                    <span>next &#x00BB;</span>
                )
                else <a href="{$page-link($page + 1)}">next &#x00BB;</a> 
            }</li>
        )
};

declare 
    %templates:default("key", "smufl")
    function app:version($node as node(), $model as map(*), $key as xs:string) as xs:string {
        switch($key)
        case 'smufl-browser' return $config:expath-descriptor/data(@version)
        case 'smufl' return $config:charDecl//tei:num[@type='smufl-version']
        case 'bravura' return $config:charDecl//tei:num[@type='bravura-version']
        default return ''
};
