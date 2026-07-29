local H = require "packages.hegemony.util"
local U = require "packages.hegemony.pkg.fengsui.util"

local heci = fk.CreateSkill{
  name = "fengsui_heg__heci",
}

local entered_names_mark = "fengsui_heg__heci_entered_names-round"

local function getCostNum(player)
  local room = player.room or Fk:currentRoom()
  if not room then return 0 end
  local n = 0
  for _, p in ipairs(room.alive_players) do
    if H.compareKingdomWith(p, player) then
      n = n + H.getGeneralsRevealedNum(p)
    end
  end
  return n
end

local function getAvailableNames(player)
  local entered = player:getTableMark(entered_names_mark)
  local all_names = table.filter(U.getNationalCardNames({"trick"}), function(name)
    return not table.contains(entered, name)
  end)
  return player:getViewAsCardNames(heci.name, all_names), all_names
end

local function canUseHeci(player)
  local cost = getCostNum(player)
  local names = getAvailableNames(player)
  return cost > 0 and #player:getCardIds("he") >= cost and #names > 0 and
    player:usedSkillTimes(heci.name, Player.HistoryTurn) == 0
end

heci:addEffect(fk.AfterCardsMove, {
  global = true,
  mute = true,
  can_refresh = function(self, event, target, player, data)
    return table.find(data, function(move)
      return move.toArea == Card.DiscardPile and #move.moveInfo > 0
    end) ~= nil
  end,
  on_refresh = function(self, event, target, player, data)
    local names = player:getTableMark(entered_names_mark)
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          table.insertIfNeed(names, Fk:getCardById(info.cardId).name)
        end
      end
    end
    player.room:setPlayerMark(player, entered_names_mark, names)
  end,
})

heci:addEffect("viewas", {
  anim_type = "offensive",
  pattern = ".",
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
  include_equip = true,
  view_as = function(self, player, cards)
    if not self.interaction.data or #cards ~= getCostNum(player) then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = heci.name
    card:addSubcards(cards)
    return card
  end,
  enabled_at_play = function(self, player)
    return canUseHeci(player)
  end,
  enabled_at_response = function(self, player, response)
    return not response and canUseHeci(player)
  end,
  enabled_at_nullification = function(self, player, data)
    if not canUseHeci(player) then return false end
    local names = getAvailableNames(player)
    return table.contains(names, "nullification")
  end,
})

return heci
