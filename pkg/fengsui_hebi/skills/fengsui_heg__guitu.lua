local H = require "packages.fengsui.hegemony_util"

local guitu = fk.CreateSkill{
  name = "fengsui_heg__guitu",
}

guitu:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(guitu.name) and
      data.damage > 1 and H.hasGeneral(player, true)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = guitu.name,
      prompt = "#fengsui_heg__guitu-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    H.removeGeneral(player, true)
    data:preventDamage()
    if data.from and data.from:isAlive() then
      player.room:setPlayerMark(data.from, "@fengsui_heg__guitu-turn", 1)
      player.room:addTableMarkIfNeed(player, "@fengsui_heg__guitu_targets-turn", data.from.id)
    end
  end,
})

guitu:addEffect("maxcards", {
  global = true,
  fixed_func = function(self, player)
    if player:getMark("@fengsui_heg__guitu-turn") > 0 then return 0 end
  end,
})

return guitu
