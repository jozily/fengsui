local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local kangying = fk.CreateSkill{
  name = "fengsui_heg__kangying",
}

kangying:addEffect(fk.Damage, {
  global = true,
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target and target ~= player and target:isAlive() and player:isAlive() and
      player:hasSkill(kangying.name) and H.compareKingdomWith(target, player)
  end,
  on_cost = function(self, event, target, player, data)
    return target.room:askToSkillInvoke(target, {
      skill_name = kangying.name,
      prompt = "#fengsui_heg__kangying-invoke::" .. player.id,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    H.swapDeputy(room, target, player)
    local owner = table.find(room.alive_players, function(p)
      return U.hasGeneralName(p, "fengsui_heg__zuti")
    end)
    if owner then
      room:addPlayerMark(owner, "fengsui_heg__kangying_range-turn", 1)
      room:addPlayerMark(owner, "fengsui_heg__kangying_damage", 1)
    end
  end,
})

kangying:addEffect("atkrange", {
  global = true,
  correct_func = function(self, from, to)
    return from:getMark("fengsui_heg__kangying_range-turn")
  end,
})

kangying:addEffect(fk.DamageCaused, {
  global = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("fengsui_heg__kangying_damage") > 0
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
    player.room:removePlayerMark(player, "fengsui_heg__kangying_damage")
  end,
})

return kangying
