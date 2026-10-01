port module Main exposing (main)

import Browser
import Html exposing (..)
import Html.Attributes exposing (class, classList, disabled, placeholder, type_, value)
import Html.Events exposing (onClick, onInput, onSubmit)


port hashChanged : (String -> msg) -> Sub msg



-- MODEL


type Column
    = Todo
    | Doing
    | Done


type alias Task =
    { id : Int
    , title : String
    , tag : String
    , who : String
    , column : Column
    }


type Board
    = Loaded
    | Empty
    | Failed String


type alias Model =
    { board : Board
    , tasks : List Task
    , draft : String
    , filter : Maybe String
    , nextId : Int
    }


seed : List Task
seed =
    [ Task 1 "Sketch the onboarding flow" "design" "MK" Todo
    , Task 2 "Write release notes for 2.4" "docs" "AL" Todo
    , Task 3 "Fix the flaky upload test" "bug" "JS" Doing
    , Task 4 "Migrate billing to the new API" "backend" "RO" Doing
    , Task 5 "Audit keyboard navigation" "design" "MK" Doing
    , Task 6 "Set up error budget dashboard" "backend" "AL" Done
    , Task 7 "Replace the empty-state icons" "design" "JS" Done
    ]


init : String -> ( Model, Cmd Msg )
init hash =
    ( fromHash hash { board = Loaded, tasks = seed, draft = "", filter = Nothing, nextId = 8 }
    , Cmd.none
    )


fromHash : String -> Model -> Model
fromHash hash model =
    case hash of
        "#empty" ->
            { model | board = Empty, tasks = [] }

        "#error" ->
            { model | board = Failed "The board service did not answer (timeout after 10 s)." }

        _ ->
            { model | board = Loaded, tasks = seed, filter = Nothing }



-- UPDATE


type Msg
    = Hash String
    | Draft String
    | Add
    | Move Int Column
    | Remove Int
    | Filter (Maybe String)
    | Retry


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Hash hash ->
            ( fromHash hash model, Cmd.none )

        Draft text ->
            ( { model | draft = text }, Cmd.none )

        Add ->
            if String.isEmpty (String.trim model.draft) then
                ( model, Cmd.none )

            else
                ( { model
                    | board = Loaded
                    , tasks = model.tasks ++ [ Task model.nextId (String.trim model.draft) "new" "ME" Todo ]
                    , draft = ""
                    , nextId = model.nextId + 1
                  }
                , Cmd.none
                )

        Move id column ->
            ( { model | tasks = List.map (\t -> if t.id == id then { t | column = column } else t) model.tasks }
            , Cmd.none
            )

        Remove id ->
            ( { model | tasks = List.filter (\t -> t.id /= id) model.tasks }, Cmd.none )

        Filter tag ->
            ( { model | filter = tag }, Cmd.none )

        Retry ->
            ( { model | board = Loaded, tasks = seed }, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "app" ]
        [ viewHeader model
        , case model.board of
            Failed why ->
                viewError why

            _ ->
                viewBoard model
        ]


viewHeader : Model -> Html Msg
viewHeader model =
    header [ class "top" ]
        [ div [ class "brand" ] [ span [ class "logo" ] [ text "H" ], h1 [] [ text "Harbor" ], span [ class "crumb" ] [ text "Website relaunch" ] ]
        , form [ class "add", onSubmit Add ]
            [ input [ type_ "text", placeholder "Add a task and press Enter", value model.draft, onInput Draft ] []
            , button [ type_ "submit", class "primary", disabled (String.isEmpty (String.trim model.draft)) ] [ text "Add task" ]
            ]
        ]


tagsOf : List Task -> List String
tagsOf tasks =
    List.foldr (\t acc -> if List.member t.tag acc then acc else t.tag :: acc) [] tasks |> List.sort


viewBoard : Model -> Html Msg
viewBoard model =
    let
        shown =
            case model.filter of
                Nothing ->
                    model.tasks

                Just tag ->
                    List.filter (\t -> t.tag == tag) model.tasks
    in
    main_ []
        [ div [ class "filters" ]
            (span [ class "label" ] [ text "Filter" ]
                :: chip model.filter Nothing "All"
                :: List.map (\t -> chip model.filter (Just t) t) (tagsOf model.tasks)
            )
        , if List.isEmpty model.tasks then
            div [ class "empty" ]
                [ h2 [] [ text "No tasks yet" ]
                , p [] [ text "Type a title above to create the first card on this board." ]
                ]

          else
            div [ class "cols" ] (List.map (viewColumn shown) [ Todo, Doing, Done ])
        ]


chip : Maybe String -> Maybe String -> String -> Html Msg
chip current this label =
    button [ class "chip", classList [ ( "on", current == this ) ], onClick (Filter this) ] [ text label ]


columnName : Column -> String
columnName c =
    case c of
        Todo ->
            "To do"

        Doing ->
            "In progress"

        Done ->
            "Done"


viewColumn : List Task -> Column -> Html Msg
viewColumn tasks column =
    let
        mine =
            List.filter (\t -> t.column == column) tasks
    in
    section [ class "col" ]
        [ h2 [] [ text (columnName column), span [ class "count" ] [ text (String.fromInt (List.length mine)) ] ]
        , div [ class "cards" ] (List.map viewCard mine)
        ]


viewCard : Task -> Html Msg
viewCard t =
    article [ class "card" ]
        [ p [ class "title" ] [ text t.title ]
        , div [ class "meta" ]
            [ span [ class ("tag " ++ t.tag) ] [ text t.tag ]
            , span [ class "who" ] [ text t.who ]
            ]
        , div [ class "actions" ]
            [ button [ disabled (t.column == Todo), onClick (Move t.id (before t.column)) ] [ text "Back" ]
            , button [ disabled (t.column == Done), onClick (Move t.id (after t.column)) ] [ text "Next" ]
            , button [ class "danger", onClick (Remove t.id) ] [ text "Delete" ]
            ]
        ]


before : Column -> Column
before c =
    if c == Done then Doing else Todo


after : Column -> Column
after c =
    if c == Todo then Doing else Done


viewError : String -> Html Msg
viewError why =
    main_ []
        [ div [ class "error", Html.Attributes.attribute "role" "alert" ]
            [ h2 [] [ text "Could not load the board" ]
            , p [] [ text why ]
            , button [ class "primary", onClick Retry ] [ text "Try again" ]
            ]
        ]



-- MAIN


main : Program String Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = \_ -> hashChanged Hash
        }
