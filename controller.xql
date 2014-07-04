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

(: noch Request headers einbauen! :)
declare function local:dispatch-chars($resource as xs:string) {
    let $ext := substring-after($resource, '.')
    let $resourceName := substring-before($resource, '.')
    let $char :=
        if(matches($resourceName, '^[A-F0-9]{4}$')) then config:get-char-by-codepoint(concat('U+', $resourceName))
        else config:get-char-by-name($resourceName)
    return 
        if($char) then 
            switch($ext)
                case 'xml' return $char
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

else if (matches($exist:path, '^/chars.html?$')) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/templates/chars.html"/>
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

(: Resource paths starting with $shared are loaded from the shared-resources app :)
else if (contains($exist:path, "/$shared/")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="/shared-resources/{substring-after($exist:path, '/$shared/')}">
            <set-header name="Cache-Control" value="max-age=3600, must-revalidate"/>
        </forward>
    </dispatch>

(: other resources are loaded from the app's resources collection :)
else if (starts-with($exist:path, '/resources/')) then 
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <cache-control cache="yes"/>
    </dispatch>

(: everything else will result in an error page:)
else
    local:dispatch-chars($exist:resource)
