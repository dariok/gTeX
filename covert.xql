xquery version "3.1";

declare namespace tei="http://www.tei-c.org/ns/1.0";

let $fileid := request:get-parameter("fileid", "")
let $target := request:get-parameter("target", "")
let $apikey := request:get-parameter("apikey", "")

let $exportURI := "https://www.googleapis.com/drive/v3/files/" || $fileid
        || "/export?mimeType=application%2Fvnd.openxmlformats-officedocument.wordprocessingml.document&amp;key=" || $apikey

let $headers :=
    <headers>
        <header name="referer" value="exist.ulb.tu-darmstadt.de" />
    </headers>

let $exportedDoc := httpclient:get($exportURI, false(), $headers, ())
let $data := $exportedDoc/httpclient:body

(: helper functions for compression:unzip :)
let $filter := function ($path as xs:string, $data-type as xs:string, $param as item()*) as xs:boolean {
switch ($path)
  case "word/document.xml"
  case "word/comments.xml"
  case "word/endnotes.xml"
  case "word/footnotes.xml"
  case "word/numbering.xml"
  case "word/_rels/endnotes.xml.rels"
  case "word/_rels/document.xml.rels"
    return true()
  default
    return false()
}

let $entry-data := function ($path as xs:string, $data-type as xs:string, $data as item()?, $param as item()*) {
  $data
}
(: end helper functions for unzip :)

let $unpack := compression:unzip($data, $filter, (), $entry-data, ())
let $incoming :=
  <pack>{
    for $item in $unpack
      return $item}
  </pack>

return $incoming