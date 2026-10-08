local H = require "packages.fengsui.hegemony_util"
local juanyi = fk.CreateSkill { name = "fengsui_heg__juanyi" }
juanyi:addEffect(fk.AfterCardsMove, {
  global = true,
  can_trigger = function(self, _, target, player, data)
    return player:hasSkill(self.name) and target and target ~= player and H.compareKingdomWith(player, target)
      and data and table.find(data, function(m) return m.to == target and #m.moveInfo >= 2 end) ~= nil
  end,
  on_use = function(self, _, target, player)
    local room = player.room
    local candidates = table.filter(room.alive_players, function(x) return x ~= target end)
    local tos = room:askToChoosePlayers(target, { targets = candidates, min_num = 1, max_num = 1, skill_name = self.name, prompt = "#fengsui_heg__juanyi-target", cancelable = true })
    if #tos == 0 or target:isNude() then return end
    local c = room:askToChooseCard(target, { target = target, flag = "he", skill_name = self.name })
    room:obtainCard(tos[1], c, false, fk.ReasonGive, target, self.name)
    room:drawCards(player, 1, self.name)
  end,
})
return juanyi
