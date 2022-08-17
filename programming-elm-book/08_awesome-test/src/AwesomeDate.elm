-- START:module
module AwesomeDate exposing (Date, create, year)
-- END:module


-- START:type.Date
{-
    レコード型の type alias ではなく Opaque type としてカスタム型を公開する
    レコード型の場合はフィールドにアクセス可能だが Opaque type は実装を隠蔽できる
    C言語の Opaque struct と同じ
-}
type Date
    = Date { year : Int, month : Int, day : Int }
-- END:type.Date


-- START:create
create : Int -> Int -> Int -> Date
create year_ month_ day_ =
    Date { year = year_, month = month_, day = day_ }
-- END:create


-- START:year
year : Date -> Int
{-
    (Date date) は引数分割束縛
    Date型のDateコンストラクタにパターンマッチして引数を受け取っている
-}
year (Date date) =
    date.year
-- END:year
