module AppTest exposing (suite)

import App
import AwesomeDate as Date exposing (Date)
import Expect
import Test exposing (..)


selectedDate : Date
selectedDate =
    Date.create 2012 6 2


futureDate : Date
futureDate =
    Date.create 2015 9 21


initialModel : App.Model
initialModel =
    { selectedDate = selectedDate
    , years = Nothing
    , months = Nothing
    , days = Nothing
    }


modelWithDateOffsets : App.Model
modelWithDateOffsets =
    { initialModel
        | years = Just 3
        , months = Just 2
        , days = Just 50
    }


-- テスト用の SelectDate メッセージを返す関数
selectDate : Date -> App.Msg
selectDate date =
    App.SelectDate (Just date)


-- テスト用の ChangeDateOffset メッセージを返す関数
changeDateOffset : App.DateOffsetField -> Int -> App.Msg
changeDateOffset field amount =
    App.ChangeDateOffset field (Just amount)


testUpdate : Test
testUpdate =
    describe "update"
        [ test "select a date" <|
            -- 日付を選択する
            \_ ->
                App.update (selectDate futureDate) initialModel -- update関数に (selectDate) と Model を渡す
                    |> Tuple.first -- (更新されたModel, Cmd) が返るのでタプルの最初を取る
                    |> Expect.equal { initialModel | selectedDate = futureDate } -- 更新されたModelが想定されたものと同じか比較する
        , test "change years" <|
            -- 年を変更する
            \_ ->
                App.update (changeDateOffset App.Years 3) initialModel
                    |> Tuple.first
                    |> Expect.equal { initialModel | years = Just 3 }
        ]


testView : Test
testView =
    todo "implement view tests"


testEvents : Test
testEvents =
    todo "implement event tests"


suite : Test
suite =
    describe "App"
        [ testUpdate
        , testView
        , testEvents
        ]
