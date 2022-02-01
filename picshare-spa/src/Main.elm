module Main exposing (main)

import Account

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
    = PublicFeed -- 写真フィード表示ページ
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
    Document 型は body だけれはなく title も設定できる
    最初の String は <title> を設定するための値
-}
viewContent : Page -> (String, Html Msg)
viewContent page =
    case page of
        PublicFeed ->
            ( "Picshare"
            , h1 [] [ text "Public Feed" ]
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
    , body = [ content ]
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


{-
    pageフィールドを新しいルート情報に基づいて更新する関数
-}
setNewPage : Maybe Routes.Route -> Model -> ( Model, Cmd Msg)
setNewPage maybeRoute model =
    case maybeRoute of
        Just Routes.Home ->
            ( { model | page = PublicFeed }, Cmd.none )
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
            setNewPage maybeRoute model
        -- AccountMsgかつ現在のページがAccountのときのみマッチする、これによってパターンマッチの簡略化 + 無駄なAccountMsgの処理を防ぐ
        (AccountMsg accountMsg, Account accountModel) ->
            let
                ( updatedAccountModel, accountCmd ) =
                    Account.update accountMsg accountModel -- コンポーネントの update を呼び出し結果を保存
            in
            ( { model | page = Account updatedAccountModel }
            , Cmd.map AccountMsg accountCmd
            )
        _ ->
            ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
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