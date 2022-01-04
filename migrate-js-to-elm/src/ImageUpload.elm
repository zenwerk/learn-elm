-- START:module
port module ImageUpload exposing (main)
-- END:module

-- START:imports
import Browser
import Html exposing (Html, div, input, label, text)
import Html.Attributes exposing (class, for, id, multiple, type_)
import Html.Events exposing (on) -- htmlの任意のイベントに対してハンドラを作成できる関数
import Json.Decode exposing (succeed) -- on で受け取るイベントハンドラの内容をデコードするのに必要
-- END:imports


-- START:model
type alias Model =
    ()
-- END:model


-- START:init
init : () -> ( Model, Cmd Msg )
init () =
    ( (), Cmd.none )
-- END:init


-- START:view
view : Model -> Html Msg
view model =
    div [ class "image-upload" ]
        [ label [ for "file-upload" ]
            [ text "+ Add Images" ]
        , input
            [ id "file-upload"
            , type_ "file"
            , multiple True
            , onChange UploadImages -- プロンプトからファイル選択時にイベントを発火し UploadImages が update に渡る
            ]
            []
        ]
-- END:view


-- START:msg.update
type Msg
    = UploadImages -- 画像アップロード port のための Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UploadImages ->
            (model, uploadImages ()) -- 外向きポートをキックしJS側のイベントリスナに通知する
-- END:msg.update


{-
    Cmd を返すものはElm to JavaScript な「外に向いた」ポート
    外向きポートはJS側にデータを送信する必要がない場合でも、必ず引数をとる
    ポートは Cmd を返すので、 `update` 関数で呼び出される必要がある
-}
port uploadImages : () -> Cmd msg


{-
    Elm が DOM のイベントオブジェクトから必要なプロパティをデコードして取り出すためにデコーダーが必要。
    onInput イベントなら event.target.value プロパティをデコードして文字入力欄への入力値を取得する。

    今回の onChange イベントハンドラは特に何かをデコードするべきものはないため、succeed 関数を使って
    常に成功するデコーダーを作成すればよい。
-}
onChange : msg -> Html.Attribute msg
onChange msg =
    -- on イベント名 JSONデコーダ
    on "change" (succeed msg)


-- START:subscriptions
subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
-- END:subscriptions


-- START:main
main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
-- END:main
