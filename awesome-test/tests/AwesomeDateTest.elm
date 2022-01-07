module AwesomeDateTest exposing (suite)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Test exposing (..)


{-
    elm-test はモジュールがexposeしている Test型の関数をすべて実行する
    よって関数名は関係ないが、suiteという名前にするのが慣習のようだ
-}
suite : Test
suite =
    -- describe "説明文" [Test, Test, ...] で実行するテストをまとめる
    describe "AwesomeDate" []
