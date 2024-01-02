module Button exposing (..)

import Html exposing (Html, div, text)
import Html.Events exposing (onClick)


type Msg
    = Sample


{-|

    <shiori> button

-}
button : Html Msg
button =
    div []
        [ Html.button [ onClick Sample ] [ text "button" ]
        ]
