local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local mingding = fk.CreateSkill {
  name = "fengsui_heg__mingding",
  tags = { Skill.Limited },
}

-- 相谶技能在目标的下一个结束阶段就会被回收，xiangchen_mark 也随之归零。
-- 命定要求的是“因相谶获得过技能”，判定依据应当是获得记录，而不是当前是否仍持有。
local function gainedByXiangchen(target)
  return #target:getTableMark("fengsui_heg__xiangchen_history_skills") > 0
end

mingding:addEffect(fk.EnterDying, {
  can_trigger = function(self, _, target, player)
    return target and player:hasShownSkill(self.name) and
      player:getMark("fengsui_heg__mingding_used") == 0 and
      H.compareKingdomWith(player, target) and
      gainedByXiangchen(target) and
      H.hasGeneral(target, true)
  end,
  on_use = function(self, _, target, player)
    local room = player.room
    room:setPlayerMark(player, "fengsui_heg__mingding_used", 1)

    -- 先记下相谶技能，再移除副将；副将上的相谶技能会随之消失，
    -- 需要在移除后重新作为永久技能加入。若技能已被结束阶段回收，
    -- 则按描述从获得记录中随机取一个。
    local held = target:getTableMark("fengsui_heg__xiangchen_skills")
    local history = target:getTableMark("fengsui_heg__xiangchen_history_skills")
    local keep = held
    if #keep == 0 then
      local fresh = table.filter(history, function(skill_name)
        return Fk.skills[skill_name] and not target:hasSkill(skill_name, true, true)
      end)
      if #fresh > 0 then keep = { fresh[math.random(#fresh)] } end
    end

    U.removeGeneralByName(target, H.getActualGeneral(target, true))
    room:recover {
      who = target,
      num = math.max(0, 1 - target.hp),
      recoverBy = player,
      skillName = self.name,
    }

    -- 技能已转为永久，清空临时表，避免后续的相谶清理把它们一并移除。
    target:setMark("fengsui_heg__xiangchen_skills", {})
    for _, skill_name in ipairs(keep) do
      if Fk.skills[skill_name] and not target:hasSkill(skill_name, true, true) then
        room:handleAddLoseSkills(target, skill_name)
      end
    end
  end,
})

return mingding
