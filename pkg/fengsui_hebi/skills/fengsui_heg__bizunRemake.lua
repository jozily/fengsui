local H = require "packages.fengsui.hegemony_util"

local bizun = fk.CreateSkill{
  name = "fengsui_heg__bizunRemake",
}

local function sameKingdomNum(player)
  local room = player.room or Fk:currentRoom()
  if not room then return 0 end
  return #table.filter(room.alive_players, function(p)
    return H.compareKingdomWith(p, player)
  end)
end

local function emptiedAreas(move)
  if not move.from then return false end
  for _, info in ipairs(move.moveInfo) do
    if info.fromArea == Card.PlayerHand and move.from:isKongcheng() then return true end
    if info.fromArea == Card.PlayerEquip and #move.from:getCardIds("e") == 0 then return true end
    if info.fromArea == Card.PlayerJudge and #move.from:getCardIds("j") == 0 then return true end
  end
  return false
end

bizun:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  times = function(self, player)
    return sameKingdomNum(player) - player:usedSkillTimes(bizun.name, Player.HistoryTurn)
  end,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(bizun.name) or
      player:usedSkillTimes(bizun.name, Player.HistoryTurn) >= sameKingdomNum(player) then
      return false
    end
    return table.find(data, function(move)
      return move.from and H.compareKingdomWith(move.from, player) and emptiedAreas(move)
    end) ~= nil
  end,
  on_cost = function(self, event, target, player, data)
    local targets = {}
    for _, move in ipairs(data) do
      if move.from and H.compareKingdomWith(move.from, player) and emptiedAreas(move) then
        table.insertIfNeed(targets, move.from)
      end
    end
    local tos = player.room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      skill_name = bizun.name,
      prompt = "#fengsui_heg__bizunRemake-invoke",
      cancelable = true,
    })
    if #tos > 0 then
      event:setCostData(self, {to = tos[1]})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local to = event:getCostData(self).to
    if to:isAlive() then to:drawCards(1, bizun.name) end
  end,
})

return bizun
