xquery version "3.0";

declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace response="http://exist-db.org/xquery/response";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;

import module namespace config="http://edirom.de/smufl-browser/config" at "modules/config.xqm";
(:import module namespace xqjson="http://xqilla.sourceforge.net/lib/xqjson";:)
import module namespace json="http://www.json.org";
(:import module namespace functx="http://www.functx.com";:)

(:~
 : Content Negotiation 
 : Evaluate Accept header and resource suffix to serve appropriate media type
 :
 : @return 'html' or 'xml' 
~:)
declare function local:media-type() as xs:string {
    let $suffix := substring-after($exist:resource, '.')
    let $accepted-content-types := tokenize(normalize-space(request:get-header('accept')), ',\s?')
    return
        (: explicit suffix takes precedence :)
        if(matches($suffix, '^x?html?$')) then 'html'
        else if(matches($suffix, '^(xml)|(tei)$')) then 'tei'
        else if(matches($suffix, '^js(on)?$')) then 'json'
        
        (: Accept header follows if no suffix is given :)
        else if($accepted-content-types[1] = ('text/html', 'application/xhtml+xml')) then 'html'
        else if($accepted-content-types[1] = ('application/xml', 'application/tei+xml')) then 'xml'
        else if($accepted-content-types[1] = ('application/json')) then 'json'
        
        (: if nothing matches fall back to xml :)
        else 'tei'
};

declare function local:dispatch-chars() {
(:    let $ext := substring-after($resource, '.'):)
    let $resourceName := substring-before($exist:resource, '.')
    let $char :=
        if(matches($resourceName, '^[A-F0-9]{4}$')) then config:get-char-by-codepoint(concat('U+', $resourceName))
        else config:get-char-by-name($resourceName)
    return 
        if($char) then 
            switch(local:media-type())
                case 'tei' return $char
                case 'rdf' return local:error()
                case 'html' return local:dispatch-char($char)
                case 'json' return local:return-json($char)
                default return local:error()
        else local:error()
};

declare function local:return-json($char as element(tei:char)?) {
    let $serializationParameters := ('method=text', 'media-type=text/javascript', 'indent=no', 'omit-xml-declaration=no', 'encoding=utf-8')
    return
        response:stream(
                json:xml-to-json($char),
                string-join($serializationParameters, ' ')
            )
};

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

declare function local:error() as element(exist:dispatch) {
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<forward url="{$exist:controller}/templates/error-page.html">
    	   <cache-control cache="yes"/>
    	</forward>
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
        <redirect url="index.html"/>
    </dispatch>

else if (matches($exist:path, '^/index.html?$')) then
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

else if (matches($exist:path, '^/about.html?$')) then
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

(: other (during development) resources are loaded from the app's components collection :)
(:else if (starts-with($exist:path, '/components/')) then 
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <cache-control cache="yes"/>
    </dispatch>:)
    
(: everything else will be run through the char-dispatcher --
    if it fails there, an error will be returned :)
else
    local:dispatch-chars()
