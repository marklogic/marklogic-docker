xquery=
xquery version "1.0-ml";
import module namespace admin = "http://marklogic.com/xdmp/admin"
at "/MarkLogic/admin.xqy";
let $config := admin:get-configuration()
let $password-to-be-verified := "test_wallet_pass"
return
admin:cluster-set-keystore-passphrase($config, "test_wallet_pass", $password-to-be-verified)