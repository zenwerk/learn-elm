port module WebSocket exposing (listen, receive, close)


port listen : String -> Cmd msg

port close : () -> Cmd msg -- 外向きポートは常に何かの引数が必要なので () を取る

port receive : (String -> msg) -> Sub msg
