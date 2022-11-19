module Main exposing (..)

import Browser
import Element exposing (..)
import Element.Input as Input
import Html exposing (Html)


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    { property : Int
    }


init : flags -> ( Model, Cmd Msg )
init _ =
    ( { property = 0
      }
    , Cmd.none
    )


type Msg
    = ReplaceMe


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ReplaceMe ->
            ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


view : Model -> Html Msg
view _ =
    layout [] <|
        text "Hello World"


{-| UITEST:BUTTON

    import Dict

    : layout [] <| try 1

    : layout [] <| try 2

    : layout [] <| try 3

-}
try i =
    text "tomtom"


try2 i =
    Input.button [] { label = text "ok", onPress = Just ReplaceMe }
