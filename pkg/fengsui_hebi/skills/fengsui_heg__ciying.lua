-- 辞映（李密）
-- 当你于回合外需要使用或打出一张基本牌或普通锦囊牌时，若当前回合角色未确定势力
-- 或为大势力，你可以视为使用或打出之并交给其X张牌（X为本局游戏此技能发动次数）。
local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"
local CardNameUI = require "packages.fengsui.pkg.card_name_ui"

local ciying = fk.CreateSkill{
  name = "fengsui_heg__ciying",
}

local function allCardNames()
  return U.getNationalCardNames({"basic", "trick"})
end

ciying:addEffect("viewas", {
  pattern = ".",
  prompt = "#fengsui_heg__ciying-active",
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
  local count = player:getMark("fengsui_heg__ciying_times") + 1
  room:setPlayerMark(player, "fengsui_heg__ciying_times", count)
  if not current or current.dead or current == player then return end
  if #player:getCardIds("he") < count then return end
  local cards = U.chooseCardsFromList(room, player, player:getCardIds("he"), count, count,
    "#fengsui_heg__ciying-give:::" .. count, ciying.name, false)
  room:moveCardTo(cards, Card.PlayerHand, current, fk.ReasonGive, ciying.name, nil, false, player)
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
