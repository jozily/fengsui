local H = require "packages.fengsui.hegemony_util"

local choutao = fk.CreateSkill{
  name = "fengsui_heg__choutao",
}

local function gainedCountThisTurn(player)
  local n = 0
  for _, e in ipairs(player.room.logic:getEventsOfScope(GameEvent.MoveCards, 9999, function() return true end, Player.HistoryTurn)) do
    for _, move in ipairs(e.data or {}) do
      if move.to == player and move.toArea == Card.PlayerHand and move.from ~= player then
        n = n + #(move.moveInfo or {})
      end
    end
  end
  return n
end

local function damageTakenThisTurn(player)
  local n = 0
  for _, e in ipairs(player.room.logic:getEventsOfScope(GameEvent.Damage, 9999, function() return true end, Player.HistoryTurn)) do
    local damage = e.data
    if damage and damage.to == player and e.exec_ret == true then n = n + (damage.damage or 0) end
  end
  return n
end

choutao:addEffect(fk.EventPhaseStart, {
  global = true,
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target and target ~= player and target.phase == Player.Finish and target:isAlive() and
      player:hasSkill(choutao.name) and damageTakenThisTurn(player) > 0 and
      gainedCountThisTurn(player) > damageTakenThisTurn(player)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = choutao.name,
      prompt = "#fengsui_heg__choutao-invoke::" .. target.id,
    })
  end,
  on_use = function(self, event, target, player, data)
    player.room:damage { from = player, to = target, damage = 1, skillName = choutao.name }
  end,
})

Fk:loadTranslationTable{
  ["fengsui_heg__choutao"] = "仇讨",
  [":fengsui_heg__choutao"] = "其他角色的回合结束阶段，若你于此回合内受到过伤害且获得牌的数量大于受到的伤害值，你可以对该角色造成一点伤害。",
  ["#fengsui_heg__choutao-invoke"] = "仇讨：是否对 %dest 造成1点伤害？",

}

return choutao
