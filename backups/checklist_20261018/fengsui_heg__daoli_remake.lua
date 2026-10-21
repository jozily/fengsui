local H = require "packages.fengsui.hegemony_util"
local D = require "packages.fengsui.pkg.fengsui_hebi.daoli_util"
local daoli = fk.CreateSkill {
  name = "fengsui_heg__daoli",
  tags = {Skill.Limited},
}

daoli:addEffect(fk.Death, {
  global = true,
  can_trigger = function(self, _, target, player)
    return target and target ~= player and player:hasShownSkill(self.name) and
      H.compareKingdomWith(player, target) and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, _, _, player)
    return player.room:askToSkillInvoke(player, {
      skill_name = self.name, prompt = "#fengsui_heg__daoli-invoke",
    })
  end,
  on_use = function(self, _, target, player)
    D.prepare(player.room, player, target)
  end,
})

return daoli