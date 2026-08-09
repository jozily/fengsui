local H = require "packages.fengsui.hegemony_util"

local zhengchi = fk.CreateSkill{
  name = "fengsui_heg__zhengchiRemake",
}

zhengchi:addEffect(fk.TargetSpecified, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if not data.firstTarget or data.card.type == Card.TypeEquip or
      not player:hasSkill(zhengchi.name) or not target or
      not H.compareKingdomWith(player, target) or
      player:usedSkillTimes(zhengchi.name, Player.HistoryRound) > 0 or
      player:isKongcheng() then
      return false
    end
    local card_targets = data.use:getAllTargets()
    return table.find(player.room.alive_players, function(p)
      return p ~= player and not p:isKongcheng() and not table.contains(card_targets, p)
    end)
  end,
  on_cost = function(self, event, target, player, data)
    local card_targets = data.use:getAllTargets()
    local candidates = table.filter(player.room.alive_players, function(p)
      return p ~= player and not p:isKongcheng() and not table.contains(card_targets, p)
    end)
    local chosen = player.room:askToChoosePlayers(player, {
      targets = candidates,
      min_num = 1,
      max_num = 1,
      prompt = "#fengsui_heg__zhengchiRemake-invoke",
      skill_name = zhengchi.name,
      cancelable = true,
    })
    if #chosen > 0 then
      event:setCostData(self, { to = chosen[1] })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local opponent = event:getCostData(self).to
    local result = player:pindian({ opponent }, zhengchi.name).results[opponent]
    local winner = result.winner
    if not winner then return end
    local loser = winner == player and opponent or player
    if not table.contains(data.use:getAllTargets(), loser) then
      data:addTarget(loser)
      player.room:sendLog{
        type = "#fengsui_heg__zhengchiRemake-target",
        from = player.id,
        to = { loser.id },
        arg = data.card:toLogString(),
      }
    end
    local winning_card = winner == player and result.fromCard or result.toCard
    if winning_card.number < 6 then
      data.from = winner
      player.room:sendLog{
        type = "#fengsui_heg__zhengchiRemake-user",
        from = winner.id,
        arg = data.card:toLogString(),
      }
    end
  end,
})

return zhengchi
