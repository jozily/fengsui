local H = require "packages.fengsui.hegemony_util"

local yiju = fk.CreateSkill {
  name = "fengsui_heg__yiju",
  tags = { Skill.Compulsory },
}

yiju.SHUGUO_MARK = "@@fengsui_heg__shuguo"

local function isShuguoCard(card)
  return card and card:getMark(yiju.SHUGUO_MARK) > 0
end

-- 锁定技：与你势力相同的角色（含你自己）成为戍国牌的目标后，取消之。
-- 用 TargetConfirming：每个被指定的目标在确认时各触发一次，target 即当前目标本人。
yiju:addEffect(fk.TargetConfirming, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player.dead or not player:hasSkill(yiju.name) then return false end
    if not target or target.dead then return false end
    if not data.card or not isShuguoCard(data.card) then return false end
    return target == player or H.compareKingdomWith(player, target)
  end,
  on_cost = function(self, event, target, player, data) return true end,
  on_use = function(self, event, target, player, data)
    data:cancelTarget(target)
  end,
})

-- 失去戍国牌后：你的回合内摸一张，回合外弃置一张
yiju:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(yiju.name) or player.dead then return false end
    for _, move in ipairs(data) do
      if move.from == player then
        for _, info in ipairs(move.moveInfo) do
          local card = Fk:getCardById(info.cardId)
          if isShuguoCard(card) and
             (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) then
            return true
          end
        end
      end
    end
    return false
  end,
  on_cost = function(self) return true end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    -- 不在此清除戍国标记：使用牌时牌先进处理区、先触发本 AfterCardsMove，
    -- 若此处清标记，随后 TargetConfirming 阶段就识别不到戍国牌，
    -- 导致「同势力角色成为目标后取消之」失效。牌离手后 move.from 不再是本人，
    -- 同一张牌不会因此重复触发本效果，故无需靠清标记去重。
    if room.current == player then
      player:drawCards(1, yiju.name)
    elseif not player:isNude() then
      room:askToDiscard(player, {
        min_num = 1, max_num = 1, include_equip = true,
        skill_name = yiju.name, cancelable = false,
      })
    end
  end,
})

return yiju
