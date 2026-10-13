local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local mingding = fk.CreateSkill {
  name = "fengsui_heg__mingding",
  tags = { Skill.Limited },
}

mingding:addEffect(fk.EnterDying, {
  can_trigger = function(self, _, target, player)
    return target and player:hasShownSkill(self.name) and
      player:getMark("fengsui_heg__mingding_used") == 0 and
      H.compareKingdomWith(player, target) and
      target:getMark("fengsui_heg__xiangchen_mark") > 0 and
      H.hasGeneral(target, true)
  end,
  on_use = function(self, _, target, player)
    local room = player.room
    room:setPlayerMark(player, "fengsui_heg__mingding_used", 1)

    -- 命定检查并移除的是曾因“相谶”获得技能的角色的副将。
    U.removeGeneralByName(target, H.getActualGeneral(target, true))
    room:recover {
      who = target,
      num = math.max(0, 1 - target.hp),
      recoverBy = player,
      skillName = self.name,
    }

    local pool = target:getTableMark("fengsui_heg__xiangchen_skills")
    if #pool > 0 then
      local choices = table.filter(pool, function(skill_name)
        return Fk.skills[skill_name] and not target:hasSkill(skill_name, true, true)
      end)
      if #choices > 0 then
        room:handleAddLoseSkills(target, choices[math.random(#choices)])
      end
    end
  end,
})

return mingding
