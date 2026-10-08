local H = require "packages.fengsui.hegemony_util"
local buge = fk.CreateSkill { name = "fengsui_heg__buge" }
local function gain(player)
  local marks = { "yinyangfish", "yinyangfish", "yinyangfish", "yinyangfish", "yinyangfish", "vanguard", "companion", "fengsui_heg_ascend", "fengsui_heg__descend", "fengsui_heg__descend" }
  H.addHegMark(player, marks[math.random(#marks)])
end
buge:addEffect(fk.Damaged, {
  can_trigger = function(self, _, target, player) return target == player and player:hasSkill(self.name) end,
  on_cost = function(self, _, _, player) return player.room:askToSkillInvoke(player, { skill_name = self.name }) end,
  on_use = function(self, _, _, player) gain(player) end,
})
return buge
