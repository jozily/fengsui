local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local yamai = fk.CreateSkill{
  name = "fengsui_heg__yamai",
}

yamai:addEffect("arraysummon", { array_type = "formation" })

-- 记录：山涛本回合获得的牌（记在山涛身上）、
-- 与山涛同队列的角色本回合使用过的牌（记在使用者身上）。
yamai:addEffect(fk.AfterCardsMove, {
  global = true,
  mute = true,
  can_refresh = function(self, event, target, player, data)
    if not player:hasSkill(yamai.name) then return false end
    return table.find(data, function(move)
      if move.to == player and move.toArea == Card.PlayerHand then return true end
      if move.moveReason == fk.ReasonUse and move.from and U.inSameQueue(move.from, player) then
        return table.find(move.moveInfo, function(info)
          return info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip
        end) ~= nil
      end
      return false
    end) ~= nil
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local gained = player:getTableMark("fengsui_heg__yamai_cards-turn")
    for _, move in ipairs(data) do
      if move.to == player and move.toArea == Card.PlayerHand then
        for _, info in ipairs(move.moveInfo) do
          table.insertIfNeed(gained, info.cardId)
        end
      elseif move.moveReason == fk.ReasonUse and move.from and U.inSameQueue(move.from, player) then
        local used = move.from:getTableMark("fengsui_heg__yamai_used-turn")
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
            table.insertIfNeed(used, info.cardId)
          end
        end
        room:setPlayerMark(move.from, "fengsui_heg__yamai_used-turn", used)
      end
    end
    room:setPlayerMark(player, "fengsui_heg__yamai_cards-turn", gained)
  end,
})

local function getUsableCards(room, player, turnPlayer)
  local pool = {}
  table.insertTable(pool, player:getTableMark("fengsui_heg__yamai_cards-turn"))
  table.insertTable(pool, turnPlayer:getTableMark("fengsui_heg__yamai_used-turn"))
  return table.filter(pool, function(id)
    local area = room:getCardArea(id)
    return (area == Card.PlayerHand and room:getCardOwner(id) == player) or area == Card.DiscardPile
  end)
end

yamai:addEffect(fk.TurnEnd, {
  global = true,
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(yamai.name) or not target or not U.inSameQueue(target, player) then
      return false
    end
    return #getUsableCards(player.room, player, target) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = getUsableCards(room, player, target)
    -- 手牌本来就在手牌区；若把它们也塞进 expand_pile，客户端会为同一张牌
    -- 再生成一个 CardItem，请求结束时按 id 回收清不干净，残影会盖在手牌上。
    -- 这里只把弃牌堆里的牌作为额外牌堆展开，pattern 仍是全部可用牌。
    local expand = table.filter(cards, function(id)
      return room:getCardArea(id) == Card.DiscardPile
    end)
    local use = room:askToUseRealCard(player, {
      pattern = cards,
      expand_pile = expand,
      skill_name = yamai.name,
      prompt = "#fengsui_heg__yamai-use::" .. target.id,
      cancelable = true,
      skip = true,
      extra_data = {bypass_times = true},
    })
    if use then
      -- 记住本次从弃牌堆展开的牌，on_use 用完牌后据此精确清除客户端残影
      event:setCostData(self, {use = use, expand = expand})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local cost = event:getCostData(self)
    local use = cost.use
    if not use then return end
    use.extraUse = true
    player.room:useCard(use)

    -- 弃牌堆展开的牌在请求里被客户端 DashboardModel.expandedCards 生成了
    -- CardItem；用完后牌已回弃牌堆，但请求收尾按 id 回收偶尔漏项，残影盖在
    -- 手牌行上。旧做法发 ChangeSelf 全量重建，时序上会被随后到达的 UI 更新
    -- 再次污染。改为参照 ol 门阀士族的精确清理：直接对这些 id 发 _delete，
    -- 走 applyChange → expandedCards.splice → HandcardArea.syncCards 回收。
    local expand = cost.expand
    local sp = player.serverplayer
    if sp and cbor and type(expand) == "table" and #expand > 0 then
      local del = {}
      for _, id in ipairs(expand) do
        table.insert(del, { type = "CardItem", id = id })
      end
      sp:doNotify("UpdateRequestUI", cbor.encode({ _type = "Room", _delete = del }))
    end
  end,
})

return yamai
