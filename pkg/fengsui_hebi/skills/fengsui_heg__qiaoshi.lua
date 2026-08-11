local H = require "packages.fengsui.hegemony_util"

local qiaoshi = fk.CreateSkill{
  name = "fengsui_heg__qiaoshi",
}

qiaoshi:addEffect(fk.Damaged, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(qiaoshi.name) and data.damageType ~= fk.NormalDamage
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = qiaoshi.name,
      prompt = "#fengsui_heg__qiaoshi-invoke::" .. target.id,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(1, qiaoshi.name)
    if target:isAlive() then target:drawCards(1, qiaoshi.name) end
    if player:isAlive() and target:isAlive() and H.compareKingdomWith(target, player) and
      room:askToSkillInvoke(player, {
        skill_name = qiaoshi.name,
        prompt = "#fengsui_heg__qiaoshi-change::" .. target.id,
      }) then
      H.askToHebiOrTransform(room, target, qiaoshi.name, false)
    end
  end,
})

return qiaoshi
