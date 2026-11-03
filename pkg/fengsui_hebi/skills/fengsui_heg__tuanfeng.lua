-- 抟风（周处）
-- 当你受到或造成伤害后，若你的武将牌均明置，你可以暗置另一张武将牌
-- 并获得本回合进入弃牌堆的不同花色的牌各一张。
local H = require "packages.fengsui.hegemony_util"

local tuanfeng = fk.CreateSkill{
  name = "fengsui_heg__tuanfeng",
}

-- 本回合进入弃牌堆、且此刻仍留在弃牌堆中的牌，按花色分组
local function discardIdsBySuit(room)
  local by_suit, seen = {}, {}
  for _, e in ipairs(room.logic:getEventsOfScope(GameEvent.MoveCards, 9999,
      function() return true end, Player.HistoryTurn)) do
    for _, move in ipairs(e.data or {}) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo or {}) do
          local id = info.cardId
          if id and not seen[id] and room:getCardArea(id) == Card.DiscardPile then
            seen[id] = true
            local card = Fk:getCardById(id)
            if card and card.suit ~= Card.NoSuit then
              by_suit[card.suit] = by_suit[card.suit] or {}
              table.insert(by_suit[card.suit], id)
            end
          end
        end
      end
    end
  end
  return by_suit
end

local function doTuanfeng(self, player)
  local room = player.room
  -- 暗置另一张武将牌：周处所在武将牌之外的那张
  local hideDeputy = player.general == "fengsui_heg__zhouchu"
  player:hideGeneral(hideDeputy)
  room:sendLog{
    type = "#ChangeHiddenGeneral",
    from = player.id,
    arg = hideDeputy and "deputyGeneral" or "mainGeneral",
    toast = true,
  }
  -- 每个花色随机获得一张
  local by_suit = discardIdsBySuit(room)
  local gained = {}
  for _, ids in pairs(by_suit) do
    local avail = table.filter(ids, function(id)
      return room:getCardArea(id) == Card.DiscardPile
    end)
    if #avail > 0 then
      table.insert(gained, avail[math.random(1, #avail)])
    end
  end
  if #gained > 0 then
    room:obtainCard(player, gained, true, fk.ReasonPrey, player, tuanfeng.name)
  end
end

local function canTuanfeng(self, player)
  return player:hasSkill(tuanfeng.name) and H.allGeneralsRevealed(player) and
    next(discardIdsBySuit(player.room)) ~= nil
end

tuanfeng:addEffect(fk.Damage, {
  anim_type = "drawcard",
  global = true,
  can_trigger = function(self, event, target, player, data)
    return data and data.from == player and canTuanfeng(self, player)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = tuanfeng.name,
      prompt = "#fengsui_heg__tuanfeng-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    doTuanfeng(self, player)
  end,
})

tuanfeng:addEffect(fk.Damaged, {
  anim_type = "drawcard",
  global = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and canTuanfeng(self, player)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = tuanfeng.name,
      prompt = "#fengsui_heg__tuanfeng-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    doTuanfeng(self, player)
  end,
})

return tuanfeng
