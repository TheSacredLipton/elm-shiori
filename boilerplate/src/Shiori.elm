module Shiori exposing (main)

import Browser
import Browser.Navigation as Nav
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font
import Element.Input as Input
import Html exposing (Html)
import Shiori.Button0
import Shiori.Route as Route exposing (Route(..))
import Shiori.Ui0
import Url


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        , onUrlRequest = UrlRequested
        , onUrlChange = UrlChanged
        }


type alias Model =
    { key : Nav.Key
    , url : Url.Url
    }


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url key =
    ( { key = key
      , url = url
      }
    , Cmd.none
    )


type Msg
    = UrlRequested Browser.UrlRequest
    | UrlChanged Url.Url
    | NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UrlRequested urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        UrlChanged url ->
            ( { model | url = url }
            , Cmd.none
            )

        NoOp ->
            ( model, Cmd.none )


view : Model -> Browser.Document Msg
view model =
    { title = "Shiori"
    , body =
        [ layout [ width fill, height fill ] <|
            column [ width fill, height fill ]
                [ el
                    [ height <| px 48
                    , width fill
                    , Background.color <| rgb255 251 146 60
                    , Border.shadow
                        { offset = ( 2, 2 )
                        , size = 2
                        , blur = 2
                        , color = rgba255 0 0 0 0.2
                        }
                    ]
                  <|
                    row [ width <| px 800, height fill, centerX, Font.color <| rgb255 255 255 255 ]
                        [ link [] { url = "/", label = text "elm-shiori" } ]
                , row [ width <| px 800, height fill, centerX ]
                    [ column [ width <| px 300, height fill, paddingXY 10 30, spacing 18, Font.size 20 ] <|
                        List.map (\l -> link [] { url = "/" ++ l, label = text l }) Route.links
                    , column [ width fill, height fill, scrollbars, paddingXY 10 30 ] [ map (\_ -> NoOp) <| Route.view model.url none ]
                    ]
                ]
        ]
    }
