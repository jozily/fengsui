local H = require "packages.fengsui.hegemony_util"
local CardNameUI = require "packages.fengsui.pkg.card_name_ui"

local liefa = fk.CreateSkill{
  name = "fengsui_heg__liefaRemake",
}

local basic_names = {"slash", "jink", "peach", "analeptic"}

liefa:addEffect("viewas", {
  pattern = ".",
  prompt = "#fengsui_heg__liefaRemake-invoke",
  interaction = function(self, player)
    local unused = table.filter(basic_names, function(name)
      return player:usedSkillTimes(liefa.name .. "_" .. name, Player.HistoryTurn) == 0
    end)
    local names = player:getViewAsCardNames(liefa.name, unused)
    return CardNameUI.create(liefa.name, names, basic_names)
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    if #cards > 0 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = liefa.name
    return card
  end,
  before_use = function(self, player, use)
    player:addSkillUseHistory(liefa.name .. "_" .. use.card.name)
  end,
  after_use = function(self, player, use)
    local room = player.room
    if table.contains(use.tos or {}, player) then
      local num = math.min(2, #player:getCardIds("he"))
      if num > 0 then
        room:askToDiscard(player, {
          min_num = num,
          max_num = num,
          include_equip = true,
          skill_name = liefa.name,
          prompt = "#fengsui_heg__liefaRemake-discard:::" .. num,
          cancelable = false,
        })
      end
    elseif player:isAlive() then
      room:loseHp(player, 1, liefa.name)
    end

    local current = room.current
    if current and current:isAlive() and H.compareKingdomWith(current, player) then
      current:drawCards(1, liefa.name)
    end
  end,
  enabled_at_play = function(self, player)
    return table.find(basic_names, function(name)
      return player:usedSkillTimes(liefa.name .. "_" .. name, Player.HistoryTurn) == 0
    end) ~= nil
  end,
  enabled_at_response = function(self, player, response)
    return not response and table.find(basic_names, function(name)
      return player:usedSkillTimes(liefa.name .. "_" .. name, Player.HistoryTurn) == 0
    end) ~= nil
  end,
})

return liefa
