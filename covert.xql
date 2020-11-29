xquery version "3.1";

declare namespace http     = "http://expath.org/ns/http-client";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace pkg    = "http://schemas.microsoft.com/office/2006/xmlPackage";
declare namespace tei    = "http://www.tei-c.org/ns/1.0";

declare option output:method "text";
declare option output:media-type "text/text";

let $fileid := request:get-parameter("fileid", "")
let $target := request:get-parameter("target", "")
let $apikey := request:get-parameter("apikey", "")

let $exportURI := "https://www.googleapis.com/drive/v3/files/" || $fileid
        || "/export?mimeType=application%2Fvnd.openxmlformats-officedocument.wordprocessingml.document&amp;key=" || $apikey

let $request :=
    <http:request method="get">
        <http:header name="referer" value="exist.ulb.tu-darmstadt.de" />
    </http:request>

let $exportedDoc := http:send-request($request, $exportURI)
let $data := $exportedDoc[2]

return if ($exportedDoc[1]/@status eq '200')
then
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
      <pkg:part pkg:name="/{$path}">
        <pkg:xmlData>
          {
            $data
          }
        </pkg:xmlData>
      </pkg:part>
    }
    (: end helper functions for unzip :)
    
    let $unpack := compression:unzip($data, $filter, (), $entry-data, ())
    let $incoming :=
      <pkg:package>{
        $unpack
      }</pkg:package>
    
    let $debug := xmldb:store("/db/apps/googleTex", "word.xml", $incoming)
    let $attr := <attributes><attr name="http://saxon.sf.net/feature/recoveryPolicyName" value="recoverSilently" /></attributes>
    let $params := <parameters/>
    
    let $w1 := transform:transform($incoming, doc('w2tei/wt0.xsl'), $params)
    let $w2 := transform:transform($w1, doc('w2tei/wt1.xsl'), $params)
    let $w3 := transform:transform($w2, doc('w2tei/wt2.xsl'), $params) 
    
    let $tex := transform:transform($w3, doc("tei-transcript-tex.xsl"), $params)
    
    return $tex
else
    util:base64-decode($exportedDoc[2])