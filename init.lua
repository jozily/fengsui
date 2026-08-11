local hegemonyPackages = require "packages/hegemony"

Fk:loadTranslationTable{
  ["fengsui"] = "烽燧燎原",
  ["fengsui_hebi"] = "烽燧燎原-合璧",
  ["fengsui_liwu"] = "烽燧燎原-离骛",
  ["fengsui_card"] = "烽燧燎原-卡牌",
  ["fengsui_effect"] = "烽燧燎原-特效",
}

require "packages/fengsui/pkg/compat"

local fengsui_hebi = require "packages/fengsui/pkg/fengsui_hebi"
local fengsui_liwu = require "packages/fengsui/pkg/fengsui_liwu"
local fengsui_card = require "packages/fengsui/pkg/fengsui_card"
local fengsui_effect = require "packages/fengsui/pkg/fengsui_effect"
require("packages/fengsui/pkg/audio_overlay")(hegemonyPackages)

return {
  fengsui_hebi,
  fengsui_liwu,
  fengsui_card,
  fengsui_effect,
}
