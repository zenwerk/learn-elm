-- START:module
port module ImageUpload exposing (main)
-- END:module

-- START:imports
import Browser
import Html exposing (Html, div, img, input, label, li, text, ul)
import Html.Attributes exposing (class, for, id, multiple, src, type_, width)
import Html.Events exposing (on) -- htmlの任意のイベントに対してハンドラを作成できる関数
import Json.Decode exposing (succeed) -- on で受け取るイベントハンドラの内容をデコードするのに必要
-- END:imports


-- START:model
type alias Model =
    { imageUploaderId : String
    , images : List Image }
-- END:model

type alias Image =
    { url : String }


-- START:init
init : Flags -> ( Model, Cmd Msg )
init flags =
    ( Model flags.imageUploaderId flags.images, Cmd.none )
-- END:init


-- START:view
view : Model -> Html Msg
view model =
    div [ class "image-upload" ]
        [ label [ for model.imageUploaderId ]
            [ text "+ Add Images" ]
        , input
            [ id model.imageUploaderId
            , type_ "file"
            , multiple True
            , onChange UploadImages -- プロンプトからファイル選択時にイベントを発火し UploadImages が update に渡る
            ]
            []
        , ul [ class "image-upload__images" ]
            (List.map viewImage model.images)
        ]
-- END:view

viewImage : Image -> Html Msg
viewImage image =
    li [ class "image-upload__image" ]
       [ img [ src image.url
             , width 400
             ]
             []
       ]


-- START:msg.update
type Msg
    = UploadImages -- 画像アップロード port のための Msg
    | ReceiveImages (List Image) -- JS側から画像を受け取る Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UploadImages ->
            (model, uploadImages ()) -- 外向きポートをキックしJS側のイベントリスナに通知する
        ReceiveImages images ->
            ( { model | images = images }
            , Cmd.none
            )
-- END:msg.update


{-
    Cmd を返すものはElm to JavaScript な「外に向いた」ポート
    外向きポートはJS側にデータを送信する必要がない場合でも、必ず引数をとる
    ポートは Cmd を返すので、 `update` 関数で呼び出される必要がある
-}
port uploadImages : () -> Cmd msg


{-
    JSからデータを受け取る「内向き」ポート
    内向きポートは、受け取るデータについてのデコーダが不要、なんとポートの型定義からElmがデコーダを自動生成する
    画像Listを受け取ってMsgを返す関数を受け取る

    JSから {url : String} なデータが渡ってきてMsgのコンストラクタ関数に渡り、それが Sub Msg になって返されTEAが受け取る
-}
port receiveImages : (List Image -> msg) -> Sub msg


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


type alias Flags =
    { imageUploaderId : String
    , images : List Image
    }

-- START:subscriptions
subscriptions : Model -> Sub Msg
subscriptions model =
    -- ReceiveImages : (List Image) -> Msg なので receiveImages に渡すと Sub Msg を返す
    receiveImages ReceiveImages
-- END:subscriptions


-- START:main
main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
-- END:main
