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


benchmarkAnimals : List Animal
benchmarkAnimals =
    [ Animal "Rucker" Dog
    , Animal "Sally" Dog
    , Animal "sunsun" Cat
    , Animal "foobar" Dog
    , Animal "misora" Cat
    ]

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
        "filterMap"
        (\_ -> dogNamesFilterMap benchmarkAnimals)
    ]


{-
    ベンチマークを実行するためだけのTEAプログラムがライブラリで用意される
-}
main : BenchmarkProgram
main =
    program suite
