local H = require "packages.fengsui.hegemony_util"
local buge = fk.CreateSkill { name = "fengsui_heg__buge" }
local function gain(player)
  local marks = { "yinyangfish", "yinyangfish", "yinyangfish", "yinyangfish", "yinyangfish", "vanguard", "companion", "fengsui_heg_ascend", "fengsui_heg__descend", "fengsui_heg__descend" }
  H.addHegMark(player, marks[math.random(#marks)])
end
buge:addEffect(fk.Damaged, {
  can_trigger = function(self, _, target, player) return target == player and player:hasShownSkill(self.name) end,
  on_cost = function(self, _, _, player) return player.room:askToSkillInvoke(player, { skill_name = self.name }) end,
  on_use = function(self, _, _, player) gain(player) end,
})
buge:addEffect(fk.GeneralRevealed, {
  can_trigger = function(self, _, target, player, data)
    if target ~= player then return false end
    local shown = data and (data.m or data.d)
    if not shown then return false end
    local g = Fk.generals[shown]
    return g and table.contains(g:getSkillNameList(true), self.name) or false
  end,
  on_cost = function(self, _, _, player)
    return player.room:askToSkillInvoke(player, { skill_name = self.name })
  end,
  on_use = function(self, _, _, player)
    gain(player)
  end,
})
return buge
