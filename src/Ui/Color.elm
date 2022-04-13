module Ui.Color exposing (bgApajh, black, blueApajh, expense30, expense40, expense50, expense80, expense90, expense95, fgApajh, focus85, greenApajh, greenApajh90, income30, income40, income50, income80, income90, income95, neutral10, neutral20, neutral30, neutral40, neutral50, neutral60, neutral70, neutral80, neutral90, neutral93, neutral95, neutral98, primary30, primary40, primary50, primary80, primary85, primary90, primary95, redApajh, transactionColor, transparent, warning50, warning60, warning70, white)

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
    hex 0x00FFD000


white : E.Color
white =
    E.rgb 1.0 1.0 1.0


neutral98 : E.Color
neutral98 =
    hex 0x00F9F9F9


neutral95 : E.Color
neutral95 =
    hex 0x00F1F1F1


neutral93 : E.Color
neutral93 =
    hex 0x00EBEBEB


neutral90 : E.Color
neutral90 =
    hex 0x00E2E2E2


neutral80 : E.Color
neutral80 =
    hex 0x00C7C7C7


neutral70 : E.Color
neutral70 =
    hex 0x00ABABAB


neutral60 : E.Color
neutral60 =
    hex 0x00919191


neutral50 : E.Color
neutral50 =
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
    hex 0x00B30009


expense50 : E.Color
expense50 =
    hex 0x00E0000F


expense30 : E.Color
expense30 =
    hex 0x00880005


expense90 : E.Color
expense90 =
    hex 0x00F4DCD8


expense95 : E.Color
expense95 =
    hex 0x00FAEEEC


expense80 : E.Color
expense80 =
    hex 0x00E9BAB3


income40 : E.Color
income40 =
    hex 0x000D7200


income50 : E.Color
income50 =
    hex 0x00139000


income30 : E.Color
income30 =
    hex 0x00075600


income90 : E.Color
income90 =
    hex 0x00DAE7D8


income95 : E.Color
income95 =
    hex 0x00ECF3EB


income80 : E.Color
income80 =
    hex 0x00B7CFB4


primary95 : E.Color
primary95 =
    hex 0x00DCEDFF


primary90 : E.Color
primary90 =
    -- hex 0x00E8F2FC
    hex 0x00D4E5F7


primary85 : E.Color
primary85 =
    -- hex 0x00D2E5FA
    hex 0x00BED8F3


primary80 : E.Color
primary80 =
    -- hex 0x00BBD8F6
    hex 0x00A8CBEE


primary50 : E.Color
primary50 =
    hex 0x00387BBB


primary40 : E.Color
primary40 =
    hex 0x00286197


primary30 : E.Color
primary30 =
    hex 0x001B4873


greenApajh : E.Color
greenApajh =
    hex 0x00536C18


greenApajh90 : E.Color
greenApajh90 =
    hex 0x00DCE8C8


redApajh : E.Color
redApajh =
    hex 0x0085144B


blueApajh : E.Color
blueApajh =
    hex 0x00011F3F


bgApajh : E.Color
bgApajh =
    hex 0x00FCFAF8


fgApajh : E.Color
fgApajh =
    hex 0x00212529
