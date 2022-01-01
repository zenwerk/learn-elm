-- START:module
module Picshare exposing (main)
-- END:module

-- START:import
import Html exposing (Html, div, text)
-- END:import


-- START:main
-- Html型は仮想DOMを表す
main : Html msg
main =
    -- [id, class, src, hrefなどの属性] [小要素]
    -- htmlの文字が欲しい場合は text 関数が必要
    div [] [ text "Picshare" ]
-- END:main
