local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local zhengchi = fk.CreateSkill{
  name = "fengsui_heg__zhengchi",
}

zhengchi:addEffect(fk.TargetSpecified, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if not data.firstTarget or not player:hasSkill(zhengchi.name) or not target or
      not H.compareKingdomWith(player, target) or not H.allGeneralsRevealed(player) or
      player:isKongcheng() then return false end
    if data.card.type ~= Card.TypeBasic and not data.card:isCommonTrick() then return false end
    local current_targets = data.use:getAllTargets()
    return table.find(player.room.alive_players, function(p)
      return p ~= player and p ~= target and not p:isKongcheng() and
        not table.contains(current_targets, p)
    end) ~= nil
  end,
  on_cost = function(self, event, target, player, data)
    local current_targets = data.use:getAllTargets()
    local candidates = table.filter(player.room.alive_players, function(p)
      return p ~= player and p ~= target and not p:isKongcheng() and
        not table.contains(current_targets, p)
    end)
    local chosen = player.room:askToChoosePlayers(player, {
      targets = candidates,
      min_num = 1,
      max_num = 1,
      prompt = "#fengsui_heg__zhengchi-invoke",
      skill_name = zhengchi.name,
      cancelable = true,
    })
    if #chosen > 0 then
      event:setCostData(self, {to = chosen[1]})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local opponent = event:getCostData(self).to
    U.hideSkillGeneral(player, zhengchi.name)
    if player.dead or opponent.dead then return end
    local result = player:pindian({opponent}, zhengchi.name).results[opponent]
    local winner = result and result.winner
    if not winner then return end
    data.from = winner
    local winning_card = winner == player and result.fromCard or result.toCard
    if winner:isAlive() and H.compareKingdomWith(winner, player) and
      room:askToSkillInvoke(player, {
        skill_name = zhengchi.name,
        prompt = "#fengsui_heg__zhengchi-reveal::" .. winner.id .. ":" .. winning_card.number,
      }) then
      U.revealSkillGeneral(player, zhengchi.name)
      data.card.number = winning_card.number
    end
  end,
})

Fk:loadTranslationTable{
  ["#fengsui_heg__zhengchi-invoke"] = "正斥：暗置此武将牌并与一名非此牌目标角色拼点",
}

return zhengchi
