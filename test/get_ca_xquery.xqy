xquery=
xquery version "1.0-ml"; 
    import module namespace pki = "http://marklogic.com/xdmp/pki" 
        at "/MarkLogic/pki.xqy";
    let $tid := pki:template-get-id(pki:get-template-by-name("testTemplate"))
    let $cacert := pki:generate-template-certificate-authority($tid, 365)
    let $tempcert := pki:generate-temporary-certificate($tid, 365, "bootstrap_3n", (), ())
    let $templ := pki:get-template-certificate-authority($tid)

    let $pem := $templ/pki:pem/text()
    return $pem