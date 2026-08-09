local H = require "packages.fengsui.hegemony_util"

local lixi = fk.CreateSkill{
  name = "fengsui_heg__lixi",
  tags = { Skill.Compulsory },
}

lixi:addEffect(fk.EnterDying, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(lixi.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.players) do
      room:setPlayerMark(p, "fengsui_heg__lixi-invalid-turn", 1)
    end
    room:sendLog{type = "#fengsui_heg__lixi-invalid", toast = true}
  end,
})

lixi:addEffect("invalidity", {
  global = true,
  invalidity_func = function(self, from, skill)
    return from:getMark("fengsui_heg__lixi-invalid-turn") > 0 and
      not skill:hasTag(Skill.Compulsory) and skill:isPlayerSkill(from)
  end,
})
return lixi
