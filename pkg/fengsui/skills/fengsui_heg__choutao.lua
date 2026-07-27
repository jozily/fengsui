local H = require "packages.hegemony.util"

local choutao = fk.CreateSkill{
  name = "fengsui_heg__choutao",
}

-- 记录是否获取过牌
choutao:addEffect(fk.AfterCardsMove, {
  global = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(choutao.name) then return false end
    if player:getMark("fengsui_heg__choutao_got-turn") == 0 then
      for _, move in ipairs(data) do
        -- 正常向获得牌，而不是用牌造成的位移或其他无所谓得牌的行为
        if move.to == player and move.toArea == Card.PlayerHand then 
          return true 
        end
      end
    end
    return false
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "fengsui_heg__choutao_got-turn", 1)
  end,
})

choutao:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and target.phase == Player.Finish and
      player:hasSkill(choutao.name) and player:getMark("fengsui_heg__choutao_got-turn") > 0 and
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
  [":fengsui_heg__choutao"] = "其他角色的回合结束阶段，若你本回合获得过牌且手牌数大于其，你可对其使用一张无距离限制的【杀】。",
  ["#fengsui_heg__choutao-invoke"] = "仇讨：你可以对 %dest 使用一张无距离限制的【杀】",
  ["#fengsui_heg__choutao-use"] = "仇讨：请对 %dest 使用一张无距离限制的【杀】",

}

return choutao
