local H = require "packages.fengsui.hegemony_util"

local zeyu = fk.CreateSkill {
  name = "fengsui_heg__zeyu",
  tags = { Skill.MainPlace },
}

zeyu:addEffect(H.KillRewardExecuting, {
  can_trigger = function(self, _, target, player, data)
    local victim, killer = data and data.victim, data and data.killer
    return target == killer and killer and killer:isAlive() and not data.replaced and victim and
      player:hasShownSkill(zeyu.name) and H.compareKingdomWith(killer, player) and
      not H.compareKingdomWith(killer, victim)
  end,
  on_cost = function(self, _, target, player)
    return player.room:askToSkillInvoke(player, {
      skill_name = zeyu.name, prompt = "#fengsui_heg__zeyu-invoke::" .. target.id,
    })
  end,
  on_use = function(self, _, target)
    if target:isAlive() and H.hasGeneral(target, true) then
      H.transformGeneral(target.room, target, false, false, 1, zeyu.name)
    end
  end,
})

return zeyu
