module GetDog exposing (Dog, Trick(..), createDog, getDog, suite)

import Benchmark exposing (..)
import Benchmark.Runner exposing (BenchmarkProgram, program)
import Dict exposing (Dict)
import Set


type Trick
    = Sit
    | RollOver
    | Speak
    | Fetch
    | Spin


type alias Dog =
    { name : String
    , tricks : List Trick
    }


trickToString : Trick -> String
trickToString trick =
    case trick of
        Sit ->
            "Sit"

        RollOver ->
            "RollOver"

        Speak ->
            "Speak"

        Fetch ->
            "Fetch"

        Spin ->
            "Spin"


uniqueBy : (a -> comparable) -> List a -> List a
uniqueBy toComparable list =
    List.foldr
        (\item ( existing, accum ) ->
            let
                comparableItem =
                    toComparable item
            in
            if Set.member comparableItem existing then
                ( existing, accum )

            else
                ( Set.insert comparableItem existing, item :: accum )
        )
        ( Set.empty, [] )
        list
        |> Tuple.second


createDog : String -> List Trick -> Dog
createDog name tricks =
    Dog name (uniqueBy trickToString tricks)


getDog : Dict String Dog -> String -> List Trick -> ( Dog, Dict String Dog )
getDog dogs name tricks =
    let
        dog =
            Dict.get name dogs
                -- この withDefault だと必ず createDog によるデフォルト値生成処理が実行されてしまう（無駄なコスト）
                |> Maybe.withDefault (createDog name tricks)

        newDogs =
            -- ここの Dict.insert は実際に createDog で新しいデータが作成されたときにだけ呼ぶべき
            Dict.insert name dog dogs
    in
    ( dog, newDogs )


{-
    UNIT値を受け取って値を返す関数を、関数型プログラミングの文脈ではThunk(サンク)と呼ぶ
    この関数では「() を受け取ってデフォルト値を返す関数」として使う
-}
withDefaultLazy : (() -> a) -> Maybe a -> a
withDefaultLazy thunk maybe =
    case maybe of
        Just value ->
            value
        Nothing ->
            thunk () -- サンクを実行してデフォルト値を返す（遅延実行）


getDogLazy : Dict String Dog -> String -> List Trick -> ( Dog, Dict String Dog )
getDogLazy dogs name tricks =
    let
        dog =
            Dict.get name dogs
                |> withDefaultLazy (\() -> createDog name tricks)

        newDogs =
            Dict.insert name dog dogs
    in
    ( dog, newDogs )


getDogLazyInsertion : Dict String Dog -> String -> List Trick -> (Dog, Dict String Dog)
getDogLazyInsertion dogs name trikcs =
    Dict.get name dogs -- 犬が存在するか Dict.get で確認
        |> Maybe.map (\dog -> (dog, dogs)) -- Just なら (データ, Dict) のタプルの組にして |> に流す
        |> withDefaultLazy -- Maybe を受け取って遅延実行
            (\() ->
                let
                    dog = createDog name trikcs
                in
                (dog, Dict.insert name dog dogs) -- ここで初めて Dict.insert が走る
            )

{-
    getDogLazyInsertion と同じ遅延評価の処理はパターンマッチを使えば簡単かつ綺麗に書ける
    パターンマッチはマッチした行しか実行されないので、自動的に遅延実行となる
-}
getDogCaseExpression : Dict String Dog -> String -> List Trick -> (Dog, Dict String Dog)
getDogCaseExpression dogs name tricks =
    case Dict.get name dogs of
        Just dog ->
            (dog, dogs)
        Nothing ->
            let
                dog = createDog name tricks
                newDogs = Dict.insert name dog dogs
            in
            (dog, newDogs)


benchmarkTricks : List Trick
benchmarkTricks =
    [ Sit, RollOver, Speak, Fetch, Spin ]


benchmarkDogs : Dict String Dog
benchmarkDogs =
    Dict.fromList
        [ ( "Tucker", createDog "Tucker" benchmarkTricks ) ]


dogExists : Benchmark
dogExists =
    describe "dog exists"
    [ Benchmark.compare "実装比較"
        "lazy creation and insertion"
        (\_ -> getDogLazyInsertion benchmarkDogs "Tucker" benchmarkTricks)
        "case expression"
        (\_ -> getDogCaseExpression benchmarkDogs "Tucker" benchmarkTricks)
    ]


suite : Benchmark
suite =
    describe "getDog"
        [ dogExists ]


main : BenchmarkProgram
main =
    program suite
