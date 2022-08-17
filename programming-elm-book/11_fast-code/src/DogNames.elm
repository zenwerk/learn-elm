module DogNames exposing (..)

import Benchmark exposing (..)
import Benchmark.Runner exposing (BenchmarkProgram, program)

type Kind
    = Dog
    | Cat


type alias Animal =
    { name : String
    , kind : Kind
    }


dogNames : List Animal -> List String
dogNames animals =
    animals
        |> List.filter (\{ kind } -> kind == Dog)
        |> List.map .name


dogNamesFilterMap : List Animal -> List String
dogNamesFilterMap animals =
    animals
        |> List.filterMap
            (\{name, kind} ->
                if kind == Dog then
                    Just name
                else
                    Nothing
            )

dogNamesFold1 : List Animal -> List String
dogNamesFold1 animals =
    animals
        |> List.foldl
            (\{name, kind} accume ->
                if kind == Dog then
                    -- accume ++ [name] 結合毎に末尾のnil走査をするため遅くなる
                    name :: accume -- まずは head に追加して
                else
                    accume
            )
            [] -- 空リストが accume の初期値
        |> List.reverse -- 最後に反転させる


benchmarkAnimals : List Animal
benchmarkAnimals =
    [ Animal "Rucker" Dog
    , Animal "Sally" Dog
    , Animal "sunsun" Cat
    , Animal "foobar" Dog
    , Animal "misora" Cat
    ]
        |> List.repeat 10
        |> List.concat

{-
suite : Benchmark
suite =
    describe "dog names"
    [ benchmark "filter and map" <|
        \_ -> dogNames benchmarkAnimals
    , benchmark "filterMap" <|
        \_ -> dogNamesFilterMap benchmarkAnimals
    ]
-}

suite : Benchmark
suite =
    describe "dog names"
    [ Benchmark.compare "implementations"
        "filter and map"
        (\_ -> dogNames benchmarkAnimals)
        "foldl"
        (\_ -> dogNamesFold1 benchmarkAnimals)
    ]


{-
    ベンチマークを実行するためだけのTEAプログラムがライブラリで用意される
-}
main : BenchmarkProgram
main =
    program suite
