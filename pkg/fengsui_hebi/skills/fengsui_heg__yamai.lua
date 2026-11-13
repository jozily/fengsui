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
      event:setCostData(self, {use = use})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local use = event:getCostData(self).use
    if not use then return end
    use.extraUse = true
    player.room:useCard(use)
    -- 这张牌是从弃牌堆里展开进手牌区选的，用完后它已经回到弃牌堆，
    -- 但请求结束时按 id 回收展开项偶尔会漏掉，残影就留在手牌行里。
    -- 让该玩家的客户端重建一次手牌区（expand 列表随之清空）。
    local sp = player.serverplayer
    if sp and cbor then
      sp:doNotify("ChangeSelf", cbor.encode(player.id))
    end
  end,
})

return yamai
