module Routes exposing (Route(..), href, match)

-- URLをいい感じに扱うモジュールをインポート
import Url exposing (Url)
-- </> は特別に定義された中置演算子
import Url.Parser as Parser exposing (Parser, (</>))

-- 画面遷移のため必要な pushState 操作関連のためインポート
import Html
import Html.Attributes


-- SPAのルート情報を定義するヴァリアント
type Route
    = Home
    | Account
    | UserFeed String


routeToUrl : Route -> String
routeToUrl route =
    case route of
        Home ->
            "/"
        Account ->
            "/account"
        UserFeed username ->
            "/user/" ++ username ++ "/feed" -- Url.Builder を使うとよりセキュアになる


href : Route -> Html.Attribute msg
href route =
    Html.Attributes.href (routeToUrl route)


{-
    URLパーサーをを定義する
    (Routes -> a) のような型定義は、カスタムタイプ Route型に対してパーサーを定義する、ということを表している
-}
routes : Parser (Route -> a) a
routes =
    Parser.oneOf -- URLを順番に試しマッチしたものを適用する関数
        [
        -- Parser.top `/` を Homeコンストラクタに Parser.map でマッピングする
        -- すると, 現在のパスが '/' にマッチしたら Parser.map は Homeコンストラクタを返すようになる
        Parser.map Home Parser.top
        -- Parser.s は指定した文字列を特定のURLセグメントとして捉える関数
        , Parser.map Account (Parser.s "account") -- "/account" を Accountコンストラクタにマッピングする
        -- 動的URLのパーサー
        , Parser.map
            UserFeed
            -- </> でパーサーを結合している, Parser.string は動的な文字列を受け取るURLパーサー
            -- この string が UserFeed String に渡される
            (Parser.s "user" </> Parser.string </> Parser.s "feed")
        ]

{-
    routes パーサーを使用して実際のURLを `Routes` へ変換する
-}
match : Url -> Maybe Route
match url =
    -- Parser.parse は渡されたパーサーを利用して url の path部をパースする
    -- 定義されたURLなら Just Route, デタラメなURLなら Nothing を返す
    Parser.parse routes url
