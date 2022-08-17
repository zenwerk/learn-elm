module AwesomeDateTest exposing (suite)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Test exposing (..)
import AwesomeDate as Date exposing (Date)


exampleDate : Date
exampleDate =
    Date.create 2012 6 2


{-
    elm-test はモジュールがexposeしている Test型の関数をすべて実行する
    よって関数名は関係ないが、suiteという名前にするのが慣習のようだ
-}
suite : Test
suite =
    -- describe "説明文" [Test, Test, ...] で実行するテストをまとめる
    describe "AwesomeDate"
    [ test "dateからyearを取得"
        -- (\() -> Expect.equal (Date.year exampleDate) 2012) もしくは
        (\() -> Date.year exampleDate
                |> Expect.equal 2012)
    , test "もっとかっこいい書き方" <|
        \_ -> Date.year exampleDate
           |> Expect.equal 2012
    ]
