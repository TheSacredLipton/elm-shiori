module Css exposing (Model, main, view, premiumCard, switchToggle)

import Browser
import Html exposing (..)
import Html.Attributes exposing (class)


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

    <shiori> view (Model 0 "modelInitialValue2") </shiori>

-}
view : Model -> Html Msg
view _ =
    div [ class "hello" ]
        [ text "hello" ]


{-|

    <shiori> premiumCard </shiori>

-}
premiumCard : Html msg
premiumCard =
    div [ class "css-card" ]
        [ div [ class "css-card-banner" ] []
        , div [ class "css-card-content" ]
            [ h3 [ class "css-card-title" ] [ text "Creative Project" ]
            , p [ class "css-card-text" ]
                [ text "This component has its styles completely isolated inside an iframe using vanilla CSS files managed via shiori.json configuration." ]
            , button [ class "css-card-btn" ] [ text "Explore" ]
            ]
        ]


{-|

    <shiori> switchToggle </shiori>

-}
switchToggle : Html msg
switchToggle =
    div [ class "css-switch" ]
        [ div [ class "css-switch-track" ]
            [ div [ class "css-switch-thumb" ] []
            ]
        , span [ class "css-switch-label" ] [ text "Feature enabled" ]
        ]
