module ElmUI exposing (Model, main, view, button, productCard, badgeList)

import Browser
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html exposing (Html)


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


view : Model -> Html Msg
view _ =
    layout [] <|
        column []
            [ button "button"
            ]


{-|
    <shiori name="Primary Button"> ElmUI.button "Primary" </shiori>
    <shiori name="Success Button"> ElmUI.button "Success" </shiori>
    <shiori name="Danger Button"> ElmUI.button "Danger" </shiori>
-}
button : String -> Element msg
button str =
    Input.button
        [ Background.color (rgb255 14 165 233)
        , Font.color (rgb255 255 255 255)
        , paddingXY 24 14
        , Border.rounded 8
        , Font.size 14
        , Font.bold
        , Border.shadow { offset = (0, 4), size = 0, blur = 6, color = rgba255 14 165 233 0.2 }
        ]
        { label = text str, onPress = Nothing }


{-|
    <shiori name="Product Card A"> ElmUI.productCard </shiori>
    <shiori name="Product Card B"> ElmUI.productCard </shiori>
-}
productCard : Element msg
productCard =
    column
        [ width (px 300)
        , Background.color (rgb255 255 255 255)
        , Border.rounded 16
        , Border.shadow { offset = (0, 8), size = 0, blur = 16, color = rgba255 0 0 0 0.05 }
        , Border.width 1
        , Border.color (rgb255 243 244 246)
        , clip
        ]
        [ image [ width fill, height (px 180) ] { src = "https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400&q=80", description = "Product Image" }
        , column [ padding 20, spacing 12, width fill ]
            [ el [ Font.size 11, Font.bold, Font.color (rgb255 156 163 175) ] (text "GADGET")
            , paragraph [ Font.size 16, Font.bold, Font.color (rgb255 31 41 55) ] [ text "Minimalist Smart Watch" ]
            , row [ width fill, spaceEvenly ]
                [ el [ Font.size 18, Font.bold, Font.color (rgb255 14 165 233) ] (text "$199.00")
                , Input.button
                    [ Background.color (rgb255 31 41 55)
                    , Font.color (rgb255 255 255 255)
                    , paddingXY 16 8
                    , Border.rounded 8
                    , Font.size 12
                    , Font.bold
                    ]
                    { label = text "Buy Now", onPress = Nothing }
                ]
            ]
        ]


{-|
    <shiori name="Status Badges"> ElmUI.badgeList </shiori>
-}
badgeList : Element msg
badgeList =
    row [ spacing 8, padding 10 ]
        [ el
            [ Background.color (rgb255 239 246 255)
            , Font.color (rgb255 37 99 235)
            , Font.size 12
            , Font.bold
            , paddingXY 10 6
            , Border.rounded 9999
            ]
            (text "Info Badge")
        , el
            [ Background.color (rgb255 236 253 245)
            , Font.color (rgb255 5 150 105)
            , Font.size 12
            , Font.bold
            , paddingXY 10 6
            , Border.rounded 9999
            ]
            (text "Success Badge")
        ]
