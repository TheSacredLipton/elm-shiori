module Shiori exposing (main)

import Browser
import Browser.Dom exposing (getViewport, setViewport)
import Browser.Events exposing (onResize)
import Browser.Navigation as Nav
import Html exposing (Html, a, div, iframe, img, map, text, node)
import Html.Attributes exposing (class, href, src, style, target, attribute)
import Html.Events exposing (onClick)
import Shiori.Route as Route
import Task
import Url
import Url.Builder as Builder


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> onResize (\w _ -> GetViewport <| Basics.toFloat w)
        , onUrlRequest = UrlRequested
        , onUrlChange = UrlChanged
        }


type alias Model =
    { key : Nav.Key
    , url : Url.Url
    , isActive : Bool
    , width : Float
    }


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url key =
    ( { key = key
      , url = url
      , isActive = False
      , width = 0
      }
    , Task.perform (\v -> GetViewport v.viewport.width) getViewport
    )


type Msg
    = UrlRequested Browser.UrlRequest
    | UrlChanged Url.Url
    | ToggleMenu
    | GetViewport Float
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
            ( { model | url = url, isActive = False }
            , Cmd.none
            )

        ToggleMenu ->
            ( { model | isActive = not model.isActive }, Task.perform (\_ -> NoOp) (setViewport 0 0) )

        GetViewport w ->
            ( { model | width = w }, Cmd.none )

        NoOp ->
            ( model, Cmd.none )


view : Model -> Browser.Document Msg
view model =
    { title = "elm-shiori"
    , body =
        [ if isPreviewMode model.url then
            div
                [ style "width" "100%"
                , style "height" "100vh"
                , style "background-color" "#ffffff"
                , style "box-sizing" "border-box"
                , style "padding" "24px"
                , style "overflow" "auto"
                ]
                [ div
                    [ style "gap" "24px"
                    , style "width" "100%"
                    , style "display" "flex"
                    , style "flex-direction" "column"
                    , style "max-width" "1200px"
                    , style "margin" "0 auto"
                    ]
                  <|
                    List.map (map (always NoOp)) (Route.view (stripPreviewPrefix model.url))
                ]

          else
            div
                [ style "display" "flex"
                , style "flex-direction" "column"
                , style "height" "100vh"
                ]
                [ header model.width model.url
                , header_
                , smNav model.isActive model.url
                , div
                    [ style "width" "100%"
                    , style "display" "flex"
                    , style "flex" "1"
                    , style "height" "calc(100vh - 48px)"
                    ]
                    [ sideNav model.width 250 model.url
                    , sideNav_ model.width 250
                    , body model.url
                    ]
                ]
        ]
    }


isPreviewMode : Url.Url -> Bool
isPreviewMode url =
    String.startsWith "/preview/" url.path || url.path == "/preview"


stripPreviewPrefix : Url.Url -> Url.Url
stripPreviewPrefix url =
    if String.startsWith "/preview/" url.path then
        { url | path = String.dropLeft 8 url.path }

    else if url.path == "/preview" then
        { url | path = "/" }

    else
        url


header : Float -> Url.Url -> Html Msg
header w url =
    div
        [ style "height" "48px"
        , style "width" "100%"
        , style "background-color" "rgba(255, 255, 255, 0.8)"
        , style "backdrop-filter" "blur(12px)"
        , style "-webkit-backdrop-filter" "blur(12px)"
        , style "border-bottom" "1px solid #e7e5e4"
        , style "display" "flex"
        , style "align-items" "center"
        , style "justify-content" "center"
        , style "left" "0"
        , style "position" "fixed"
        , style "top" "0"
        , style "z-index" "10"
        ]
        [ div
            [ style "width" "100%"
            , style "height" "100%"
            , style "padding" "0px 24px"
            , style "box-sizing" "border-box"
            , style "display" "flex"
            , style "justify-content" "space-between"
            , style "align-items" "center"
            ]
            [ div
                []
                [ a
                    [ href "/"
                    , style "color" "#1c1917"
                    , style "display" "flex"
                    , style "align-items" "center"
                    , style "font-weight" "700"
                    , style "font-size" "18px"
                    , style "text-decoration" "none"
                    , style "box-sizing" "border-box"
                    , style "letter-spacing" "-0.025em"
                    ]
                    [ logoIcon
                    , text "elm-shiori"
                    ]
                ]
            , div
                [ style "display" "flex"
                , style "align-items" "center"
                , style "gap" "12px"
                ]
                [ previewLink url
                , menuButton w
                ]
            ]
        ]


previewLink : Url.Url -> Html msg
previewLink url =
    if url.path == "/" then
        text ""

    else
        a
            [ href ("/preview" ++ url.path)
            , target "_blank"
            , style "color" "#0ea5e9"
            , style "font-size" "13px"
            , style "text-decoration" "none"
            , style "display" "flex"
            , style "align-items" "center"
            , style "gap" "4px"
            , style "padding" "6px 12px"
            , style "border" "1px solid #e0f2fe"
            , style "border-radius" "6px"
            , style "background-color" "#f0f9ff"
            , class "shiori-link"
            ]
            [ text "Open Preview ↗" ]


menuButton : Float -> Html Msg
menuButton w =
    div
        [ onClick ToggleMenu
        , style "padding" "8px 12px"
        , style "box-sizing" "border-box"
        , style "display" "block"
        , style "cursor" "pointer"
        , style "font-size" "18px"
        , style "color" "#57534e"
        , md w "display" "none"
        ]
        [ text "☰" ]


header_ : Html msg
header_ =
    div
        [ style "height" "48px"
        , style "flex-shrink" "0"
        ]
        []


sideNav : Float -> Int -> Url.Url -> Html msg
sideNav w width url =
    div
        [ style "width" <| String.fromInt width ++ "px"
        , style "height" "calc(100% - 48px)"
        , style "padding" "32px 16px"
        , style "box-sizing" "border-box"
        , style "flex-direction" "column"
        , style "gap" "24px"
        , style "border-right" "1px solid #e7e5e4"
        , style "position" "fixed"
        , style "display" "none"
        , style "overflow-y" "auto"
        , style "background-color" "#ffffff"
        , md w "display" "flex"
        ]
    <|
        List.map (sideNavLinkGroup url) Route.links


sideNav_ : Float -> Int -> Html msg
sideNav_ w width =
    div
        [ style "width" <| String.fromInt width ++ "px"
        , style "flex-shrink" "0"
        , style "display" "none"
        , md w "display" "flex"
        ]
        []


smNav : Bool -> Url.Url -> Html msg
smNav isActive url =
    if isActive then
        div
            [ style "display" "flex"
            , style "flex-direction" "column"
            , style "gap" "20px"
            , style "width" "100%"
            , style "box-sizing" "border-box"
            , style "padding" "24px 16px"
            , style "border-bottom" "1px solid #e7e5e4"
            , style "background-color" "#ffffff"
            ]
        <|
            List.map (sideNavLinkGroup url) Route.links

    else
        text ""


type alias FileName =
    String


type alias FunctionName =
    String


sideNavLinkGroup : Url.Url -> ( FileName, List ( FunctionName, List String ) ) -> Html msg
sideNavLinkGroup url ( fileName, v ) =
    div [ style "display" "flex", style "flex-direction" "column", style "gap" "4px", style "width" "100%" ]
        [ div
            [ style "font-size" "11px"
            , style "font-weight" "700"
            , style "color" "#a8a29e"
            , style "text-transform" "uppercase"
            , style "letter-spacing" "0.05em"
            , style "padding" "0px 12px"
            , style "margin-bottom" "6px"
            ]
            [ text fileName ]
        , div [ style "width" "100%", style "display" "flex", style "flex-direction" "column", style "gap" "2px" ] <|
            List.map (\( functionName, _ ) ->
                let
                    linkUrl = Builder.absolute [ fileName, functionName ] []
                    isActive = url.path == linkUrl
                in
                sideNavLink functionName linkUrl isActive
            ) v
        ]


sideNavLink : FunctionName -> String -> Bool -> Html msg
sideNavLink name url isActive =
    a
        [ style "width" "100%"
        , style "padding" "8px 12px"
        , style "color" "#57534e"
        , style "display" "block"
        , style "text-decoration" "none"
        , style "box-sizing" "border-box"
        , style "font-size" "14px"
        , href url
        , class <|
            if isActive then
                "shiori-link shiori-link-active"

            else
                "shiori-link"
        ]
        [ text name ]


body : Url.Url -> Html Msg
body url =
    div
        [ style "width" "100%"
        , style "padding" "24px"
        , style "box-sizing" "border-box"
        , style "height" "100%"
        ]
        [ if url.path == "/" then
            div
                [ style "display" "flex"
                , style "align-items" "center"
                , style "justify-content" "center"
                , style "height" "100%"
                , style "color" "#a8a29e"
                , style "font-size" "14px"
                ]
                [ text "サイドバーからコンポーネントを選択してください" ]

          else
            iframe
                [ src ("/preview" ++ url.path)
                , class "shiori-preview-iframe"
                ]
                []
        ]


md : Float -> String -> String -> Html.Attribute msg
md w a b =
    if w > 768 then
        style a b

    else
        style "" ""


logoIcon : Html msg
logoIcon =
    img
        [ src "/shiori-logo.svg"
        , style "width" "20px"
        , style "height" "20px"
        , style "margin-right" "8px"
        , style "display" "inline-block"
        , style "vertical-align" "middle"
        ]
        []
