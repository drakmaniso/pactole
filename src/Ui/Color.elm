module Ui.Color exposing (black, expense30, expense40, expense50, expense80, expense90, expense95, focus85, income30, income40, income50, income80, income90, income95, neutral10, neutral20, neutral30, neutral40, neutral50, neutral60, neutral70, neutral80, neutral90, neutral93, neutral95, neutral98, primary30, primary40, primary50, primary80, primary90, primary95, transactionColor, transparent, warning50, warning60, warning70, white)

import Bitwise
import Element as E


hex : Int -> E.Color
hex color =
    E.rgb255
        (color |> Bitwise.and 0x00FF0000 |> Bitwise.shiftRightBy 16)
        (color |> Bitwise.and 0xFF00 |> Bitwise.shiftRightBy 8)
        (color |> Bitwise.and 0xFF)


transparent : E.Color
transparent =
    E.rgba 0 0 0 0


warning70 : E.Color
warning70 =
    hex 0x00FF8263


warning60 : E.Color
warning60 =
    hex 0x00FE4200


warning50 : E.Color
warning50 =
    hex 0x00D23500


focus85 : E.Color
focus85 =
    -- E.rgb 1.0 0.7 0
    hex 0x00FFD000


white : E.Color
white =
    E.rgb 1.0 1.0 1.0


neutral98 : E.Color
neutral98 =
    hex 0x00F9F9F9


neutral95 : E.Color
neutral95 =
    -- E.rgb 0.95 0.95 0.95
    hex 0x00F1F1F1


neutral93 : E.Color
neutral93 =
    -- E.rgb 0.9 0.9 0.9
    hex 0x00EBEBEB


neutral90 : E.Color
neutral90 =
    -- E.rgb 0.9 0.9 0.9
    hex 0x00E2E2E2


neutral80 : E.Color
neutral80 =
    -- E.rgb 0.7 0.7 0.7
    hex 0x00C7C7C7


neutral70 : E.Color
neutral70 =
    -- E.rgb 0.7 0.7 0.7
    hex 0x00ABABAB


neutral60 : E.Color
neutral60 =
    hex 0x00919191


neutral50 : E.Color
neutral50 =
    -- E.rgb 0.5 0.5 0.5
    hex 0x00777777


neutral40 : E.Color
neutral40 =
    hex 0x005E5E5E


neutral30 : E.Color
neutral30 =
    hex 0x00464646


neutral20 : E.Color
neutral20 =
    hex 0x002E2E2E


neutral10 : E.Color
neutral10 =
    hex 0x00161616


black : E.Color
black =
    hex 0x00


transactionColor : Bool -> E.Color
transactionColor isExpense =
    if isExpense then
        expense40

    else
        income40


expense40 : E.Color
expense40 =
    -- E.rgb 0.64 0.12 0.00
    -- hex 0xA31F00
    hex 0x00B30009


expense50 : E.Color
expense50 =
    hex 0x00E0000F


expense30 : E.Color
expense30 =
    hex 0x00880005


expense90 : E.Color
expense90 =
    -- E.rgb 0.94 0.87 0.87
    -- hex 0xF0DEDE
    hex 0x00F4DCD8


expense95 : E.Color
expense95 =
    -- E.rgb 1 0.96 0.96
    hex 0x00FAEEEC


expense80 : E.Color
expense80 =
    -- E.rgb 0.8 0.6 0.6
    -- hex 0xCC9999
    hex 0x00E9BAB3


income40 : E.Color
income40 =
    -- E.rgb 0.1 0.44 0
    -- hex 0x1A7000
    -- hex 0x006F53
    hex 0x000D7200


income50 : E.Color
income50 =
    hex 0x00139000


income30 : E.Color
income30 =
    hex 0x00075600


income90 : E.Color
income90 =
    -- E.rgb 0.92 0.94 0.86
    hex 0x00DAE7D8


income95 : E.Color
income95 =
    -- E.rgb 0.98 1 0.96
    hex 0x00ECF3EB


income80 : E.Color
income80 =
    -- E.rgb 0.7 0.8 0.6
    hex 0x00B7CFB4


primary95 : E.Color
primary95 =
    hex 0x00E8F2FC


primary90 : E.Color
primary90 =
    hex 0x00D2E5FA


primary80 : E.Color
primary80 =
    hex 0x00BBD8F6


primary50 : E.Color
primary50 =
    -- E.rgb 0.18 0.52 0.66
    -- hex 0x007DC2
    -- hex 0x387BBB
    hex 0x00387BBB


primary40 : E.Color
primary40 =
    -- E.rgb 0.08 0.26 0.42
    -- hex 0x14426b
    -- hex 0x00639B
    -- hex 0x1B4873
    hex 0x00286197


primary30 : E.Color
primary30 =
    -- E.rgb 0.08 0.19 0.3
    -- hex 0x004A75
    hex 0x001B4873
