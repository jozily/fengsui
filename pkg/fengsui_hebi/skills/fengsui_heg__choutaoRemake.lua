local H = require "packages.fengsui.hegemony_util"

local choutao = fk.CreateSkill{
  name = "fengsui_heg__choutaoRemake",
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
      prompt = "#fengsui_heg__choutaoRemake-invoke::" .. target.id,
    })
  end,
  on_use = function(self, event, target, player, data)
    player.room:askToUseRealCard(player, {
      pattern = "slash",
      skill_name = choutao.name,
      prompt = "#fengsui_heg__choutaoRemake-use::" .. target.id,
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
  -- 存档技能必须使用带 Remake 后缀的键。skills 目录会被
  -- loadSkillSkelsByPath 整目录加载，若沿用现役 fengsui_heg__choutao 的键，
  -- 会把现役仇讨的名字、描述与发动提示一起覆盖成下面这份旧版文案。
  ["fengsui_heg__choutaoRemake"] = "仇讨",
  [":fengsui_heg__choutaoRemake"] = "其他角色的回合结束时，若你本回合获得过牌且手牌数大于其，你可对其使用一张无距离限制的【杀】。",
  ["#fengsui_heg__choutaoRemake-invoke"] = "仇讨：你可以对 %dest 使用一张无距离限制的【杀】",
  ["#fengsui_heg__choutaoRemake-use"] = "仇讨：请对 %dest 使用一张无距离限制的【杀】",

}

return choutao
