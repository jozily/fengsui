local H = require "packages.fengsui.hegemony_util"

local zhouwang = fk.CreateSkill{
  name = "fengsui_heg__zhouwangRemake",
  tags = {Skill.DeputyPlace},
}

local function costNum(player)
  local room = player.room or Fk:currentRoom()
  if not room then return 0 end
  local n = 0
  for _, p in ipairs(room.alive_players) do
    if H.compareKingdomWith(p, player) then n = n + H.getGeneralsRevealedNum(p) end
  end
  return n
end

zhouwang:addEffect("active", {
  anim_type = "support",
  prompt = "#fengsui_heg__zhouwangRemake",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    local n = costNum(player)
    return player:usedSkillTimes(zhouwang.name, Player.HistoryPhase) == 0 and n > 0 and
      player:getMark("@!!yinyangfish") >= n
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player, to = effect.from, effect.tos[1]
    H.removeHegMark(room, player, "yinyangfish", costNum(player))
    local draw = 4 - player:getHandcardNum()
    if draw > 0 then player:drawCards(draw, zhouwang.name) end
    if player.dead or to.dead then return end
    room:useVirtualCard("known_both", nil, player, to, zhouwang.name, true)
    local names = {}
    local duplicated = table.find(to:getCardIds("h"), function(id)
      local name = Fk:getCardById(id).trueName
      if names[name] then return true end
      names[name] = true
      return false
    end)
    if duplicated then room:setPlayerMark(player, "@fengsui_heg__zhouwangRemake-round", 1) end
  end,
})

return zhouwang
