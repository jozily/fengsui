local Util = require "packages.fengsui.pkg.fengsui_hebi.util"
local H = require "packages.fengsui.hegemony_util"
local marks = { "yinyangfish", "vanguard", "companion", "wild", "fengsui_heg_ascend", "fengsui_heg__descend" }
local zhuiji = fk.CreateSkill { name = "fengsui_heg__zhuiji" }
local function available(player)
  local result = {}
  for _, mark in ipairs(marks) do if player:getMark("@!!" .. mark) > 0 then table.insert(result, mark) end end
  return result
end
zhuiji:addEffect("active", {
  anim_type = "draw", card_num = 0, target_num = 0, card_filter = Util.FalseFunc, target_filter = Util.FalseFunc,
  can_use = function(self, player) return player:getMark(self.name .. "-disabled") == 0 and #available(player) > 0 end,
  on_use = function(self, room, effect)
    local player = effect.from; local choices = available(player); if #choices == 0 then return end
    local mark = room:askToChoice(player, { choices = choices, skill_name = self.name })
    H.addHegMark(player, mark)
    room:setPlayerMark(player, self.name .. "-disabled", 1)
    room:setPlayerMark(player, self.name .. "-damage", #Fk:translate("@!!" .. mark))
  end,
})
local function reduce(self, player)
  local n = player:getMark(self.name .. "-damage")
  if n > 0 then player.room:setPlayerMark(player, self.name .. "-damage", n - 1) end
  if n == 1 then player.room:setPlayerMark(player, self.name .. "-disabled", 0) end
end
zhuiji:addEffect(fk.Damage, { can_trigger = function(self, _, target, player, data) return target == player and player:hasSkill(self.name) and player:getMark(self.name .. "-damage") > 0 end, on_use = function(self, _, _, player) reduce(self, player) end })
zhuiji:addEffect(fk.Damaged, { can_trigger = function(self, _, target, player, data) return target == player and player:hasSkill(self.name) and player:getMark(self.name .. "-damage") > 0 end, on_use = function(self, _, _, player) reduce(self, player) end })
return zhuiji
