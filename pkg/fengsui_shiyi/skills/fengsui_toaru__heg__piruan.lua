-- 疲软（食蜂操祈）
-- 锁定技，当你成为锦囊牌的目标后，你选择一项：
-- 1. 若你的武将牌均明置，你暗置此武将牌；
-- 2. 重铸一个区域所有牌。
local H = require "packages.fengsui.hegemony_util"

local piruan = fk.CreateSkill{
  name = "fengsui_toaru__heg__piruan",
  tags = { Skill.Compulsory },
}

local HIDE = "fengsui_toaru__heg__piruan_hide"
local RECAST = "fengsui_toaru__heg__piruan_recast"

-- 区域与选项译名一一对应，选择区域时按这里的键发问。
local AREA_KEY = {
  h = "fengsui_toaru__heg__piruan_hand",
  e = "fengsui_toaru__heg__piruan_equip",
  j = "fengsui_toaru__heg__piruan_judge",
}
local AREA_OF = {
  [AREA_KEY.h] = "h",
  [AREA_KEY.e] = "e",
  [AREA_KEY.j] = "j",
}

Fk:loadTranslationTable{
  ["fengsui_toaru__heg__piruan"] = "疲软",
  [":fengsui_toaru__heg__piruan"] =
    "锁定技，当你成为锦囊牌的目标后，你选择一项：1.若你的武将牌均明置，你暗置此武将牌；2.重铸一个区域所有牌。",
  [HIDE] = "暗置此武将牌",
  [RECAST] = "重铸一个区域所有牌",
  [AREA_KEY.h] = "手牌区",
  [AREA_KEY.e] = "装备区",
  [AREA_KEY.j] = "判定区",
}

-- 有牌可重铸的区域
local function nonEmptyAreas(player)
  local areas = {}
  for _, area in ipairs({ "h", "e", "j" }) do
    if #player:getCardIds(area) > 0 then table.insert(areas, area) end
  end
  return areas
end

piruan:addEffect(fk.TargetConfirmed, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasShownSkill(self.name) then return false end
    if not data.card or data.card.type ~= Card.TypeTrick then return false end
    -- 两个选项至少要有一个能落实，否则这次照面不作结算。
    return H.allGeneralsRevealed(player) or #nonEmptyAreas(player) > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local canHide = H.allGeneralsRevealed(player)
    local areas = nonEmptyAreas(player)

    local choices, all_choices = {}, {}
    if canHide then
      table.insert(choices, HIDE)
      table.insert(all_choices, HIDE)
    end
    if #areas > 0 then
      table.insert(choices, RECAST)
      table.insert(all_choices, RECAST)
    end
    if #choices == 0 then return end

    -- 锁定技不给「发动与否」的询问，直接进选项；只剩一项时不必弹框。
    -- all_choices 传全量，不可选的项在界面上灰掉而不是消失。
    local choice = choices[1]
    if #choices > 1 then
      choice = room:askToChoice(player, {
        choices = choices,
        all_choices = all_choices,
        skill_name = piruan.name,
      })
    end

    if choice == HIDE then
      -- 暗置技能所在的武将牌；技能若不在武将技能里（额外获得），退回暗置主将。
      if not H.hideBySkillName(player, piruan.name) then
        if H.allGeneralsRevealed(player) then player:hideGeneral(false) end
      end
      return
    end

    local area = areas[1]
    if #areas > 1 then
      local keys = {}
      for _, a in ipairs(areas) do table.insert(keys, AREA_KEY[a]) end
      area = AREA_OF[room:askToChoice(player, { choices = keys, skill_name = piruan.name })] or areas[1]
    end
    local ids = player:getCardIds(area)
    if #ids > 0 then
      room:recastCard(ids, player, piruan.name)
    end
  end,
})

return piruan
