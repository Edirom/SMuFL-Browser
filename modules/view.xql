(:~
 : This is the main XQuery which will (by default) be called by controller.xql
 : to process any URI ending with ".html". It receives the HTML from
 : the controller and passes it to the templating system.
 :)
xquery version "3.0";

declare namespace exist="http://exist.sourceforge.net/NS/exist";

import module namespace templates="http://exist-db.org/xquery/html-templating";

(: 
 : The following modules provide functions which will be called by the 
 : templating.
 :)
import module namespace config="http://smufl-browser.edirom.de/config" at "config.xqm";
import module namespace app="http://smufl-browser.edirom.de/app" at "app.xql";

declare option exist:serialize "method=xhtml5 media-type=text/html enforce-xhtml=yes";

let $config := map {
    $templates:CONFIG_APP_ROOT : $config:app-root,
    $templates:CONFIG_STOP_ON_ERROR : true()
}

let $model := map {
    'char': config:get-char-by-id(request:get-parameter('id', ()))
}

(:
 : We have to provide a lookup function to templates:apply to help it
 : find functions in the imported application modules. The templates
 : module cannot see the application modules, but the inline function
 : below does see them.
 :)
let $lookup := function($functionName as xs:string, $arity as xs:int) {
    try {
        function-lookup(xs:QName($functionName), $arity)
    } catch * {
        ()
    }
}
(:
 : The HTML is passed in the request from the controller.
 : Run it through the templating system and return the result.
 :)
let $content := request:get-data()
let $setStatusCode := if(request:get-attribute('error-code')) then response:set-status-code(xs:int(request:get-attribute('error-code'))) else()
return
    templates:apply($content, $lookup, $model, $config)