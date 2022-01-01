-- START:module
-- portモジュールの宣言
-- portモジュールとは、JavaScript と Elm が通信するのに必要な共用インターフェース（port）をエクスポートするもの
port module WebSocket exposing (listen, receive)
-- END:module


-- START:ports
-- Cmd を返すものを「外に向けた」ポートという | Elm --data--> JavaScript
-- JS側へWSサーバーのURLを送信する
port listen : String -> Cmd msg


-- Sub を返すものを「内に向けた」ポートという | JavaScript --data--> Elm
-- WS からのデータをJSから受信する
-- Sub型はElmにTEAの外側から情報を受け取ることを指示する
-- 受け取り時に Sub 時に指定した msg を update に渡す
port receive : (String -> msg) -> Sub msg
-- END:ports
