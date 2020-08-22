module Main exposing (main)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput, onSubmit)
import Http
import Json.Decode as D exposing (Decoder)
import Json.Encode as Enc
import List
import Material.Button as Button
import Material.Elevation as Elevation
import Material.FormField as FormField
import Material.List as MList
import Material.List.Item as ListItem
import Material.Slider as Slider
import Material.TextField as TextField
import Material.Theme as Theme
import Material.Typography as Typography
import Maybe exposing (andThen)
import String
import Svg exposing (Svg)
import Svg.Attributes as SA
import Time

-- ripped from json extra package
andMap : Decoder a -> Decoder (a -> b) -> Decoder b
andMap =
    D.map2 (|>)



-- MAIN


main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


type alias Model =
    { username : String
    , password : String
    , color : String
    , colorValue : Float
    , session : String
    , messages : List Message
    , currentMessage : String
    , state : State
    }


type State
    = NotLogged
    | Logged


init : () -> ( Model, Cmd Msg )
init _ =
    ( { username = ""
      , password = ""
      , color = "red"
      , colorValue = 0
      , session = ""
      , messages = []
      , currentMessage = ""
      , state = NotLogged
      }
    , attemptAutoLogin
    )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.state of
        NotLogged ->
            Sub.none

        Logged ->
            Time.every 333 GetMessages



-- VIEW


view : Model -> Html Msg
view model =
    case model.state of
        NotLogged ->
            loginForm model

        Logged ->
            chatForm model


calcUsernameBackgroundWidth : String -> String
calcUsernameBackgroundWidth usr =
    String.fromInt (String.length ("Username: " ++ usr) + 5) ++ "em"


chatForm : Model -> Html Msg
chatForm model =
    div [ class "chat-container" ]
        [ div [ class "username-display", style "width" (calcUsernameBackgroundWidth model.username) ] [ h4 [ Typography.headline4 ] [ text "Username: ", span [ style "color" model.color ] [ text model.username ] ] ]
        , colorDisplay model
        , viewMessageList model.messages
        , sendMessageForm model
        ]


colorDisplay : Model -> Html Msg
colorDisplay m =
    Slider.slider
        (Slider.config
            |> Slider.setAttributes []
            |> Slider.setValue (Just m.colorValue)
            |> Slider.setMax (Just 360)
            |> Slider.setOnInput ColorChanged
        )


viewMessageList : List Message -> Html Msg
viewMessageList messages =
    let
        svgCircle : String -> Html Msg
        svgCircle c =
            Svg.svg [] [ Svg.circle [ SA.r "18", SA.cx "22", SA.cy "70", SA.color c ] [] ]

        toList : Message -> ListItem.ListItem Msg
        toList m =
            ListItem.listItem
                (ListItem.config
                    |> ListItem.setAttributes [ class "message-item" ]
                )
                [ ListItem.graphic [ Elevation.z16 ] [ svgCircle m.color ]
                , ListItem.text []
                    { primary = [ span [ class "message-sender", style "color" m.color ] [ text m.sender ] ]
                    , secondary = [ span [ class "message-text" ] (formatMessage m.text) ]
                    }
                ]

        getHead : List Message -> Message
        getHead l =
            case List.head l of
                Just m ->
                    m

                Nothing ->
                    -- doesn't reach
                    Message "" "" "" 0
    in
    case List.isEmpty messages of
        True ->
            h3 [ Typography.headline3 ] [ text "Looks like there are no messages yet!" ]

        False ->
            MList.list
                (MList.config
                    |> MList.setNonInteractive False
                    |> MList.setTwoLine True
                    |> MList.setAvatarList True
                    |> MList.setAttributes [ class "message-list-container", Elevation.z24 ]
                )
                (toList (getHead messages))
                (List.map toList (List.drop 1 messages))


sendMessageForm : Model -> Html Msg
sendMessageForm model =
    Html.form [ onSubmit SendMessage, class "message-form" ]
        [ TextField.filled
            (TextField.config
                |> TextField.setType (Just "text")
                |> TextField.setAttributes [ class "inputfield1" ]
                |> TextField.setPlaceholder (Just "Type here...")
                |> TextField.setValue (Just model.currentMessage)
                |> TextField.setRequired True
                |> TextField.setOnInput UpdateMessage
                |> TextField.setLeadingIcon (Just (TextField.icon [] (determineIcon model.currentMessage)))
            )
        ]


determineIcon : String -> String
determineIcon msg =
    case String.length msg of
        0 ->
            "chat_bubble_outline"

        _ ->
            "chat"


sendMessage : Model -> Cmd Msg
sendMessage m =
    Http.post
        { url = "http://localhost:8080/message"
        , body =
            Http.jsonBody
                (Enc.object
                    [ ( "username", Enc.string m.username )
                    , ( "color", Enc.string m.color )
                    , ( "text", Enc.string m.currentMessage )
                    ]
                )
        , expect = Http.expectString MessageSent
        }


styles : List ( String, List (Attribute Msg) -> List (Html Msg) -> Html Msg )
styles =
    [ ( "**", Html.b ), ( "*", Html.i ), ( "__", Html.u ), ( "~~", Html.s ) ]


formatMessage : String -> List (Html Msg)
formatMessage str =
    -- easiest *here*
    case createStylelist str of
        [] ->
            [ text str ]

        ( chars, tag ) :: restoflist ->
            case String.split chars str of
                a :: b :: c :: rest ->
                    [ text a ] ++ [ tag [] (formatMessage b) ] ++ formatMessage (String.join chars (c :: rest))

                _ ->
                    [ text str ]


createStylelist : String -> List ( String, List (Attribute Msg) -> List (Html Msg) -> Html Msg )
createStylelist str =
    let
        getHead : List Int -> Int
        getHead list =
            case List.head list of
                Just number ->
                    number

                _ ->
                    0
    in
    styles
        |> List.filter (\( char, b ) -> List.length (String.indexes char str) >= 2)
        |> List.sortBy (\( char, b ) -> getHead (String.indexes char str))


loginForm : Model -> Html Msg
loginForm model =
    Html.form [ onSubmit AttemptLogin, class "login-form" ]
        [ TextField.filled
            (TextField.config
                |> TextField.setType (Just "text")
                |> TextField.setAttributes [ class "inputfield1" ]
                |> TextField.setPlaceholder (Just "Username...")
                |> TextField.setValue (Just model.username)
                |> TextField.setRequired True
                |> TextField.setOnInput UpdateUsername
                |> TextField.setLeadingIcon (Just (TextField.icon [] "face"))
            )
        , TextField.filled
            (TextField.config
                |> TextField.setType (Just "password")
                |> TextField.setAttributes [ class "inputfield1" ]
                |> TextField.setPlaceholder (Just "Password...")
                |> TextField.setValue (Just model.password)
                |> TextField.setRequired True
                |> TextField.setOnInput UpdatePassword
                |> TextField.setLeadingIcon (Just (TextField.icon [] "vpn_key"))
            )
        , Button.raised (Button.config |> Button.setAttributes [ type_ "submit" ]) "LOGIN"
        ]


postLogin : Model -> Cmd Msg
postLogin model =
    Http.post
    { url = "http://localhost:8080/login"
    , body =
        Http.jsonBody
            (Enc.object
                [ ( "authType", Enc.string "default" )
                , ( "username", Enc.string model.username )
                , ( "password", Enc.string model.password )
                ]
            )
    , expect = Http.expectJson GotLogin loginDecoder
    }


type alias LoginInfo =
    { sessionId : String
    , username : String
    , status : Int
    }


loginDecoder : Decoder LoginInfo
loginDecoder =
    D.map3 LoginInfo
        (D.field "id" D.string)
        (D.field "username" D.string)
        (D.field "status" D.int)


attemptAutoLogin : Cmd Msg
attemptAutoLogin =
    Http.riskyRequest
        { method = "POST"
        , headers = []
        , url = "http://localhost:8080/login"
        , body =
            Http.jsonBody
                (Enc.object
                    [ ( "authType", Enc.string "autologin" )
                    , ( "username", Enc.string "" )
                    , ( "password", Enc.string "" )
                    ]
                )
        , expect = Http.expectJson GotLogin loginDecoder
        , timeout = Nothing
        , tracker = Nothing
        }


getMessages : Model -> Cmd Msg
getMessages model =
    Http.get
        { url = "http://localhost:8080/message"
        , expect = Http.expectJson GotMessages messageDecoder
        }


type alias Message =
    { sender : String
    , color : String
    , text : String
    , timestamp : Int
    }


messageDecoder : Decoder (List Message)
messageDecoder =
    D.succeed Message
        -- Decoder (String -> String -> String -> Int -> Message)
        |> andMap (D.field "username" D.string)
        -- Decoder (String -> String -> Int -> Message)
        |> andMap (D.field "color" D.string)
        -- Decoder (String -> Int -> Message)
        |> andMap (D.field "text" D.string)
        -- Decoder (Int -> Message)
        |> andMap (D.field "createdAt" D.int)
        -- Decoder (Message)
        |> D.list



-- UPDATE


type Msg
    = AttemptLogin
    | GotLogin (Result Http.Error LoginInfo)
    | UpdateUsername String
    | UpdatePassword String
    | GetMessages Time.Posix
    | GotMessages (Result Http.Error (List Message))
    | UpdateMessage String
    | SendMessage
    | MessageSent (Result Http.Error String)
    | ColorChanged Float


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AttemptLogin ->
            ( model, postLogin model )

        GotLogin result ->
            case result of
                Ok info ->
                    ( { model
                        | username = info.username
                        , session = info.sessionId
                        , state = Logged
                      }
                    , getMessages model
                    )

                Err _ ->
                    ( model, Cmd.none )

        UpdateUsername username ->
            ( { model | username = username }, Cmd.none )

        UpdatePassword password ->
            ( { model | password = password }, Cmd.none )

        UpdateMessage message ->
            ( { model | currentMessage = message }, Cmd.none )

        SendMessage ->
            ( { model | currentMessage = "" }, sendMessage model )

        MessageSent result ->
            case result of
                Ok _ ->
                    ( model, getMessages model )

                Err _ ->
                    ( model, Cmd.none )

        GetMessages _ ->
            ( model, getMessages model )

        GotMessages result ->
            case result of
                Ok messages ->
                    ( { model | messages = messages }, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )

        ColorChanged f ->
            ( { model | color = "hsl(" ++ String.fromFloat f ++ ", 100%, 50%)", colorValue = f }, Cmd.none )
