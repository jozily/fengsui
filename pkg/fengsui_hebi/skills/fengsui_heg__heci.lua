local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"
local CardNameUI = require "packages.fengsui.pkg.card_name_ui"

local heci = fk.CreateSkill{
  name = "fengsui_heg__heci",
}

local used_names_mark = "fengsui_heg__heci_used_names-round"

local function getCostNum(player)
  local room = player.room or Fk:currentRoom()
  if not room then return 0 end
  local n = 0
  for _, p in ipairs(room.alive_players) do
    if H.compareKingdomWith(p, player) then
      local general_num = p.deputyGeneral and p.deputyGeneral ~= "" and 2 or 1
      n = n + general_num - H.getGeneralsRevealedNum(p)
    end
  end
  return n
end

local function getAvailableNames(player)
  local used = {}
  local room = player.room or Fk:currentRoom()
  if room then
    for _, p in ipairs(room.players) do
      table.insertTableIfNeed(used, p:getTableMark(used_names_mark))
    end
  end
  local all_names = table.filter(U.getNationalCardNames({"trick"}), function(name)
    return not table.contains(used, name)
  end)
  return player:getViewAsCardNames(heci.name, all_names), all_names
end

local function canUseHeci(player)
  local cost = getCostNum(player)
  local names = getAvailableNames(player)
  return cost > 0 and #player:getCardIds("he") >= cost and #names > 0 and
    player:usedSkillTimes(heci.name, Player.HistoryTurn) == 0
end

heci:addEffect(fk.CardUsing, {
  global = true,
  mute = true,
  can_refresh = function(self, event, target, player, data)
    return data.card and data.card:isCommonTrick()
  end,
  on_refresh = function(self, event, target, player, data)
    target.room:addTableMarkIfNeed(target, used_names_mark, data.card.trueName)
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
    return CardNameUI.create(heci.name, names, all_names)
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
