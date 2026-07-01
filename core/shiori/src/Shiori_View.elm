module Shiori_View exposing (card, map, solo)

import Html exposing (Html, div, text)
import Html.Attributes exposing (style)


map : List (Html msg) -> List (Html ())
map =
    List.map <| Html.map (always ())


card : String -> Html msg -> Html msg
card label content =
    div
        [ style "border" "1px solid #e7e5e4"
        , style "border-radius" "12px"
        , style "background-color" "#ffffff"
        , style "display" "flex"
        , style "flex-direction" "column"
        , style "overflow" "hidden"
        , style "box-shadow" "0 1px 3px 0 rgba(0, 0, 0, 0.05)"
        ]
        [ div
            [ style "padding" "10px 16px"
            , style "background-color" "#fafaf9"
            , style "border-bottom" "1px solid #e7e5e4"
            , style "font-size" "12px"
            , style "font-weight" "600"
            , style "color" "#78716c"
            , style "letter-spacing" "0.025em"
            ]
            [ text label ]
        , div
            [ style "padding" "24px"
            , style "display" "flex"
            , style "justify-content" "center"
            , style "align-items" "center"
            , style "background-color" "#ffffff"
            ]
            [ content ]
        ]


solo : Html msg -> Html msg
solo content =
    div
        [ style "width" "100%"
        , style "height" "100%"
        , style "display" "flex"
        , style "justify-content" "center"
        , style "align-items" "center"
        ]
        [ content ]
