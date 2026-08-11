local H = require "packages.fengsui.hegemony_util"

local juanzhi = fk.CreateSkill{
  name = "fengsui_heg__juanzhi",
}

local function nameLength(name)
  return utf8.len(name) or #name
end

local function revealedSameCount(player)
  local n = 0
  for _, p in ipairs(player.room.alive_players) do
    if H.compareKingdomWith(p, player) then n = n + H.getGeneralsRevealedNum(p) end
  end
  return n
end

juanzhi:addEffect(fk.CardUseFinished, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(juanzhi.name) and
      player:usedSkillTimes(juanzhi.name, Player.HistoryRound) == 0 and
      data.card and nameLength(data.card.name) == revealedSameCount(player) and
      data.card:getId() > 0 and room:getCardArea(data.card:getId()) ~= Card.Void
  end,
  on_cost = function(self, event, target, player, data)
    local chosen = player.room:askToChoosePlayers(player, {
      targets = player.room:getOtherPlayers(player),
      min_num = 1,
      max_num = 1,
      skill_name = juanzhi.name,
      prompt = "#fengsui_heg__juanzhi-give",
      cancelable = true,
    })
    if #chosen > 0 then
      event:setCostData(self, {to = chosen[1]})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).to
    if to:isAlive() then room:obtainCard(to, data.card, true, fk.ReasonPrey, player, juanzhi.name) end
    room:addTableMarkIfNeed(player, "@fengsui_heg__juanzhi-turn", data.card.name)
  end,
})

Fk:loadTranslationTable{
  ["#fengsui_heg__juanzhi-give"] = "卷帙：选择一名其他角色获得此牌",
  ["@fengsui_heg__juanzhi-turn"] = "卷帙：",
}

return juanzhi
