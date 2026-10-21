local H = require "packages.fengsui.hegemony_util"
local buge = fk.CreateSkill { name = "fengsui_heg__buge" }
local function skillPlace(player)
  for _, isDeputy in ipairs({ false, true }) do
    local general = Fk.generals[H.getActualGeneral(player, isDeputy)]
    if general and table.contains(general:getSkillNameList(true), buge.name) then
      return isDeputy and "d" or "m"
    end
  end
end
local function gain(player)
  local marks = { "yinyangfish", "yinyangfish", "yinyangfish", "yinyangfish", "yinyangfish", "vanguard", "companion", "fengsui_heg_ascend", "fengsui_heg__descend", "fengsui_heg__descend" }
  H.addHegMark(player, marks[math.random(#marks)])
end
buge:addEffect(fk.Damaged, {
  can_trigger = function(self, _, target, player) return target == player and player:hasSkill(self.name, true, true) end,
  on_cost = function(self, _, _, player) return player.room:askToSkillInvoke(player, { skill_name = self.name }) end,
  on_use = function(self, _, _, player) gain(player) end,
})
buge:addEffect(fk.GeneralRevealed, {
  global = true,
  can_trigger = function(self, _, target, player, data)
    if target ~= player then return false end
    if not data or (not data.m and not data.d) or not player:hasSkill(self.name, true, true) then
      return false
    end
    -- GeneralRevealed 可能同时带有 m/d；只在承载“不隔”的那张武将牌
    -- 被明置时触发，避免把“明置另一张武将牌”误当成此技能时机。
    local place = skillPlace(player)
    return (place == "m" and data.m ~= nil) or (place == "d" and data.d ~= nil)
  end,
  on_cost = function(self, _, _, player)
    return player.room:askToSkillInvoke(player, { skill_name = self.name })
  end,
  on_use = function(self, _, _, player)
    gain(player)
  end,
})
return buge
