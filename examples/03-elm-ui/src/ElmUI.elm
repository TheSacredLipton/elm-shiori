module ElmUI exposing (..)

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

    <shiori> button "button"

    <shiori> button "button2"

-}
button : String -> Element msg
button str =
    Input.button
        [ Background.color (rgb255 40 40 40)
        , Font.color (rgb 255 255 255)
        , paddingXY 30 20
        , Border.rounded 10
        , mouseOver [ Background.color (rgb255 100 100 100) ]
        ]
        { label = text str, onPress = Nothing }
