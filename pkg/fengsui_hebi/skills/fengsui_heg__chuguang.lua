local H = require "packages.fengsui.hegemony_util"
local chuguang = fk.CreateSkill { name = "fengsui_heg__chuguang", tags = { Skill.Compulsory } }
local disabledMark = "@fengsui_heg__chuguang_disabled-round"
local targetMark = "fengsui_heg__chuguang_target-round"
local function sameKingdomPlayers(player)
  return table.filter(player.room.alive_players, function(p) return H.compareKingdomWith(player, p) end)
end

chuguang:addEffect(fk.AfterSkillEffect, {
  global = true,
  can_trigger = function(self, _, target, player, data)
    local skillName = data and data.skill and data.skill:getSkeleton().name
    return target == player and player:hasShownSkill(self.name) and
      (skillName == "fengsui_heg__jiaosu" or skillName == "fengsui_heg__yaoming") and
      player:getMark("fengsui_heg__chuguang_count-round") > 0 and
      player:getMark(targetMark) ~= 0
  end,
  on_use = function(self, _, _, player, data)
    local room = player.room
    local x = player:getMark("fengsui_heg__chuguang_count-round")
    local kingdomCount = #sameKingdomPlayers(player)
    local target = table.find(room.alive_players, function(p) return p.id == player:getMark(targetMark) end)
    if target and target:isAlive() then room:drawCards(target, x, self.name) end
    if x == kingdomCount then room:setPlayerMark(player, disabledMark, "蓄势待发") end
    room:setPlayerMark(player, targetMark, 0)
  end,
})

chuguang:addEffect("invalidity", {
  global = true,
  invalidity_func = function(self, from, skill)
    return from and from:getMark(disabledMark) > 0 and
      (skill.name == "fengsui_heg__jiaosu" or skill.name == "fengsui_heg__yaoming")
  end,
})

chuguang:addEffect(fk.AfterDying, {
  global = true,
  can_trigger = function(self, _, target, player)
    return target and target:getMark("fengsui_heg__jiaosu_target") > 0 and player:hasShownSkill(self.name)
  end,
  on_use = function(self, _, target, player)
    local room = player.room
    room:setPlayerMark(target, "@fengsui_heg__jiaosu_target", 0)
    room:setPlayerMark(target, "fengsui_heg__jiaosu_target", 0)
    if target:isAlive() then
      target:reset()
      local turn = room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
      if turn then turn:addExitFunc(function()
        if target:isAlive() then target:gainAnExtraPhase(Player.Play, chuguang.name, false) end
      end) end
    end
  end,
})

chuguang:addEffect(fk.Death, {
  global = true,
  can_trigger = function(self, _, target, player)
    return target and target:getMark("fengsui_heg__yaoming_target") > 0 and player:hasShownSkill(self.name)
  end,
  on_use = function(self, _, target, player)
    local room = player.room
    room:setPlayerMark(target, "@fengsui_heg__yaoming_target", 0)
    room:setPlayerMark(target, "fengsui_heg__yaoming_target", 0)
    if player:isAlive() then
      room:loseHp(player, 1, chuguang.name)
      if player:isAlive() then H.transformGeneral(room, player, false, true, 1, chuguang.name) end
    end
  end,
})
return chuguang
