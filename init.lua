Fk:loadTranslationTable{
  ["fengsui"] = "烽燧燎原",
  ["fengsui_hebi"] = "烽燧燎原-合璧",
  ["fengsui_liwu"] = "烽燧燎原-离骛",
  ["fengsui_cards"] ="<font color='red'>烽燧燎原卡牌</font>",
    ["fengsui_mode"] ="<font color='green'>燎原之战</font> ",


}

local fengsui_hebi = require "packages/fengsui/pkg/fengsui_hebi"
local fengsui_cards = require "packages/fengsui/pkg/fengsui_cards"
local fengsui_liwu = require "packages/fengsui/pkg/fengsui_liwu"
local fengsui_mode = require "packages/fengsui/pkg/fengsui_mode"


return {
  fengsui_hebi,
  fengsui_cards,
  fengsui_liwu,     
  fengsui_mode,
}
