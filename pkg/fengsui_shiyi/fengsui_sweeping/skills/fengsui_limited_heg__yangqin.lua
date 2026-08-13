local H = require "packages.hegemony.util"
local yangqin = fk.CreateSkill { name = "fengsui_limited_heg__yangqin", tags = { Skill.Compulsory } }

Fk:loadTranslationTable {
  ["fengsui_limited_heg__yangqin"] = "扬琴",
  [":fengsui_limited_heg__yangqin"] = "锁定技，当你的体力值发生变化后，若你没有国战标记，你摸一张牌；若你的体力值为3，你获得一枚“阴阳鱼”；若为2，你获得一枚“先驱”；若为1，你视为对一名其他角色使用一张雷【杀】。",
  ["#fengsui_limited_heg__yangqin-slash"] = "扬琴：选择一名角色，视为对其使用雷【杀】",
}

local function hasHegMark(player)
  return table.find({ "@!!vanguard", "@!!yinyangfish", "@!!companion", "@!!wild", "@!!fengsui_heg_ascend", "@!!fengsui_heg__descend" },
    function(mark) return player:getMark(mark) > 0 end) ~= nil
end

yangqin:addEffect(fk.HpChanged, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yangqin.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player.hp >= 1 and player.hp <= 3 then
      room:broadcastPlaySound("./packages/fengsui/audio/skill/fengsui_limited_heg__yangqin" .. player.hp)
    end
    if not hasHegMark(player) then player:drawCards(1, yangqin.name) end
    if player.hp == 3 then H.addHegMark(player, "yinyangfish")
    elseif player.hp == 2 then H.addHegMark(player, "vanguard")
    elseif player.hp == 1 then
      local slash = Fk:cloneCard("thunder__slash")
      local targets = table.filter(room:getOtherPlayers(player), function(p)
        return player:canUseTo(slash, p, { bypass_times = true, bypass_distances = true })
      end)
      if #targets == 0 then return end
      local tos = room:askToChoosePlayers(player, { targets = targets, min_num = 1, max_num = 1,
        cancelable = false, skill_name = yangqin.name, prompt = "#fengsui_limited_heg__yangqin-slash" })
      if #tos > 0 then room:useVirtualCard("thunder__slash", nil, player, tos[1], yangqin.name, true) end
    end
  end,
})

return yangqin
