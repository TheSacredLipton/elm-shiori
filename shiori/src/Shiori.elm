module Shiori exposing (main)

import Browser
import Browser.Navigation as Nav
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Shiori.Route as Route
import Url
import Url.Builder as Builder


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


colors =
    { white = rgb255 255 255 255
    , lightGray = rgb255 240 240 240
    , gray = rgb255 150 150 150
    , dark = rgb255 50 50 50
    , orange = rgb255 251 146 60
    }


view : Model -> Browser.Document Msg
view model =
    { title = "elm-shiori"
    , body =
        [ layout [ width fill, height fill, noto, Font.color colors.dark ] <|
            column [ width fill, height fill ]
                [ header
                , row [ containerWidth, height fill, centerX, spacing 24 ]
                    [ sideNav
                    , body model.url
                    ]
                ]
        ]
    }


noto : Attribute msg
noto =
    Font.family
        [ Font.external
            { name = "Noto Sans JP"
            , url = "https://fonts.googleapis.com/css?family=Noto+Sans+JP"
            }
        , Font.sansSerif
        ]


header : Element msg
header =
    el
        [ height <| px 48
        , width fill
        , Background.color colors.orange
        , Border.shadow { offset = ( 2, 2 ), size = 2, blur = 2, color = rgba255 0 0 0 0.2 }
        ]
    <|
        row [ containerWidth, height fill, centerX, Font.color colors.white ]
            [ link [] { url = Builder.absolute [] [], label = text "elm-shiori" } ]


containerWidth : Attribute msg
containerWidth =
    width <| px 900


sideNav : Element msg
sideNav =
    column
        [ width <| px 250
        , height fill
        , contentsPadding
        , Border.widthXY 2 0
        , Border.color colors.lightGray
        , spacing 24
        ]
    <|
        List.map sideNavLinkGroup Route.links


type alias FileName =
    String


type alias FunctionName =
    String


sideNavLinkGroup : ( FileName, List ( FunctionName, List String ) ) -> Element msg
sideNavLinkGroup ( fileName, v ) =
    column [ spacing 8, width fill ]
        [ el [ Font.size 20 ] <| text fileName
        , column [ width fill, Font.size 16 ] <| List.map (\( functionName, _ ) -> sideNavLink functionName <| Builder.absolute [ fileName, functionName ] []) v
        ]


sideNavLink : String -> String -> Element msg
sideNavLink name url =
    link [ width fill, paddingXY 10 8, Font.color colors.gray, mouseOver [ Font.color colors.dark ] ]
        { url = url, label = text name }


body : Url.Url -> Element Msg
body url =
    column [ width fill, height fill, scrollbars, contentsPadding, spacing 20 ] <|
        List.map (map (always NoOp)) (Route.view url)


contentsPadding : Attribute msg
contentsPadding =
    paddingXY 10 30
