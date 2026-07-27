local H = require "packages.hegemony.util"

local heci = fk.CreateSkill{
  name = "fengsui_heg__heci",
}

local function getCostNum(player)
  local n = 0
  for _, p in ipairs(player.room.alive_players) do
    if H.compareKingdomWith(p, player) then
      n = n + H.getGeneralsRevealedNum(p)
    end
  end
  return n
end

local function getAvailableNames(player)
  local entered = {}
  player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(event)
    for _, move in ipairs(event.data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          entered[Fk:getCardById(info.cardId).name] = true
        end
      end
    end
  end, Player.HistoryRound)

  local all_names = table.filter(Fk:getAllCardNames("t"), function(name)
    return Fk:cloneCard(name):isCommonTrick() and not entered[name]
  end)
  return player:getViewAsCardNames(heci.name, all_names), all_names
end

heci:addEffect("viewas", {
  anim_type = "offensive",
  prompt = function(self, player)
    return "#fengsui_heg__heci-active:::" .. getCostNum(player)
  end,
  interaction = function(self, player)
    local names, all_names = getAvailableNames(player)
    if #names > 0 then
      return UI.CardNameBox { choices = names, all_choices = all_names }
    end
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected < getCostNum(player)
  end,
  view_as = function(self, player, cards)
    if not self.interaction.data or #cards ~= getCostNum(player) then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = heci.name
    card:addSubcards(cards)
    return card
  end,
  enabled_at_play = function(self, player)
    return getCostNum(player) > 0 and player:usedSkillTimes(heci.name, Player.HistoryTurn) == 0
  end,
})

return heci
