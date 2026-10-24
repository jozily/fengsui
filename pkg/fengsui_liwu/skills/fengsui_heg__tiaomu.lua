local tiaomu = fk.CreateSkill { name = "fengsui_heg__tiaomu" }
local target_mark = "@fengsui_heg__tiaomu"

tiaomu:addEffect(fk.TargetConfirmed, {
  anim_type = "support",
  can_trigger = function(self, _, target, player, data)
    return target == player and player:hasShownSkill(tiaomu.name) and data.use and data.from and
      #data.use.tos > 1 and not data.from:inMyAttackRange(player)
  end,
  on_cost = function(self, event, _, player)
    if player.room:askToSkillInvoke(player, { skill_name = tiaomu.name,
        prompt = "#fengsui_heg__tiaomu-invoke" }) then return true end
  end,
  on_use = function(self, _, target, player, data)
    local room = player.room
    room:drawCards(data.from, 1, tiaomu.name)
    data:setNullified(player)
    room:setPlayerMark(data.from, target_mark, 1)
  end,
})

return tiaomu
