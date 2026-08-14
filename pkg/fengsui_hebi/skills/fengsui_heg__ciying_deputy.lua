local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"
local CardNameUI = require "packages.fengsui.pkg.card_name_ui"

local ciying = fk.CreateSkill{
  name = "fengsui_heg__ciying_deputy",
  tags = { Skill.DeputyPlace },
}

local function names()
  return U.getNationalCardNames({ "basic", "trick" })
end

ciying:addEffect("viewas", {
  pattern = ".",
  prompt = "#fengsui_heg__ciying-active",
  interaction = function(self, player)
    local all = names()
    local available = player:getViewAsCardNames(ciying.name, all)
    return CardNameUI.create(ciying.name, available, all)
  end,
  filter_pattern = { min_num = 0, max_num = 0, pattern = "", subcards = {} },
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

local function used(data)
  return data.card and table.contains(data.card.skillNames, ciying.name)
end

local finishSpec = {
  anim_type = "support",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and used(data)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local current = room.current
  local count = player:getMark("fengsui_heg__ciying_times") + 1
  room:setPlayerMark(player, "fengsui_heg__ciying_times", count)
    local choices = {}
    if current and current:isAlive() and #player:getCardIds("he") >= count then
      table.insert(choices, "fengsui_heg__ciying_give")
    end
    if H.hasGeneral(player, true) and #(room.general_pile or room.generalPile or {}) > 0 then
      table.insert(choices, "fengsui_heg__ciying_transform")
    end
    if #choices == 0 then return end
    local choice = #choices == 1 and choices[1] or room:askToChoice(player, {
      choices = choices,
      skill_name = ciying.name,
      prompt = "#fengsui_heg__ciying-choice:::" .. count,
    })
    if choice == "fengsui_heg__ciying_give" then
      local cards = U.chooseCardsFromList(room, player, player:getCardIds("he"), count, count,
        "#fengsui_heg__ciying-give:::" .. count, ciying.name, false)
      room:moveCardTo(cards, Card.PlayerHand, current, fk.ReasonGive, ciying.name, nil, false, player)
    else
      if H.transformGeneral(room, player, false, false, 3, ciying.name) then
        room:handleAddLoseSkills(player, "-" .. ciying.name, nil, false, true)
      end
    end
  end,
}

ciying:addEffect(fk.CardUseFinished, finishSpec)

ciying:addEffect(fk.CardRespondFinished, finishSpec)

return ciying
