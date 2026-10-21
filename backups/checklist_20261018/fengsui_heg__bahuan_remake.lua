local H = require "packages.fengsui.hegemony_util"
local bahuan = fk.CreateSkill { name = "fengsui_heg__bahuan" }

bahuan:addEffect(fk.TurnStart, {
  can_trigger = function(self, _, target, player)
    return target == player and player:hasShownSkill(self.name)
  end,
  on_use = function(self, _, _, player)
    local room = player.room
    local kingdoms, targets = {}, {}
    for _, p in ipairs(room.alive_players) do
      local k = H.getKingdom(p)
      if k ~= "unknown" and not table.contains(kingdoms, k) then
        table.insert(kingdoms, k)
        local candidates = table.filter(room.alive_players, function(x) return H.getKingdom(x) == k and H.getGeneralsRevealedNum(x) <= H.getGeneralsRevealedNum(player) end)
        if #candidates > 0 then table.insert(targets, room:askToChoosePlayers(player, { targets = candidates, min_num = 1, max_num = 1, skill_name = self.name, prompt = "#fengsui_heg__bahuan-target", cancelable = false })[1]) end
      end
    end
    for _, target in ipairs(targets) do
      if target and target:isAlive() then
        room:damage { from = player, to = target, damage = 1, skillName = self.name }
        if not target.dead and not target:isNude() and room:askToSkillInvoke(target, { skill_name = self.name, prompt = "#fengsui_heg__bahuan-give" }) then
          local card = room:askToCards(target, { min_num = 1, max_num = 1, include_equip = true, skill_name = self.name, prompt = "#fengsui_heg__bahuan-give-card", cancelable = false })
          if #card > 0 then room:obtainCard(player, card, true, fk.ReasonGive, target, self.name); room:recover { who = target, num = 1, skillName = self.name } end
        end
      end
    end
  end,
})

return bahuan
