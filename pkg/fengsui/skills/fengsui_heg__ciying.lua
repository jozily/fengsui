local H = require "packages.hegemony.util"
local U = require "packages.hegemony.pkg.fengsui.util"

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
    if #names == 0 then return end
    return UI.CardNameBox { choices = names, all_choices = all_names }
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
  local choices = { "fengsui_heg__ciying_draw" }
  if current and current:isAlive() and #player:getCardIds("he") >= count then
    table.insert(choices, 1, "fengsui_heg__ciying_give")
  end
  local choice = room:askToChoice(player, {
    choices = choices,
    skill_name = ciying.name,
    prompt = "#fengsui_heg__ciying-choice:::" .. count,
  })
  if choice == "fengsui_heg__ciying_give" then
    local cards = U.chooseCardsFromList(room, player, player:getCardIds("he"), count, count,
      "#fengsui_heg__ciying-give:::" .. count, ciying.name, false)
    room:moveCardTo(cards, Card.PlayerHand, current, fk.ReasonGive, ciying.name, nil, false, player)
  else
    player:drawCards(count, ciying.name)
    local place = U.getSkillPlace(player, ciying.name)
    if place ~= nil then H.removeGeneral(player, place) end
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
