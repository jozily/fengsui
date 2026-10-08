local H = require "packages.fengsui.hegemony_util"
local lishi = fk.CreateSkill { name = "fengsui_heg__lishi" }
lishi:addEffect(fk.AfterCardsMove, {
  global = true,
  can_trigger = function(self, _, target, player, data)
    return player:hasSkill(self.name) and target and target ~= player and H.compareKingdomWith(player, target)
      and data and table.find(data, function(m) return m.from == target and #m.moveInfo >= 2 end) ~= nil
      and player:getHandcardNum() < player.hp
  end,
  on_use = function(self, _, target, player)
    local room = player.room
    if not player:isNude() then
      local c = room:askToChooseCard(player, { target = player, flag = "he", skill_name = self.name })
      room:obtainCard(target, c, false, fk.ReasonGive, player, self.name)
    end
    local current = room.current
    if current and not current:isNude() then
      local c = room:askToChooseCard(player, { target = current, flag = "he", skill_name = self.name })
      room:throwCard(c, self.name, current, player)
    end
  end,
})
return lishi
