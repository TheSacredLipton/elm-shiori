module Hello exposing (Model, main, view, buttons, alertBoxes)

import Browser
import Html exposing (..)
import Html.Attributes exposing (style)


main : Program () Model Msg
main =
    Browser.sandbox
        { init = init
        , view = view
        , update = update
        }


type alias Model =
    { property : Int
    , property2 : String
    }


init : Model
init =
    Model 0 "modelInitialValue2"


type Msg
    = Msg1
    | Msg2


update : Msg -> Model -> Model
update msg model =
    case msg of
        Msg1 ->
            model

        Msg2 ->
            model


{-|

    <shiori> view (Model 0 "modelInitialValue2")

-}
view : Model -> Html Msg
view _ =
    div
        [ style "padding" "40px"
        , style "background-color" "#fafaf9"
        , style "border-radius" "16px"
        , style "border" "1px solid #e7e5e4"
        , style "text-align" "center"
        ]
        [ h1
            [ style "font-size" "24px"
            , style "font-weight" "700"
            , style "color" "#1c1917"
            , style "margin-bottom" "12px"
            ]
            [ text "Hello, Elm-Shiori!" ]
        , p
            [ style "font-size" "14px"
            , style "color" "#78716c"
            , style "margin" "0"
            ]
            [ text "Select component variations from the sidebar navigation." ]
        ]


{-|

    <shiori> buttons

-}
buttons : Html msg
buttons =
    div
        [ style "display" "flex"
        , style "gap" "16px"
        , style "align-items" "center"
        , style "padding" "24px"
        , style "background-color" "#ffffff"
        , style "border-radius" "12px"
        , style "border" "1px solid #e7e5e4"
        ]
        [ button
            [ style "padding" "10px 20px"
            , style "background" "linear-gradient(135deg, #0ea5e9 0%, #0284c7 100%)"
            , style "color" "#ffffff"
            , style "border" "none"
            , style "border-radius" "8px"
            , style "font-weight" "600"
            , style "font-size" "14px"
            , style "cursor" "pointer"
            , style "box-shadow" "0 4px 6px -1px rgba(14, 165, 233, 0.2)"
            ]
            [ text "Primary Action" ]
        , button
            [ style "padding" "10px 20px"
            , style "background" "#f5f5f4"
            , style "color" "#44403c"
            , style "border" "1px solid #e7e5e4"
            , style "border-radius" "8px"
            , style "font-weight" "600"
            , style "font-size" "14px"
            , style "cursor" "pointer"
            ]
            [ text "Secondary Action" ]
        , button
            [ style "padding" "10px 20px"
            , style "background" "transparent"
            , style "color" "#0284c7"
            , style "border" "none"
            , style "border-radius" "8px"
            , style "font-weight" "600"
            , style "font-size" "14px"
            , style "cursor" "pointer"
            , style "text-decoration" "underline"
            ]
            [ text "Link Action" ]
        ]


{-|

    <shiori> alertBoxes

-}
alertBoxes : Html msg
alertBoxes =
    div
        [ style "display" "flex"
        , style "flex-direction" "column"
        , style "gap" "12px"
        , style "width" "100%"
        , style "max-width" "500px"
        ]
        [ div
            [ style "padding" "16px 20px"
            , style "background-color" "#eff6ff"
            , style "border-left" "4px solid #3b82f6"
            , style "border-radius" "0 8px 8px 0"
            , style "display" "flex"
            , style "flex-direction" "column"
            , style "gap" "4px"
            ]
            [ h4
                [ style "margin" "0"
                , style "font-size" "14px"
                , style "font-weight" "600"
                , style "color" "#1e3a8a"
                ]
                [ text "Information Update" ]
            , p
                [ style "margin" "0"
                , style "font-size" "12px"
                , style "color" "#2563eb"
                ]
                [ text "A new version of Shiori is available. Please update." ]
            ]
        , div
            [ style "padding" "16px 20px"
            , style "background-color" "#ecfdf5"
            , style "border-left" "4px solid #10b981"
            , style "border-radius" "0 8px 8px 0"
            , style "display" "flex"
            , style "flex-direction" "column"
            , style "gap" "4px"
            ]
            [ h4
                [ style "margin" "0"
                , style "font-size" "14px"
                , style "font-weight" "600"
                , style "color" "#064e3b"
                ]
                [ text "Success Event" ]
            , p
                [ style "margin" "0"
                , style "font-size" "12px"
                , style "color" "#059669"
                ]
                [ text "Your component styles have been isolated successfully." ]
            ]
        ]
