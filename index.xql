xquery version "3.1";

module namespace idx="http://teipublisher.com/index";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace dbk="http://docbook.org/ns/docbook";

declare variable $idx:app-root :=
    let $rawPath := system:get-module-load-path()
    return
        (: strip the xmldb: part :)
        if (starts-with($rawPath, "xmldb:exist://")) then
            if (starts-with($rawPath, "xmldb:exist://embedded-eXist-server")) then
                substring($rawPath, 36)
            else
                substring($rawPath, 15)
        else
            $rawPath
    ;

(: 2025-05-07 (EL) : Personalisation of the facets according to the degree of certainty of the data :)
declare function idx:parse-author($author) {
    if ($author[@role='presumed_author'])
    then '[' || normalize-space($author/tei:forename || ' ' || $author/tei:surname) || ']'
    else normalize-space($author/tei:forename || ' ' || $author/tei:surname)
};

declare function idx:parse-printer($printer) {
    if ($printer[@role='presumed_printer'])
    then '[' || normalize-space($printer/tei:forename || ' ' || $printer/tei:surname) || ']'
    else normalize-space($printer/tei:forename || ' ' || $printer/tei:surname)
};

declare function idx:parse-date($date) {
    if ($date[@cert='low'])
    then '[' || $date || '?]'
    else if ($date[@cert='medium'])
    then '[' || $date || ']'
    else $date
};

(:~
 : Helper function called from collection.xconf to create index fields and facets.
 : This module needs to be loaded before collection.xconf starts indexing documents
 : and therefore should reside in the root of the app.
 :)
declare function idx:get-metadata($root as element(), $field as xs:string) {
    let $header := $root/tei:teiHeader
    return
        switch ($field)
            case "title" return (
                $header//tei:monogr/tei:title[@type="short_title"]
            )
            case "author" return (
                idx:parse-author($header//tei:monogr/tei:author/tei:persName[1])
            )
            case "printer" return (
                idx:parse-printer($header//tei:monogr/tei:imprint//tei:persName[1])
            )
            case "place" return (
                idx:parse-date($header//tei:monogr/tei:imprint/tei:pubPlace[1])
            )
            case "false-place" return (
                $header//tei:monogr//tei:pubPlace[@role="false_address"]
            )
            case "date" return head((
                idx:parse-date($header//tei:imprint/tei:date)
            ))
            default return
                ()
};

declare function idx:get-genre($header as element()?) {
    let $targets := $header//tei:textClass/tei:catRef[@scheme="#genre"]/@target
    return
        array:for-each(array {$targets}, function($target) {
            let $category := id(substring($target, 2), doc($idx:app-root || "/data/taxonomy.xml"))
            return
        $category/ancestor-or-self::tei:category[parent::tei:category]/tei:catDesc
        })
};

declare function idx:get-classification($header as element()?, $scheme as xs:string) {
    for $target in $header//tei:textClass/tei:catRef[@scheme="#" || $scheme]/@target
    let $category := id(substring($target, 2), doc($idx:app-root || "/data/taxonomy.xml"))
    return
        $category/ancestor-or-self::tei:category[parent::tei:category]/tei:catDesc
};