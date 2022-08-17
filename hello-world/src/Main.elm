module Main exposing (main)
import Html exposing (text)

-- elm make src/Main.elm

greeting : String
greeting = "Hello, Elm"


-- elm make src/Main.elm"
main =
    text ((Debug.toString 42) ++ " Hello, Elm.")