local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"
local jiaosu = fk.CreateSkill { name = "fengsui_heg__jiaosu", tags = { Skill.MainPlace } }
jiaosu:addEffect(fk.TargetSpecified, {
  can_trigger = function(self, _, target, player, data)
    return player:hasShownSkill(self.name) and U.getSkillPlace(player, self.name) == false and data and data.from and
      data.from ~= player and not H.compareKingdomWith(player, data.from) and data.card and data.to and
      H.compareKingdomWith(player, data.to) and (not data.use or #data.use.tos == 1)
  end,
  on_cost = function(self, _, _, player, data)
    return player.room:askToSkillInvoke(player, { skill_name = self.name,
      prompt = "#fengsui_heg__jiaosu-invoke::" .. data.to.id })
  end,
  on_use = function(self, _, _, player, data)
    player.room:setPlayerMark(player, "fengsui_heg__chuguang_target-round", data.to.id)
    player.room:addPlayerMark(player, "fengsui_heg__chuguang_count-round", 1)
    U.swapGenerals(player.room, player)
    data:cancelTarget(data.to)
  end,
})
return jiaosu
