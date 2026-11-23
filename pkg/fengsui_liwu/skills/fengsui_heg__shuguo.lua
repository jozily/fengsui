local H = require "packages.fengsui.hegemony_util"

local shuguo = fk.CreateSkill {
  name = "fengsui_heg__shuguo",
}

local DISCARD_MARK = "fengsui_heg__shuguo_discard-turn"

-- 记录当前回合角色本回合弃置的牌（含花色），-turn 回合结束自动清零
shuguo:addEffect(fk.AfterCardsMove, {
  global = true,
  mute = true,
  can_refresh = function(self, event, target, player, data)
    return player.dead == false and player.room.current ~= nil
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local cur = room.current
    for _, move in ipairs(data) do
      if move.from == cur and move.moveReason == fk.ReasonDiscard then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip or
             info.fromArea == Card.PlayerJudge then
            local rec = cur:getTableMark(DISCARD_MARK)
            table.insertIfNeed(rec, info.cardId)
            room:setPlayerMark(cur, DISCARD_MARK, rec)
          end
        end
      end
    end
  end,
})

shuguo:addEffect(fk.TurnEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(shuguo.name) or player.dead then return false end
    local rec = target:getTableMark(DISCARD_MARK)
    if #rec == 0 then return false end
    -- 弃牌仍须在弃牌堆中，且花色两两不同
    local suits = {}
    for _, id in ipairs(rec) do
      if player.room:getCardArea(id) ~= Card.DiscardPile then return false end
      local suit = Fk:getCardById(id).suit
      if table.contains(suits, suit) then return false end
      table.insert(suits, suit)
    end
    return true
  end,
  on_cost = function(self, event, target, player, data)
    local rec = target:getTableMark(DISCARD_MARK)
    -- 弃牌堆的牌须用 expand_pile 展开才能在选择界面显示并自选
    local chosen = player.room:askToCards(player, {
      min_num = 1, max_num = 1,
      pattern = tostring(Exppattern{ id = rec }),
      expand_pile = rec,
      skill_name = shuguo.name,
      prompt = "#fengsui_heg__shuguo-choose",
      cancelable = true,
    })
    if #chosen > 0 then
      event:setCostData(self, { cardid = chosen[1] })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local id = event:getCostData(self).cardid
    room:setPlayerMark(target, DISCARD_MARK, {})
    -- 获得的牌直接带可见文本 mark（牌面显示"戍国"），供义拒识别
    room:obtainCard(player, id, true, fk.ReasonPrey, player, shuguo.name, { "@@fengsui_heg__shuguo", 1 })
    -- 再显式打一次牌面 mark，确保客户端显示
    local shuguoCard = Fk:getCardById(id)
    if shuguoCard then room:setCardMark(shuguoCard, "@@fengsui_heg__shuguo", 1) end
  end,
})

return shuguo
