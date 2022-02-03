module Main exposing (main)

import Account
import Feed as PublicFeed
import WebSocket

import Browser
import Browser exposing (Document, UrlRequest)
import Browser.Navigation as Navigation
import Html exposing (Html, a, div, h1, i, text)
import Html.Attributes exposing (class)
import Routes
import Url exposing (Url)



---- MODEL ----

{-
    `Model` に保存するためのSPAのルート情報
    これは「現在表示されているページ」を表すもの
    Routes は URL と表示するページの対応可能を表すものなので別
-}
type Page
    = PublicFeed PublicFeed.Model -- 写真フィード表示ページ
    | Account Account.Model
    | NotFound

-- Navigation.Key はブラウザ側でURLの変更がなされた際に使うキー
type alias Model =
    { page : Page
    , navigationKey : Navigation.Key
    }


{-
    Navigation.Key が実行中のElmプログラムから渡されてくる
    Browser がURL変更イベントを発行する
-}
initialModel : Navigation.Key -> Model
initialModel navigationKey =
    { page = NotFound
    , navigationKey = navigationKey
    }


{-
    Browser.application は起動時に最初のUrlを渡してくる
    よって initi は Flag の後に Url, Browser.Navigation.Key を引数にとり Model と Cmd を返す関数に変更しなければならない
-}
init : () -> Url -> Navigation.Key -> ( Model, Cmd Msg )
init () url navigationKey =
    setNewPage (Routes.match url) (initialModel navigationKey)



---- VIEW ----

{-
    共通ヘッダ
-}
viewHeader : Html Msg
viewHeader =
    div [ class "header" ]
        [ div [ class "header-nav" ]
            [ a [ class "nav-brand", Routes.href Routes.Home ]
                [ text "Picshare" ]
            , a [ class "nav-account", Routes.href Routes.Account ]
                [ i [ class "fa fa-2x fa-gear" ] [] ]
            ]
        ]


{-
    Document 型は body だけれはなく title も設定できる
    最初の String は <title> を設定するための値
-}
viewContent : Page -> (String, Html Msg)
viewContent page =
    case page of
        PublicFeed publicFeedModel ->
            ( "Picshare"
            , PublicFeed.view publicFeedModel
                |> Html.map PublicFeedMsg
            )
        Account accountModel ->
            ( "Account"
            , Account.view accountModel
                |> Html.map AccountMsg -- Account.Msg を Main.Msg に変換する必要がある
            )
        NotFound ->
            ( "Not Found"
            , div [ class "not-found" ]
                [ h1 [] [ text "Page Not Found"] ]
            )

view : Model -> Document Msg
view model =
    let
        ( title, content) = viewContent model.page
    in
    { title = title
    , body = [ viewHeader, content ]
    }



---- UPDATE ----


type Msg
    -- メッセージでURLの変化を扱う
    = NewRoute (Maybe Routes.Route)
    | Visit UrlRequest
    {-
        AccountコンポーネントのMsgを使うためにラップするコンストラクタを追加する
    -}
    | AccountMsg Account.Msg
    -- FeedもAccountコンポーネントと同様
    | PublicFeedMsg PublicFeed.Msg


{-
    pageフィールドを新しいルート情報に基づいて更新する関数
-}
setNewPage : Maybe Routes.Route -> Model -> ( Model, Cmd Msg)
setNewPage maybeRoute model =
    case maybeRoute of
        Just Routes.Home ->
            let
                ( publicFeedModel, publicFeedCmd ) = PublicFeed.init ()
            in
            ( { model | page = PublicFeed publicFeedModel }
            , Cmd.map PublicFeedMsg publicFeedCmd
            )
        Just Routes.Account ->
            let
                ( accountModel, accountCmd ) = Account.init
            in
            ( { model | page = Account accountModel }
            -- Account.Msg をラップして Main.Msg を返す
            , Cmd.map AccountMsg accountCmd
            )
        Nothing ->
            ( { model | page = NotFound }, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case (msg, model.page) of -- Msg と現在のページの状態でマッチさせる
        (NewRoute maybeRoute, _) -> -- ページ遷移に現在のページは関係ないので _ で無視
            let
                ( updatedModel, cmd ) = setNewPage maybeRoute model
            in
            ( updatedModel
            -- Cmd.batch で一度の複数のコマンドをTEAアプリに発行できる
            -- WebSocket.close で画面遷移字にwsをちゃんと閉じる
            , Cmd.batch [ cmd, WebSocket.close () ]
            )

        -- AccountMsgかつ現在のページがAccountのときのみマッチする、これによってパターンマッチの簡略化 + 無駄なAccountMsgの処理を防ぐ
        (AccountMsg accountMsg, Account accountModel) ->
            let
                ( updatedAccountModel, accountCmd ) =
                    Account.update accountMsg accountModel -- コンポーネントの update を呼び出し結果を保存
            in
            ( { model | page = Account updatedAccountModel }
            , Cmd.map AccountMsg accountCmd
            )

        ( PublicFeedMsg publicFeedMsg, PublicFeed publicFeedModel ) ->
            let
                ( updatedPublicFeedModel, publicFeedCmd ) = PublicFeed.update publicFeedMsg publicFeedModel
            in
            ( { model | page = PublicFeed updatedPublicFeedModel }
            , Cmd.map PublicFeedMsg publicFeedCmd
            )

        ( Visit (Browser.Internal url), _) -> -- Internal で内部URLのみにマッチさせる
            -- Navigation.pushUrl関数で Cmd を生成する
            {-
                onUrlRequest で Visit が発火した結果の Internal url を pushUrl関数経由で history.pushState を操作する
                pushStateがブラウザのURLを変更すると、onUrlChangeが発火し現在のルート情報を NewRoute で包んで update関数へ渡す
                updateが画面内容を更新する
            -}
            ( model, Navigation.pushUrl model.navigationKey (Url.toString url) )
        _ ->
            ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.page of
        PublicFeed publicFeedModel ->
            PublicFeed.subscriptions publicFeedModel
                |> Sub.map PublicFeedMsg
        _ ->
            Sub.none



---- PROGRAM ----


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        -- Browser.application に必要な新しいフィールド2つ
        {-
            onUrlRequest には UrlRequest をラップするMsgのコンストラクタを渡す
        -}
        , onUrlRequest = Visit
        {-
            ブラウザがURLを変更されると onUrlChange に指定された値を使って「現在のURL」をラップする
            >> は 左->右へ関数を合成する演算子
            |> と違うのは (Foo >> Bar) の組み合わせで「一つの関数」になること
            引数で渡された Url を Routes.match で (Maybe Route) にして NewRoute コンストラクタに渡す
        -}
        , onUrlChange = Routes.match >> NewRoute
        }