xquery version "3.0";

(:~
 : A set of TEI related functions 
 :)
module namespace tei-funcs="http://smufl-browser.edirom.de/tei-funcs";

declare namespace request="http://exist-db.org/xquery/request";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";
import module namespace config="http://smufl-browser.edirom.de/config" at "config.xqm";

declare function tei-funcs:index() as document-node() {
    let $range := request:get-parameter('range', 'all')
    let $class := request:get-parameter('class', 'all')
    let $glyphname := request:get-parameter('glyphname', 'all')
    return 
        if (($range,$class,$glyphname) != 'all') then
            let $chars := 
                $config:charDecl//tei:char[.//tei:item = $class] | 
                $config:charDecl//tei:char[parent::tei:charDecl/tei:desc = $range][@xml:id] |
                $config:charDecl//id($glyphname)
            let $charDecl := tei-funcs:filter-charDecl($config:charDecl/tei:TEI, $chars)
            return 
                document {
                    tei-funcs:remove-empty-charDecl($charDecl)
                }
        else $config:charDecl 
};

declare %private function tei-funcs:filter-charDecl($element as element(), $chars as element(tei:char)*) as element()? {
    element {node-name($element)} {
        $element/@*,
        for $child in $element/node()
        return 
            if ($child instance of element(tei:char)) then 
                if($child/@xml:id = $chars/@xml:id) then tei-funcs:filter-charDecl($child, $chars)
                else ()
            else if ($child instance of element()) then tei-funcs:filter-charDecl($child, $chars)
            else $child
    }
};

declare %private function tei-funcs:remove-empty-charDecl($element as element()) as element()? {
    element {node-name($element)} {
        $element/@*,
        for $child in $element/node()
        return 
            if ($child instance of element(tei:charDecl)) then 
                if($child/tei:char) then tei-funcs:remove-empty-charDecl($child)
                else ()
            else if ($child instance of element()) then tei-funcs:remove-empty-charDecl($child)
            else $child
    }
};