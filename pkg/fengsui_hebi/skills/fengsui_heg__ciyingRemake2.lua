-- 辞应 · 旧版二存档（不挂载任何武将，留作 Remake）
-- 旧效果：当你于回合外需要使用或打出一张基本牌或普通锦囊牌时，若当前回合角色
-- 未确定势力或为大势力，你可以视为使用或打出之并选择一项：1.交给其X张牌；
-- 2.变更副将，然后若此武将牌为主将，此技能变为副将技（X为本局游戏此技能发动次数）。
-- 注：旧的副将技变体文件 fengsui_heg__ciying_deputy.lua 已随本次修改一并删除。
local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"
local CardNameUI = require "packages.fengsui.pkg.card_name_ui"

local ciying = fk.CreateSkill{
  name = "fengsui_heg__ciyingRemake2",
}

local function allCardNames()
  return U.getNationalCardNames({"basic", "trick"})
end

ciying:addEffect("viewas", {
  pattern = ".",
  prompt = "#fengsui_heg__ciyingRemake2-active",
  interaction = function(self, player)
    local all_names = allCardNames()
    local names = player:getViewAsCardNames(ciying.name, all_names)
    return CardNameUI.create(ciying.name, names, all_names)
  end,
  filter_pattern = {
    min_num = 0,
    max_num = 0,
    pattern = "",
    subcards = {},
  },
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    if not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = ciying.name
    return card
  end,
  enabled_at_play = Util.FalseFunc,
  enabled_at_response = function(self, player, response)
    local room = Fk:currentRoom()
    local current = room and room.current
    return current and current ~= player and
      (current.kingdom == "unknown" or H.isBigKingdomPlayer(current))
  end,
})

local function usedCiying(player, data)
  return data.card and table.contains(data.card.skillNames, ciying.name)
end

local function resolveCiying(player)
  local room = player.room
  local current = room.current
  local count = player:getMark("fengsui_heg__ciyingRemake2_times") + 1
  room:setPlayerMark(player, "fengsui_heg__ciyingRemake2_times", count)
  local choices = {}
  if current and current:isAlive() and #player:getCardIds("he") >= count then
    table.insert(choices, "fengsui_heg__ciyingRemake2_give")
  end
  if H.hasGeneral(player, true) and #(room.general_pile or room.generalPile or {}) > 0 then
    table.insert(choices, "fengsui_heg__ciyingRemake2_transform")
  end
  if #choices == 0 then return end
  local choice = #choices == 1 and choices[1] or room:askToChoice(player, {
    choices = choices,
    skill_name = ciying.name,
    prompt = "#fengsui_heg__ciyingRemake2-choice:::" .. count,
  })
  if choice == "fengsui_heg__ciyingRemake2_give" then
    local cards = U.chooseCardsFromList(room, player, player:getCardIds("he"), count, count,
      "#fengsui_heg__ciyingRemake2-give:::" .. count, ciying.name, false)
    room:moveCardTo(cards, Card.PlayerHand, current, fk.ReasonGive, ciying.name, nil, false, player)
  else
    if H.transformGeneral(room, player, false, false, 3, ciying.name) then
      room:handleAddLoseSkills(player, "-" .. ciying.name, nil, false, true)
    end
  end
end

local finish_spec = {
  anim_type = "support",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and usedCiying(player, data)
  end,
  on_use = function(self, event, target, player, data)
    resolveCiying(player)
  end,
}

ciying:addEffect(fk.CardUseFinished, finish_spec)
ciying:addEffect(fk.CardRespondFinished, finish_spec)

return ciying
