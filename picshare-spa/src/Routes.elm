module Routes exposing (Route(..), href, match)

-- URLをいい感じに扱うモジュールをインポート
import Url exposing (Url)
import Url.Parser as Parser exposing (Parser)

-- 画面遷移のため必要な pushState 操作関連のためインポート
import Html
import Html.Attributes


-- SPAのルート情報を定義するヴァリアント
type Route
    = Home
    | Account


routeToUrl : Route -> String
routeToUrl route =
    case route of
        Home ->
            "/"
        Account ->
            "/account"


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
        [ Parser.map Home Parser.top -- Parser.top("/") を Homeコンストラクタにマッピングする
        -- Parser.s はURLの特定のセグメントを捉える関数
        , Parser.map Account (Parser.s "account") -- "/account" を Accountコンストラクタにマッピングする
        ]

{-
    routes パーサーを使用して実際のURLを `Routes` へ変換する
-}
match : Url -> Maybe Route
match url =
    -- Parser.parse は渡されたパーサーを利用して url の path部をパースする
    Parser.parse routes url