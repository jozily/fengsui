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

    -- 先记下相谶技能，再移除副将；副将上的相谶技能会随之消失，
    -- 需要在移除后重新作为永久技能加入。
    local pool = target:getTableMark("fengsui_heg__xiangchen_skills")
    local native = table.filter(pool, function(skill_name)
      return H.inGeneralSkills(target, skill_name) ~= nil
    end)
    U.removeGeneralByName(target, H.getActualGeneral(target, true))
    room:recover {
      who = target,
      num = math.max(0, 1 - target.hp),
      recoverBy = player,
      skillName = self.name,
    }

    local retained = #native > 0 and native or
      (#pool > 0 and { pool[math.random(#pool)] } or {})
    local remaining = table.filter(pool, function(skill_name)
      return not table.contains(retained, skill_name)
    end)
    target:setMark("fengsui_heg__xiangchen_skills", remaining)
    for _, skill_name in ipairs(retained) do
      if Fk.skills[skill_name] and not target:hasSkill(skill_name, true, true) then
        room:handleAddLoseSkills(target, skill_name)
      end
    end
  end,
})

return mingding
