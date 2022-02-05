module PublicFeed exposing (Model, Msg, init, subscriptions, update, view)

import Feed
import Html exposing (Html)

-- Feed のモデルを PublicFeed モジュールで使えるように再度エイリアス化する
type alias Model =
    Feed.Model

type alias Msg =
    Feed.Msg


feedUrl : String
feedUrl =
    "https://programming-elm.com/feed"

wsUrl : String
wsUrl =
    "wss://programming-elm/"


init : ( Model, Cmd Msg )
init =
    Feed.init
    { feedUrl = feedUrl
    , wsUrl = Just wsUrl
    }


view : Model -> Html Msg
view =
    Feed.view


update : Msg -> Model -> ( Model, Cmd Msg )
update =
    Feed.update


subscriptions : Model -> Sub Msg
subscriptions =
    Feed.subscriptions
    