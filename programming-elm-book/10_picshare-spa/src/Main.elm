module Main exposing (main)

import Account
import PublicFeed
import UserFeed
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

    コンストラクタの引数には, そのページに表示させたい状態をもたせる
-}
type Page
    = PublicFeed PublicFeed.Model -- 写真フィード表示ページ
    | UserFeed String UserFeed.Model -- ユーザーページ
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
    よって init は Flag の後に Url, Browser.Navigation.Key を引数にとり,
    その引数を利用し (Model, Cmd) を返す関数である必要がある
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
    Document 型は <body> だけではなく <title> も設定できる
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
        UserFeed username userFeedModel ->
            ( "User Feed for @" ++ username
            , UserFeed.view userFeedModel
                |> Html.map UserFeedMsg
            )
        Account accountModel ->
            ( "Account"
            , Account.view accountModel -- Account.Msg が返り値
                |> Html.map AccountMsg -- Account.Msg を |> でコンストラクタに渡して Main.Msg に変換する必要がある
            )
        NotFound ->
            ( "Not Found"
            , div [ class "not-found" ]
                [ h1 [] [ text "Page Not Found"] ]
            )

-- Html msg ではなく Document Msg を返す
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
    | UserFeedMsg UserFeed.Msg


{-
    pageフィールドを新しいルート情報に基づいて更新する関数
-}
setNewPage : Maybe Routes.Route -> Model -> ( Model, Cmd Msg)
setNewPage maybeRoute model =
    case maybeRoute of
        Just Routes.Home ->
            let
                ( publicFeedModel, publicFeedCmd ) = PublicFeed.init
            in
            ( { model | page = PublicFeed publicFeedModel }
            , Cmd.map PublicFeedMsg publicFeedCmd
            )
        Just (Routes.UserFeed username) ->
            let
                ( userFeedModel, userFeedCmd ) = UserFeed.init username
            in
            ( { model | page = UserFeed username userFeedModel }
            , Cmd.map UserFeedMsg userFeedCmd
            )
        Just Routes.Account ->
            let
                -- ページ遷移するときにコンポーネントの init を呼び出して (Model, 初期Cmd) を取得する
                ( accountModel, accountCmd ) = Account.init
            in
            ( { model | page = Account accountModel }
            -- accountCmd を直接返すと Account.Cmd と Main.Cmd が合わず型エラーになる
            -- そこで Cmd.map 関数を慶友して Account.Msg をラップして Main.Msg を返す
            -- map は map-reduce の map だよ
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

        (UserFeedMsg userFeedMsg, UserFeed username userFeedModel ) ->
            let
                ( updatedUserFeedModel, userFeedCmd) = UserFeed.update userFeedMsg userFeedModel
            in
            ( { model | page = UserFeed username updatedUserFeedModel }
            , Cmd.map UserFeedMsg userFeedCmd
            )

        {-
            aタグなどでリンクが踏まれると onUrlRequest で指定された Visit Msg が発行される
            発火した結果の Visit Internal.url update でパターンマッチして, その結果を pushUrl関数経由で Cmd を発行する
            発行された Cmd で TEA が history.pushState を実行しURLが変更される
            URLを変更されると、続いて onUrlChangeが発火し現在のルート情報を NewRoute で包んで update関数へ渡し, updateのパターンマッチで画面内容を更新し再描画(画面遷移)が完了する
        -}
        ( Visit (Browser.Internal url), _) -> -- Internal で内部URLのみにマッチさせる
            -- Navigation.pushUrl関数で Cmd を生成する
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
    -- Browser.application は Browser.element の機能に加えて
    -- リンクがクリックされたとき、TEAからBrowserモジュール経由で現在のURLを通知するイベントを発行してくれる
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        -- Browser.application に必要な新しいフィールド2つ
        {-
            onUrlRequest には リンクがクリックされたときにTEAから発行される
            UrlRequest をラップするMsgのコンストラクタを渡す
        -}
        , onUrlRequest = Visit
        {-
            ブラウザがURLを変更されると onUrlChange に指定された値を使って「変更後のURL」をラップする.
            引数で渡された Url を Routes.match で (Maybe Route) にして NewRoute コンストラクタに渡す
        -}
        -- >> は 左->右へ関数を合成する演算子, |> と違うのは (Foo >> Bar) の組み合わせで「一つの関数」になること.
        , onUrlChange = Routes.match >> NewRoute
        }
