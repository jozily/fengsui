local H = require "packages.hegemony.util"
local zhenming = fk.CreateSkill { name = "fengsui_limited_heg__zhenming" }
local marks = {
  { "@!!vanguard", "vanguard" }, { "@!!yinyangfish", "yinyangfish" },
  { "@!!companion", "companion" }, { "@!!wild", "wild" },
}

Fk:loadTranslationTable {
  ["fengsui_limited_heg__zhenming"] = "震鸣",
  [":fengsui_limited_heg__zhenming"] = "出牌阶段，你可以随机获得一枚本局游戏中出现过的国战标记（“升”和“降”除外），然后此技能失效直至你杀死角色。",
}

local function available(player)
  local room = player.room or Fk:currentRoom()
  if not room then return {} end
  return table.filter(marks, function(pair)
    return table.find(room.players, function(p) return p:getMark(pair[1]) > 0 end) ~= nil or
      table.contains(room:getBanner("fengsui_heg_marks_used") or {}, pair[2])
  end)
end

zhenming:addEffect("active", {
  card_num = 0, target_num = 0, card_filter = Util.FalseFunc, target_filter = Util.FalseFunc,
  can_use = function(self, player)
    return player:getMark("fengsui_limited_heg__zhenming_invalid") == 0 and #available(player) > 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local pair = table.random(available(player))
    if pair then
      H.addHegMark(player, pair[2])
      room:setPlayerMark(player, "fengsui_limited_heg__zhenming_invalid", 1)
      room:broadcastPlaySound("./packages/fengsui/audio/skill/fengsui_limited_heg__zhenming")
    end
  end,
})

zhenming:addEffect(fk.Death, {
  can_refresh = function(self, event, target, player, data)
    return player:getMark("fengsui_limited_heg__zhenming_invalid") > 0 and data.damage and data.damage.from == player
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "fengsui_limited_heg__zhenming_invalid", 0)
  end,
})

return zhenming
