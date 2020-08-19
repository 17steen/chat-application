module Main exposing (main)
import Html exposing (..)
import Html.Attributes exposing (..)
import Browser


main =
    Browser.element
    { init = init
    , update = update
    , subscriptions = subscriptions
    , view = view
    }

type alias Model
  = {
      username : String,
      password : String,
      color : String,
      session : String,
      messages : List String,
      state : State
  }

type State
    = NotLogged
    | Logged

init : () -> (Model, Cmd Msg)
init  _ = 
    ({
        username = "",
        password = "",
        color = "red",
        session = "",
        messages = [],
        state = NotLogged
    }, Cmd.none)



type Msg 
    = Hello

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none

view : Model -> Html Msg
view model =
    text "Hello"
    
update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    (model, Cmd.none)
