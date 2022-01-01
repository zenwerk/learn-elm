module Picshare exposing (main)

import Browser
import Html exposing (..)
import Html.Attributes exposing (class, disabled, placeholder, src, type_, value)
import Html.Events exposing (onClick, onInput, onSubmit)
-- START:imports
import Http
-- END:imports
import Json.Decode exposing (Decoder, bool, int, list, string, succeed)
import Json.Decode.Pipeline exposing (hardcoded, required)


type alias Id =
    Int


type alias Photo =
    { id : Id
    , url : String
    , caption : String
    , liked : Bool
    , comments : List String
    , newComment : String
    }


type alias Model =
    Photo


photoDecoder : Decoder Photo
photoDecoder =
    succeed Photo
        |> required "id" int
        |> required "url" string
        |> required "caption" string
        |> required "liked" bool
        |> required "comments" (list string)
        |> hardcoded ""


baseUrl : String
baseUrl =
    "https://programming-elm.com/"


initialModel : Model
initialModel =
    { id = 1
    , url = baseUrl ++ "1.jpg"
    , caption = "Surfing"
    , liked = False
    , comments = [ "Cowabunga, dude!" ]
    , newComment = ""
    }


-- START:init
-- () -> (初期状態, 初期実行コマンド)
init : () -> ( Model, Cmd Msg )
init () =
    ( initialModel, fetchFeed )
-- END:init


-- START:fetchFeed
-- Cmd(コマンド型)は外界とのやり取りが発生し副作用が発生する処理に対して適用する
-- コマンドは、TEAアプリに対して送信され、TEAアプリが外部ウェブAPIに対して実際のリクエストを行う
-- コマンドは実行結果の Msg を update 関数に渡し状態を更新する
fetchFeed : Cmd Msg
fetchFeed =
    -- Http.get : { expect : Http.Expect msg, url : String } -> Cmd msg
    -- msg はコマンドによって生成しうるメッセージの型を表す
    -- fetchFeed の場合 msg は LoadFeed を返す
    Http.get
        { url = baseUrl ++ "feed/1"
          -- リクエストしたデータをどのように受け取りたいか
          -- photoDecoder の結果を LadFeedコンストラクタでラップして返す
        , expect = Http.expectJson LoadFeed photoDecoder
        }
-- END:fetchFeed


viewLoveButton : Model -> Html Msg
viewLoveButton model =
    let
        buttonClass =
            if model.liked then
                "fa-heart"

            else
                "fa-heart-o"
    in
    div [ class "like-button" ]
        [ i
            [ class "fa fa-2x"
            , class buttonClass
            , onClick ToggleLike
            ]
            []
        ]


viewComment : String -> Html Msg
viewComment comment =
    li []
        [ strong [] [ text "Comment:" ]
        , text (" " ++ comment)
        ]


viewCommentList : List String -> Html Msg
viewCommentList comments =
    case comments of
        [] ->
            text ""

        _ ->
            div [ class "comments" ]
                [ ul []
                    (List.map viewComment comments)
                ]


viewComments : Model -> Html Msg
viewComments model =
    div []
        [ viewCommentList model.comments
        , form [ class "new-comment", onSubmit SaveComment ]
            [ input
                [ type_ "text"
                , placeholder "Add a comment..."
                , value model.newComment
                , onInput UpdateComment
                ]
                []
            , button
                [ disabled (String.isEmpty model.newComment) ]
                [ text "Save" ]
            ]
        ]


viewDetailedPhoto : Model -> Html Msg
viewDetailedPhoto model =
    div [ class "detailed-photo" ]
        [ img [ src model.url ] []
        , div [ class "photo-info" ]
            [ viewLoveButton model
            , h2 [ class "caption" ] [ text model.caption ]
            , viewComments model
            ]
        ]


view : Model -> Html Msg
view model =
    div []
        [ div [ class "header" ]
            [ h1 [] [ text "Picshare" ] ]
        , div [ class "content-flow" ]
            [ viewDetailedPhoto model ]
        ]


-- START:msg
type Msg
    = ToggleLike
    | UpdateComment String
    | SaveComment
    | LoadFeed (Result Http.Error Photo)
-- END:msg


saveNewComment : Model -> Model
saveNewComment model =
    let
        comment =
            String.trim model.newComment
    in
    case comment of
        "" ->
            model

        _ ->
            { model
                | comments = model.comments ++ [ comment ]
                , newComment = ""
            }


-- START:update
-- Browser.element の初期値に合わせて (状態, コマンド) のタプルを返す
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ToggleLike ->
            ( { model | liked = not model.liked } -- 更新された状態
            , Cmd.none -- その後実行するコマンド
            )

        UpdateComment comment ->
            ( { model | newComment = comment }
            , Cmd.none
            )

        SaveComment ->
            ( saveNewComment model
            , Cmd.none
            )

        LoadFeed _ ->
            ( model, Cmd.none )
-- END:update


-- START:subscriptions
subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
-- END:subscriptions


main : Program () Model Msg
-- START:main
main =
    -- TEAアプリにコマンドを追加する場合は Browser.element を使う
    -- Browser.element はアプリケーションをページに埋め込む際に JavaScript のコードから初期データを渡せる
    Browser.element
        { init = init -- モデルとコマンドの2つの初期状態が必要
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
-- END:main
