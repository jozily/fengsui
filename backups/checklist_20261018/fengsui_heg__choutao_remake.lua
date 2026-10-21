local H = require "packages.fengsui.hegemony_util"

local choutao = fk.CreateSkill{
  name = "fengsui_heg__choutao",
}

local function gainedCardThisTurn(player)
  return #player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
    return table.find(e.data, function(move)
      return move.to == player and move.toArea == Card.PlayerHand and #move.moveInfo > 0
    end) ~= nil
  end, Player.HistoryTurn) > 0
end

choutao:addEffect(fk.TurnEnd, {
  global = true,
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(choutao.name) and
      gainedCardThisTurn(player) and
      player:getHandcardNum() > target:getHandcardNum() and
      table.find(player:getCardIds("h"), function(id)
        local card = Fk:getCardById(id)
        return card.trueName == "slash" and
          player:canUseTo(card, target, { bypass_distances = true, bypass_times = true })
      end)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = choutao.name,
      prompt = "#fengsui_heg__choutao-invoke::" .. target.id,
    })
  end,
  on_use = function(self, event, target, player, data)
    player.room:askToUseRealCard(player, {
      pattern = "slash",
      skill_name = choutao.name,
      prompt = "#fengsui_heg__choutao-use::" .. target.id,
      cancelable = false,
      extra_data = {
        exclusive_targets = { target.id },
        bypass_distances = true,
        bypass_times = true,
        extraUse = true,
      },
    })
  end,
})

Fk:loadTranslationTable{
  ["fengsui_heg__choutao"] = "仇讨",
  [":fengsui_heg__choutao"] = "其他角色的回合结束时，若你本回合获得过牌且手牌数大于其，你可对其使用一张无距离限制的【杀】。",
  ["#fengsui_heg__choutao-invoke"] = "仇讨：你可以对 %dest 使用一张无距离限制的【杀】",
  ["#fengsui_heg__choutao-use"] = "仇讨：请对 %dest 使用一张无距离限制的【杀】",

}

return choutao
