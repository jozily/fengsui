local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"
local yaoming = fk.CreateSkill { name = "fengsui_heg__yaoming", tags = { Skill.DeputyPlace } }
yaoming:addEffect(fk.TargetSpecified, {
  can_trigger = function(self, _, target, player, data)
    return player:hasShownSkill(self.name) and U.getSkillPlace(player, self.name) == true and data and data.from and
      H.compareKingdomWith(player, data.from) and data.card and data.to and not H.compareKingdomWith(player, data.to) and
      (not data.use or #data.use.tos == 1)
  end,
  on_cost = function(self, event, _, player, data)
    local candidates = table.filter(data:getExtraTargets(), function(p) return data.from:canUseTo(data.card, p) end)
    if #candidates == 0 then return false end
    local chosen = player.room:askToChoosePlayers(player, { targets = candidates, min_num = 1, max_num = 1,
      skill_name = self.name, prompt = "#fengsui_heg__yaoming-add", cancelable = true })
    if chosen[1] then event:setCostData(self, chosen[1]); return true end
  end,
  on_use = function(self, event, _, player, data)
    player.room:setPlayerMark(player, "fengsui_heg__chuguang_target-round", data.from.id)
    player.room:addPlayerMark(player, "fengsui_heg__chuguang_count-round", 1)
    U.swapGenerals(player.room, player)
    data:addTarget(event:getCostData(self))
  end,
})
return yaoming
