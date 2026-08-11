local H = require "packages.fengsui.hegemony_util"

local guru = fk.CreateSkill{
  name = "fengsui_heg__guruRemake",
  tags = { Skill.Compulsory },
}

local distance_mark = "@fengsui_heg__guruRemake_distance"

local function getDistanceX(player)
  if not player:hasSkill(guru.name) or not H.allGeneralsRevealed(player) then return 0 end
  local room = player.room or Fk:currentRoom()
  if not room then return 0 end
  local same = H.getSameKingdomPlayersNum(room, player)
  local kingdoms = 0
  for _, count in pairs(H.getKingdomPlayersNum(room)) do
    if count > 0 then kingdoms = kingdoms + 1 end
  end
  return same < kingdoms and same or 0
end

guru:addEffect(fk.DrawNCards, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(guru.name) and
      player:hasShownSkill(guru.name) and H.getGeneralsRevealedNum(player) == 1
  end,
  on_use = function(self, event, target, player, data)
    data.n = data.n + H.getSameKingdomPlayersNum(player.room, player)
  end,
})

guru:addEffect("distance", {
  correct_func = function(self, from, to)
    return getDistanceX(from) + getDistanceX(to)
  end,
})

local mark_refresh_events = {
  fk.TurnStart,
  fk.GeneralRevealed,
  fk.GeneralHidden,
  fk.Death,
  H.PlayerRemoved,
  fk.EventAcquireSkill,
  fk.EventLoseSkill,
}

for _, refresh_event in ipairs(mark_refresh_events) do
  guru:addEffect(refresh_event, {
    global = true,
    mute = true,
    can_refresh = function(self, event, target, player, data)
      return player:getMark(distance_mark) > 0 or player:hasSkill(guru.name, true, true)
    end,
    on_refresh = function(self, event, target, player, data)
      player.room:setPlayerMark(player, distance_mark, getDistanceX(player))
    end,
  })
end

return guru
