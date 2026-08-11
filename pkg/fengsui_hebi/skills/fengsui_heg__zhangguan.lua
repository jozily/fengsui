local H = require "packages.fengsui.hegemony_util"

local zhangguan = fk.CreateSkill{
  name = "fengsui_heg__zhangguan",
  tags = { Skill.Compulsory },
}

local function limit(player)
  local same, other = 0, 0
  local room = player.room or Fk:currentRoom()
  if not room then return 0 end
  for _, p in ipairs(room.alive_players) do
    local n = H.getGeneralsRevealedNum(p)
    if H.compareKingdomWith(player, p) then
      same = same + n
    elseif n > 0 then
      other = other + n
    end
  end
  return other - same
end

local function updateMark(room, player)
  if player:isAlive() and player:hasSkill(zhangguan.name, true) then
    room:setPlayerMark(player, "@fengsui_heg__zhangguan", limit(player))
  else
    room:setPlayerMark(player, "@fengsui_heg__zhangguan", 0)
  end
end

local function applies(player, card)
  return card and (card.type == Card.TypeBasic or card:isCommonTrick()) and
    card.number > 0 and card.number <= limit(player)
end

zhangguan:addEffect(fk.TargetSpecified, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhangguan.name) and data.firstTarget and
      applies(player, data.card)
  end,
  on_use = function(self, event, target, player, data)
    for _, p in ipairs(data.use:getAllTargets()) do
      data:cancelTarget(p)
    end
  end,
})

zhangguan:addEffect(fk.TargetConfirmed, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhangguan.name) and data.from ~= player and
      applies(player, data.card)
  end,
  on_use = function(self, event, target, player, data)
    data:cancelTarget(player)
  end,
})

zhangguan:addEffect(fk.GeneralRevealed, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(zhangguan.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    updateMark(player.room, player)
  end,
})

zhangguan:addEffect(fk.GeneralHidden, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(zhangguan.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    updateMark(player.room, player)
  end,
})

zhangguan:addEffect(fk.Death, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(zhangguan.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    updateMark(player.room, player)
  end,
})

zhangguan:addAcquireEffect(function(self, player)
  updateMark(player.room, player)
end)

zhangguan:addLoseEffect(function(self, player)
  player.room:setPlayerMark(player, "@fengsui_heg__zhangguan", 0)
end)

Fk:loadTranslationTable{
  ["@fengsui_heg__zhangguan"] = "仗关：",
}

return zhangguan
