xquery version "3.0";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;

import module namespace config="http://edirom.de/smufl-browser/config" at "modules/config.xqm";
import module namespace functx="http://www.functx.com";

let $ext := substring-after($exist:resource, '.')
let $resource := substring-before($exist:resource, '.')
let $char := if(matches($ext, 'html?|rdf|xml')) then config:get-char-by-name($resource) else ()
let $char := if($char) then ($char) else 
    if(matches($ext, 'html?|rdf|xml')) then config:get-char-by-codepoint($resource) else ()
(:let $log := util:log-system-out($char):)
(:let $log := util:log-system-out($ext):)
return 

if ($exist:path eq '') then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="{request:get-uri()}/"/>
    </dispatch>
    
else if ($exist:path eq "/") then
    (: forward root path to index.xql :)
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="index.html"/>
    </dispatch>

else if ($char and matches($ext, '^html?$')) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="templates/char.html"/>
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

else if ($char and matches($ext, '^xml$')) then
    $char
    
else if (matches($exist:resource, '^index.html?$')) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="templates/index.html"/>
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
else
    (: everything else is passed through :)
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <cache-control cache="yes"/>
    </dispatch>
