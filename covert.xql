xquery version "3.1";

declare namespace tei="http://www.tei-c.org/ns/1.0";

let $fileid := request:get-parameter("fileid", "")
let $target := request:get-parameter("target", "")
let $apikey := request:get-parameter("apikey", "")

let $exportURI := "https://www.googleapis.com/drive/v3/files/" || $fileid
        || "/export?mimeType=application%2Fvnd.openxmlformats-officedocument.wordprocessingml.document&amp;key=" || $apikey

let $headers := <headers>
        <header name="referer" value="exist.ulb.tu-darmstadt.de" />
    </headers>

let $exportedDoc := httpclient:get($exportURI, false(), $headers, ())

return util:base64-decode($exportedDoc/httpclient:body)
