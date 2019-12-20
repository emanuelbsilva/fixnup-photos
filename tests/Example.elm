module Example exposing (initTest)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Main as Main
import Test exposing (..)
import Test.Html.Query as Query
import Test.Html.Selector exposing (tag, text)


initTest =
    describe "dummy test suite"
        [ test "dummy test" <|
            \() ->
                Expect.equal 1 1
        ]
