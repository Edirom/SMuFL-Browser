xquery version "3.0";

declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace request="http://exist-db.org/xquery/request";

import module namespace config="http://smufl-browser.edirom.de/config" at "modules/config.xqm";
import module namespace tei-funcs="http://smufl-browser.edirom.de/tei-funcs" at "modules/tei-funcs.xqm";
import module namespace json="http://www.json.org";
import module namespace functx="http://www.functx.com";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;

(:~
 : Content Negotiation 
 : Evaluate Accept header and resource suffix to serve appropriate media type
 :
 : @return ('html' | 'json' | 'tei' | 'png' | 'svg') 
~:)
declare function local:media-type() as xs:string {
    let $suffix := substring-after($exist:resource, '.')
    let $accepted-content-types := tokenize(normalize-space(request:get-header('accept')), ',\s?')
    return
        (: explicit suffix takes precedence :)
        if(matches($suffix, '^x?html?$', 'i')) then 'html'
        else if(matches($suffix, '^(xml)|(tei)$', 'i')) then 'tei'
        else if(matches($suffix, '^json$', 'i')) then 'json'
        else if(matches($suffix, '^js(onp)?$', 'i')) then 'jsonp'
        else if(matches($suffix, '^png$', 'i')) then 'png'
        else if(matches($suffix, '^svg$', 'i')) then 'svg'
        
        (: Accept header follows if no suffix is given :)
        else if($accepted-content-types[1] = ('text/html', 'application/xhtml+xml')) then 'html'
        else if($accepted-content-types[1] = ('application/xml', 'application/tei+xml')) then 'tei'
        else if($accepted-content-types[1] = ('application/json')) then 'json'
        else if($accepted-content-types[1] = ('application/javascript')) then 'jsonp'
        else if($accepted-content-types[1] = ('image/png', 'application/png', 'application/x-png')) then 'png'
        else if($accepted-content-types[1] = ('image/svg+xml')) then 'svg'
        
        (: if nothing matches fall back to TEI-XML :)
        else 'tei'
};


(:~
 : Dispatch single chars according to the requested media type
~:)
declare function local:dispatch() {
    let $resourceName := functx:substring-before-if-contains($exist:resource, '.')
    let $char :=
        if(matches($resourceName, $config:valid-unicode-range-regex, 'i')) then config:get-char-by-codepoint(upper-case($resourceName))
        else config:get-char-by-name($resourceName)
    return 
        if($char) then 
            switch(local:media-type())
                case 'tei' return $char
                case 'rdf' return local:error()
                case 'html' return local:dispatch-char($char)
                case 'json' return local:return-json($char)
                case 'jsonp' return local:return-jsonp($char)
                case 'png' return local:dispatch-image($char)
                case 'svg' return local:dispatch-svgGlyph($char)
                default return local:error()
        else local:error()
};

(:~
 : Dispatch the index of chars according to the requested media type
~:)
declare function local:dispatch-index() {
    if(functx:substring-before-if-contains($exist:resource, '.') = 'index') then 
        switch(local:media-type())
            case 'tei' return tei-funcs:index()
            case 'html' return
                <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                    <forward url="{$exist:controller}/templates/index.html"/>
                    <view>
                        <forward url="{$exist:controller}/modules/view.xql"/>
                    </view>
            		<error-handler>
            			<forward url="{$exist:controller}/templates/error-page.html" method="get"/>
            			<forward url="{$exist:controller}/modules/view.xql"/>
            		</error-handler>
                </dispatch>
            default return local:error()
    else local:error()
};

(:~
 : Return a single char as json
~:)
declare function local:return-json($char as element(tei:char)?) {
    let $serializationParameters := ('method=text', 'media-type=application/json', 'indent=no', 'encoding=utf-8')
    return
        response:stream(
                json:xml-to-json($char),
                string-join($serializationParameters, ' ')
            )
};

(:~
 : Return a single char as jsonp (http://en.wikipedia.org/wiki/JSONP)
~:)
declare function local:return-jsonp($char as element(tei:char)?) {
    let $serializationParameters := ('method=text', 'media-type=application/javascript', 'indent=no', 'encoding=utf-8')
    let $callback := request:get-parameter('callback', 'callback')
    return
        response:stream(
                normalize-space($callback) || '(' || json:xml-to-json($char) || ');',
                string-join($serializationParameters, ' ')
            )
};

(:~
 : Return a single char as html via the eXist templating module
~:)
declare function local:dispatch-char($char as element(tei:char)?) as element(exist:dispatch) {
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/templates/char.html"/>
        <view>
            <forward url="{$exist:controller}/modules/view.xql">
                <add-parameter name="id" value="{normalize-space($char/@xml:id)}"/>
            </forward>
        </view>
		<error-handler>
			<forward url="{$exist:controller}/templates/error-page.html" method="get"/>
			<forward url="{$exist:controller}/modules/view.xql"/>
		</error-handler>
    </dispatch>
};

(:~
 : Return a png image of a single char
~:)
declare function local:dispatch-image($char as element(tei:char)?) as element(exist:dispatch) {
    let $res := request:get-parameter('res', 'hi')[. = ('low', 'hi')] (: Two allowed values only :)
    let $codepoint := substring($char/tei:mapping[@type='smufl'], 3) 
    return
        if($res and $codepoint) then 
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                <forward url="{$exist:controller}/resources/images/{$res}/{$codepoint}.png">
            	   <cache-control cache="yes"/>
            	</forward>
            </dispatch>
        else local:error()
};

(:~
 : Return an SVG XML file of a single char
~:)
declare function local:dispatch-svgGlyph($char as element(tei:char)?) as element(exist:dispatch) {
    let $codepoint := substring($char/tei:mapping[@type='smufl'], 3)
    return
        if($codepoint) then 
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                <forward url="{$exist:controller}/resources/images/{$codepoint}.svg">
            	   <cache-control cache="yes"/>
            	</forward>
            </dispatch>
        else local:error()
};

(:~
 : Return the 404 error page
~:)
declare function local:error() as element(exist:dispatch) {
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<forward url="{$exist:controller}/templates/error-page.html">
    	   <cache-control cache="yes"/>
    	</forward>
    	<view>
            <forward url="{$exist:controller}/modules/view.xql">
                <set-attribute name="error-code" value="404"/>
            </forward>
        </view>
		<error-handler>
			<forward url="{$exist:controller}/templates/error-page.html" method="get"/>
			<forward url="{$exist:controller}/modules/view.xql"/>
		</error-handler>
    </dispatch>
};


(:
 : Main routines start here
:)

if ($exist:path eq '') then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="{request:get-uri()}/"/>
    </dispatch>
    
else if ($exist:path eq "/") then
    (: forward root path to index.html :)
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="index"/>
    </dispatch>

else if (starts-with($exist:path, '/index')) then 
    local:dispatch-index()
    
else if ($exist:path eq '/about.html') then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/templates/about.html"/>
        <view>
            <forward url="{$exist:controller}/modules/view.xql"/>
        </view>
		<error-handler>
			<forward url="{$exist:controller}/templates/error-page.html" method="get"/>
			<forward url="{$exist:controller}/modules/view.xql"/>
		</error-handler>
    </dispatch>

(: other resources are loaded from the app's resources collection :)
else if (starts-with($exist:path, '/resources/')) then 
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <cache-control cache="yes"/>
    </dispatch>

(: everything else will be run through the general dispatcher --
    if it fails there, an error will be returned :)
else
    local:dispatch()
