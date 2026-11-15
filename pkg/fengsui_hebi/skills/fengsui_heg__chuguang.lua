local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"
local chuguang = fk.CreateSkill { name = "fengsui_heg__chuguang", tags = { Skill.Compulsory } }
local countMark = "fengsui_heg__chuguang_count-round"
local targetMark = "fengsui_heg__chuguang_target-round"
-- 可见 mark 显示「N/M」；失效状态另存不可见 mark，避免字符串参与数值比较。
local invalidMark = U.chuguangInvalidMark

chuguang:addEffect(fk.AfterSkillEffect, {
  global = true,
  can_trigger = function(self, _, target, player, data)
    local skillName = data and data.skill and data.skill:getSkeleton().name
    return target == player and player:isAlive() and player:hasShownSkill(self.name) and
      (skillName == "fengsui_heg__jiaosu" or skillName == "fengsui_heg__yaoming") and
      player:getMark(countMark) > 0 and player:getMark(targetMark) ~= 0
  end,
  on_use = function(self, _, _, player, data)
    local room = player.room
    local x = player:getMark(countMark)
    local target = table.find(room.alive_players, function(p) return p.id == player:getMark(targetMark) end)
    if target and target:isAlive() then room:drawCards(target, x, self.name) end
    -- 每次发动皎宿／曜暝后立刻刷新「次数/失效边界」，并据此判定本轮是否失效。
    U.refreshChuguangMark(player)
    room:setPlayerMark(player, targetMark, 0)
  end,
})

chuguang:addEffect("invalidity", {
  global = true,
  invalidity_func = function(self, from, skill)
    return from and skill and from:getMark(invalidMark) > 0 and
      (skill.name == "fengsui_heg__jiaosu" or skill.name == "fengsui_heg__yaoming")
  end,
})

-- 同势力角色数会随明置、变更武将、阵亡变化，失效边界 M 要跟着更新。
local refreshCount = {
  global = true,
  mute = true,
  can_refresh = function(self, _, _, player)
    return player:getMark(countMark) > 0
  end,
  on_refresh = function(self, _, _, player)
    U.refreshChuguangMark(player)
  end,
}
chuguang:addEffect(fk.GeneralRevealed, refreshCount)
chuguang:addEffect(H.GeneralTransformed, refreshCount)
chuguang:addEffect(fk.Deathed, refreshCount)
chuguang:addEffect(fk.TurnStart, refreshCount)
chuguang:addEffect(fk.RoundStart, refreshCount)

chuguang:addEffect(fk.AfterDying, {
  global = true,
  can_trigger = function(self, _, target, player)
    return target and target:isAlive() and player:isAlive() and target:getMark("fengsui_heg__jiaosu_target") > 0 and player:hasShownSkill(self.name)
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
    return target and player:isAlive() and target:getMark("fengsui_heg__yaoming_target") > 0 and player:hasShownSkill(self.name)
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
