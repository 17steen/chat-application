port module Main exposing (main)

import Browser
import Debug
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
import Material.Switch as Switch
import Material.TextField as TextField
import Material.Theme as Theme
import Material.Typography as Typography
import SolidColor as SC
import String
import Svg exposing (Svg)
import Svg.Attributes as SA exposing (color)
import Time


hueToHex : Float -> String
hueToHex hue =
    SC.toHex (SC.fromHSL ( hue, 100, 50 ))


first3 : ( a, b, c ) -> a
first3 ( a, _, _ ) =
    a


hasChars : String -> Bool
hasChars str =
    not <|
        String.isEmpty <|
            str


hexToHue : String -> Float
hexToHue hex =
    case SC.fromHex hex of
        Ok val ->
            first3 (SC.toHSL val)

        _ ->
            0



-- ripped from json extra package


andMap : Decoder a -> Decoder (a -> b) -> Decoder b
andMap =
    D.map2 (|>)



-- PORTS


port setStorage : ( String, String ) -> Cmd any



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
    , password_confirm : String
    , colorValue : Float
    , session : String
    , messages : List Message
    , currentMessage : String
    , state : State
    }


type State
    = NotLogged FormType
    | Logged


type FormType
    = Login
    | Register


init : String -> ( Model, Cmd Msg )
init flags =
    ( { username = ""
      , password = ""
      , password_confirm = ""
      , colorValue = hexToHue flags
      , messages = []
      , session = ""
      , currentMessage = ""
      , state = NotLogged Login
      }
    , attemptAutoLogin
    )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.state of
        Logged ->
            -- this should probably be a flag
            Time.every 333 GetMessages

        _ ->
            Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    case model.state of
        NotLogged formType ->
            displayForm model formType

        Logged ->
            chatForm model


calcUsernameBackgroundWidth : String -> String
calcUsernameBackgroundWidth usr =
    String.fromInt (String.length ("Username: " ++ usr) + 5) ++ "em"


chatForm : Model -> Html Msg
chatForm model =
    div [ class "chat-container" ]
        [ div [ class "username-display", style "width" (calcUsernameBackgroundWidth model.username) ] [ h4 [ Typography.headline4 ] [ text "Username: ", span [ style "color" (hueToHex model.colorValue) ] [ text model.username ] ] ]
        , colorDisplay model
        , viewMessageList model.messages
        , sendMessageForm model
        ]


colorDisplay : Model -> Html Msg
colorDisplay m =
    div [ class "slider-container" ]
        [ Slider.slider
            (Slider.config
                |> Slider.setAttributes []
                |> Slider.setValue (Just m.colorValue)
                |> Slider.setMax (Just 360)
                |> Slider.setOnInput ColorChanged
            )
        ]


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
                    |> ListItem.setAttributes [ class "message-item", style "height" "auto" ]
                )
                [ ListItem.graphic [ Elevation.z16 ] [ svgCircle m.color ]
                , ListItem.text []
                    { primary = [ span [ class "message-sender", style "color" m.color ] [ text m.sender ] ]
                    , secondary = [ span [ class "message-text" ] (formatMessage m.text) ]
                    }
                ]
    in
    case List.head messages of
        Nothing ->
            h3 [ Typography.headline3 ] [ text "Looks like there are no messages yet!" ]

        Just head ->
            MList.list
                (MList.config
                    |> MList.setNonInteractive False
                    |> MList.setTwoLine True
                    |> MList.setAvatarList True
                    |> MList.setAttributes [ class "message-list-container", Elevation.z24 ]
                )
                (toList head)
                (List.map toList (List.drop 1 messages))


sendMessageForm : Model -> Html Msg
sendMessageForm model =
    Html.form [ onSubmit SendMessage, class "message-form" ]
        [ materialTextField model.currentMessage "text" "Type here..." [] (determineIcon model.currentMessage) (not (String.isEmpty model.currentMessage)) UpdateMessage
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
        { url = "/message"
        , body =
            Http.jsonBody
                (Enc.object
                    [ ( "username", Enc.string m.username )
                    , ( "color", Enc.string (hueToHex m.colorValue) )
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


materialTextField : String -> String -> String -> List (Attribute Msg) -> String -> Bool -> (String -> Msg) -> Html Msg
materialTextField str setType placeholder arr icon isValid updateFunction =
    TextField.filled
        (TextField.config
            |> TextField.setType (Just setType)
            |> TextField.setAttributes ([ style "width" "100%", class "material-text-field" ] ++ arr)
            |> TextField.setPlaceholder (Just placeholder)
            |> TextField.setValue (Just str)
            |> TextField.setRequired True
            |> TextField.setOnInput updateFunction
            |> TextField.setValid (not (String.isEmpty str))
            |> TextField.setLeadingIcon (Just (TextField.icon [] icon))
        )


displayForm : Model -> FormType -> Html Msg
displayForm model formType =
    let
        hide bool el =
            case bool of
                True ->
                    span [ class "confirm-password tobehidden" ] [ el ]

                _ ->
                    span [ class "confirm-password" ] [ el ]

        either a b =
            case formType of
                Login ->
                    a

                Register ->
                    b
    in
    Html.form [ onSubmit (either AttemptLogin AttemptRegister), class "login-form" ]
        [ materialTextField model.username "text" "Username..." [] "face" (hasChars model.username) UpdateUsername
        , materialTextField model.password "password" "Password..." [] "vpn_key" (hasChars model.password) UpdatePassword
        , hide (either True False) (materialTextField model.password_confirm "password" "Please confirm your password..." [ disabled (either True False) ] "vpn_key" (not (String.isEmpty model.password_confirm)) UpdatePasswordConfirm)
        , span [ class "changing-text" ] [ Button.raised (Button.config |> Button.setAttributes [ type_ "submit", style "width" "100%" ]) (either "LOGIN" "REGISTER") ]
        , span [ class "changing-text" ] [ Button.raised (Button.config |> Button.setAttributes [ type_ "button", style "width" "100%" ] |> Button.setOnClick (either ShowRegisterForm ShowLoginForm)) (either "GO TO REGISTER" "GO TO LOGIN") ]
        ]


postLogin : Model -> Cmd Msg
postLogin model =
    Http.post
        { url = "/login"
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


postRegister : Model -> Cmd Msg
postRegister m =
    Http.post
        { url = "/register"
        , body =
            Http.jsonBody
                (Enc.object
                    [ ( "username", Enc.string m.username )
                    , ( "password", Enc.string m.password )
                    , ( "password2", Enc.string m.password_confirm )
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
        , url = "/login"
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
        { url = "/message"
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
    | AttemptRegister
    | GotLogin (Result Http.Error LoginInfo)
    | UpdateUsername String
    | UpdatePassword String
    | UpdatePasswordConfirm String
    | GetMessages Time.Posix
    | GotMessages (Result Http.Error (List Message))
    | UpdateMessage String
    | SendMessage
    | MessageSent (Result Http.Error String)
    | ColorChanged Float
    | ShowRegisterForm
    | ShowLoginForm


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AttemptLogin ->
            ( model, postLogin model )

        AttemptRegister ->
            ( model, postRegister model )

        GotLogin result ->
            case result of
                Ok info ->
                    case info.status of
                        1 ->
                            ( { model
                                | username = info.username
                                , session = info.sessionId
                                , state = Logged
                              }
                            , getMessages model
                            )

                        _ ->
                            ( model, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )

        UpdateUsername username ->
            ( { model | username = username }, Cmd.none )

        UpdatePassword password ->
            ( { model | password = password }, Cmd.none )

        UpdatePasswordConfirm password ->
            ( { model | password_confirm = password }, Cmd.none )

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
            ( { model | colorValue = f }, setStorage ( "color", hueToHex model.colorValue ) )

        ShowLoginForm ->
            ( { model | state = NotLogged Login, password = "", password_confirm = "" }, Cmd.none )

        ShowRegisterForm ->
            ( { model | state = NotLogged Register, password = "" }, Cmd.none )
