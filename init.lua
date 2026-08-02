Fk:loadTranslationTable{
  ["fengsui"] = "烽燧燎原",
  ["fengsui_hebi"] = "烽燧燎原-合璧",
  ["fengsui_yili"] = "烽燧燎原-屹砺",
  ["fengsui_cards"] = "烽燧卡牌",
}

local fengsui_hebi = require "packages/fengsui/pkg/fengsui_hebi"
local fengsui_yili = require "packages/fengsui/pkg/fengsui_yili"
local fengsui_cards = require "packages/fengsui/pkg/fengsui_cards"

return {
  fengsui_hebi,
  fengsui_yili,
  fengsui_cards,
}
