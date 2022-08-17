module SaladBuilder exposing (main)

import Browser
import Html
    exposing
        ( Html
        , button
        , div
        , h1
        , h2
        , input
        , label
        , li
        , p
        , section
        , table
        , td
        , text
        , th
        , tr
        , ul
        )
import Html.Attributes exposing (checked, class, disabled, name, type_, value)
import Html.Events exposing (onCheck, onClick, onInput)
import Http
import Json.Encode exposing (Value, list, object, string)
import Regex
import Set exposing (Set)



---- MODEL ----
type alias Error =
    String

-- サラダの基礎となるもの
type Base
    = Lettuce -- レタス
    | Spinach -- ほうれん草
    | SpringMix -- 新芽の盛り合わせ


baseToString : Base -> String
baseToString base =
    case base of
        Lettuce ->
            "Lettuce"

        Spinach ->
            "Spinach"

        SpringMix ->
            "Spring Mix"


-- トッピング
type Topping
    = Tomatoes
    | Cucumbers
    | Onions


-- Set に保存するため comparable な String に変換するための関数
toppingToString : Topping -> String
toppingToString topping =
    case topping of
        Tomatoes ->
            "Tomatoes"

        Cucumbers ->
            "Cucumbers"

        Onions ->
            "Onions"


-- ドレッシング
type Dressing
    = NoDressing
    | Italian
    | RaspberryVinaigrette
    | OilVinegar


dressingToString : Dressing -> String
dressingToString dressing =
    case dressing of
        NoDressing ->
            "No Dressing"

        Italian ->
            "Italian"

        RaspberryVinaigrette ->
            "Raspberry Vinaigrette"

        OilVinegar ->
            "Oil and Vinegar"


type alias Salad =
    { base : Base
    , toppings : Set String
    , dressing : Dressing
    }


-- 拡張可能レコード
{-
    他言語でいう「インターフェイス」に相当するもの.
    先頭の `{ c |` という構文は定義しているフィールドを含むすべての型を総称して `c` という名前を付けている.
    また `c` は小文字なので型変数.
    この型変数は型エイリアスの定義の左辺にも含めて `type alias Contact c` のように宣言する必要がある.

    インターフェイスなので、I/Fを満たす具体的な型fooを受け取るひつようがあるため、使用時には Contact c のように型変数が必須
-}
type alias Contact c =
    { c
        | name : String
        , email : String
        , phone : String
    }


type alias Model =
    { step : Step
    , error : Maybe String
    , salad : Salad
    , name : String
    , email : String
    , phone : String
    }


initialModel : Model
initialModel =
    { step = Building Nothing
    , error = Nothing
    , salad =
        { base = Lettuce
        , toppings = Set.empty
        , dressing = NoDressing
        }
    , name = ""
    , email = ""
    , phone = ""
    }


init : () -> ( Model, Cmd Msg )
init () =
    ( initialModel, Cmd.none )



---- VALIDATION ----


isRequired : String -> Bool
isRequired value =
    String.trim value /= ""


isValidEmail : String -> Bool
isValidEmail value =
    let
        options =
            { caseInsensitive = True
            , multiline = False
            }

        regexString =
            "^(([^<>()\\[\\]\\.,;:\\s@\"]+(\\.[^<>()\\[\\]\\.,;:\\s@\"]+)*)|(\".+\"))@((\\[[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}])|(([a-zA-Z\\-0-9]+\\.)+[a-zA-Z]{2,}))$"

        regex =
            Regex.fromStringWith options regexString
                |> Maybe.withDefault Regex.never
    in
    value
        |> String.trim
        |> Regex.contains regex


isValidPhone : String -> Bool
isValidPhone value =
    let
        regex =
            Regex.fromString "^\\d{10}$"
                |> Maybe.withDefault Regex.never
    in
    value
        |> String.trim
        |> Regex.contains regex


isValid : Model -> Bool
isValid model =
    [ isRequired model.name
    , isRequired model.email
    , isValidEmail model.email
    , isRequired model.phone
    , isValidPhone model.phone
    ]
        |> List.all identity



---- VIEW ----

-- 送信中画面
viewSending : Html msg
viewSending =
    div [ class "sending" ] [ text "Sending Order ..." ]


-- エラー画面
viewError : Maybe Error -> Html msg
viewError error =
    case error of
        Just errorMessage ->
            div [ class "error" ] [ text errorMessage ]
        Nothing ->
            text ""


viewSection : String -> List (Html msg) -> Html msg
viewSection heading children =
    section [ class "salad-section" ]
        (h2 [] [ text heading ] :: children)


-- トッピング選択肢
viewToppingOption : String -> Topping -> Set String -> Html Msg
viewToppingOption toppingLabel topping toppings =
    label [ class "section-option" ]
        [ input
            [ type_ "checkbox"
            , checked (Set.member (toppingToString topping) toppings)
            {- ToggleTopping は Topping, bool を引数に取るコンストラクタ関数
                bool 型は onCheck 時にElmが渡してくれる

             << で関数合成しているのは、以下のような処理を完結に記述するため
             toggleToppingMsg : Topping -> Bool -> Msg
             toggleToppingMsg topping add =
                SaladMsg (ToggleTopping topping add)
            -}
            , onCheck (SaladMsg << ToggleTopping topping)
            ]
            []
        , text toppingLabel
        ]


-- トッピング選択まとめ
viewSelectToppings : Set String -> Html Msg
viewSelectToppings toppings =
    div []
        [ viewToppingOption "Tomatos" Tomatoes toppings
        , viewToppingOption "Cucumbers" Cucumbers toppings
        , viewToppingOption "Onions" Onions toppings
        ]


-- ラジオボタン選択肢
viewRadioOption : String -> value -> (value -> msg) -> String -> value -> Html msg
viewRadioOption radioName selectedValue tagger optionLabel value =
    label [ class "section-option" ]
        [ input
            [ type_ "radio"
            , name radioName
            , checked (value == selectedValue)
            , onClick (tagger value)
            ]
            []
        , text optionLabel
        ]



-- 現在選択されている値をcurrentBase引数として受け取る
viewSelectBase : Base -> Html Msg
viewSelectBase currentBase =
    let
        viewBaseOption =
            {-
                "base" がラジオボタン名
                currentBase が selectedValue
                (SaladMsg << SetBase) が tagger
            -}
            viewRadioOption "base" currentBase (SaladMsg << SetBase)
    in
    div []
        [ viewBaseOption "Lettase" Lettuce
        , viewBaseOption "Spinach" Spinach
        , viewBaseOption "Spring Mix" SpringMix
        ]


viewSelectDressing : Dressing -> Html Msg
viewSelectDressing currentDressing =
    let
        viewDressingOption =
            viewRadioOption "dressing" currentDressing (SaladMsg << SetDressing)
    in
    div []
        [ viewDressingOption "None" NoDressing
        , viewDressingOption "Italian" Italian
        , viewDressingOption "Raspberry Vinaigrette" RaspberryVinaigrette
        , viewDressingOption "Oil and Vinegar" OilVinegar
        ]


-- テキスト入力汎用化関数
viewTextInput : String -> String -> (String -> msg) -> Html msg
viewTextInput inputLabel inputValue tagger =
    div [ class "text-input" ]
        [ label []
            [ div [] [ text (inputLabel ++ ":") ]
            , input
                [ type_ "text"
                , value inputValue
                , onInput tagger
                ]
                []
            ]
        ]


viewContact : Contact a -> Html ContactMsg
viewContact contact =
    div []
        [ viewTextInput "Name" contact.name SetName
        , viewTextInput "Email" contact.email SetEmail
        , viewTextInput "Phone" contact.phone SetPhone
        ]

-- サラダ構成画面
-- viewBuild は入力イベントが Msg 型の値を生成するので、型注釈は Html msg ではなく Html Msg
-- 他の viewFoo と違い `Html Msg` とあるので、このviewだけがメッセージを返すということが、型定義から読み取れる
-- 逆に `Html msg` の場合はメッセージを生成しないということが分かる
viewBuild : Maybe Error -> Model -> Html Msg
viewBuild error model =
    div []
        [ viewError error
        , viewSection "1. Select Base"
            [ viewSelectBase model.salad.base ]
        , viewSection "2. Select Toppings"
            [ viewSelectToppings model.salad.toppings ]
        , viewSection "3. Select Dressing"
            [ viewSelectDressing model.salad.dressing ]
        , viewSection "4. Enter Contact Info"
            [
            {-
                viewContact は ContactMsg(値) を返すが viewBuild は Html Msg を期待するのでコンパイルできない
                よって Html.map で ContactMsg(コンストラクタ) でラップして Html Msg に変換してコンパイルできるようにする

                Html型をリスト型のデータ構造と捉えると、以下のようなイメージ
                List.map ContactMsg [ SetName "Jeremy", SetEmail "j@example.com" ]
                    returns [ ContactMsg (SetName "Jeremy")
                            , ContactMsg (SetEmail "j@example.com")
                            ]
            -}
              Html.map ContactMsg (viewContact model)
            , button
                [ class "send-button"
                , disabled (not (isValid model))
                , onClick Send
                ]
                [ text "Send Order" ]
            ]
        ]


-- 確定画面
viewConfirmation : Model -> Html msg
viewConfirmation model =
    div [ class "confirmation" ]
        [ h2 [] [ text "Woo hoo!" ]
        , p [] [ text "Thanks for your order!" ]
        , table []
            [ tr []
                [ th [] [ text "Base:" ]
                , td [] [ text (baseToString model.salad.base) ]
                ]
            , tr []
                [ th [] [ text "Toppings:" ]
                , td []
                    [ ul []
                        (model.salad.toppings
                            |> Set.toList
                            |> List.map (\topping -> li [] [ text topping ])
                        )
                    ]
                ]
            , tr []
                [ th [] [ text "Dressing:" ]
                , td [] [ text (dressingToString model.salad.dressing) ]
                ]
            , tr []
                [ th [] [ text "Name:" ]
                , td [] [ text model.name ]
                ]
            , tr []
                [ th [] [ text "Email:" ]
                , td [] [ text model.email ]
                ]
            , tr []
                [ th [] [ text "Phone:" ]
                , td [] [ text model.phone ]
                ]
            ]
        ]


-- 各状態における画面表示の分岐
viewStep : Model -> Html Msg
viewStep model =
    case model.step of
        Building error ->
            viewBuild error model
        Sending ->
            viewSending
        Confirmation ->
            viewConfirmation model


view : Model -> Html Msg
view model =
    div []
        -- ヘッダ部
        [ h1 [ class "header" ]
            [ text "Saladise - Build a Salad" ]
        , div [ class "content" ]
            [ viewStep model ]
        ]



---- UPDATE ----

type SaladMsg
    = SetBase Base
    | ToggleTopping Topping Bool
    | SetDressing Dressing


type ContactMsg
    = SetName String
    | SetEmail String
    | SetPhone String


-- 現在の画面繊維状態
type Step
    = Building (Maybe Error)
    | Sending
    | Confirmation


type Msg
    = SaladMsg SaladMsg -- コンストラクタ名`SaladMsg` 引数の型`SaladMsg`
    | ContactMsg ContactMsg -- 拡張可能レコードを使う
    | Send
    | SubmissionResult (Result Http.Error String)


sendUrl : String
sendUrl =
    "https://programming-elm.com/salad/send"


encodeOrder : Model -> Value
encodeOrder model =
    object
        [ ( "base", string (baseToString model.salad.base) )
        , ( "toppings", list string (Set.toList model.salad.toppings) )
        , ( "dressing", string (dressingToString model.salad.dressing) )
        , ( "name", string model.name )
        , ( "email", string model.email )
        , ( "phone", string model.phone )
        ]


send : Model -> Cmd Msg
send model =
    Http.post
        { url = sendUrl
        , body = Http.jsonBody (encodeOrder model)
        , expect = Http.expectString SubmissionResult
        }


updateSalad : SaladMsg -> Salad -> Salad
updateSalad msg salad =
    case msg of
        SetBase base ->
            { salad | base = base }
        SetDressing dressing ->
            { salad | dressing = dressing }
        ToggleTopping topping add ->
            let
                updater =
                    if add then
                        Set.insert
                    else
                        Set.remove
            in
            { salad | toppings = updater (toppingToString topping) salad.toppings }


updateContact : ContactMsg -> Contact c -> Contact c
updateContact msg contact =
    case msg of
        SetName name ->
            { contact | name = name }
        SetEmail email ->
            { contact | email = email }
        SetPhone phone ->
            { contact | phone = phone }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SaladMsg saladMsg ->
            ( { model | salad = updateSalad saladMsg model.salad }
            , Cmd.none )

        ContactMsg contactMsg ->
            ( updateContact contactMsg model
            , Cmd.none
            )

        Send ->
            let
                newModel =
                    { model | step = Sending }
            in
            ( newModel
            , send newModel
            )

        SubmissionResult (Ok _) ->
            ( { model | step = Confirmation }
            , Cmd.none
            )

        SubmissionResult (Err _) ->
            let
                errorMessage = "There was a problem sending your order. Please try again."
            in
            ( { model | step = Building (Just errorMessage) }
            , Cmd.none
            )



---- PROGRAM ----


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = always Sub.none
        }
