local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local tuanfeng = fk.CreateSkill{
  name = "fengsui_heg__tuanfeng",
}

local handlimit_mark = "@fengsui_heg__tuanfeng_handlimit"

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

-- 每个花色随机取一张
local function pickOnePerSuit(room)
  local by_suit = discardIdsBySuit(room)
  local suits = {}
  for suit in pairs(by_suit) do table.insert(suits, suit) end
  table.sort(suits)
  local picked = {}
  for _, suit in ipairs(suits) do
    local id = room:tableRandomPick(by_suit[suit], 1)[1]
    if id then table.insert(picked, id) end
  end
  return picked
end

tuanfeng:addEffect(fk.Damaged, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasShownSkill(tuanfeng.name) and
      H.allGeneralsRevealed(player) and #pickOnePerSuit(player.room) > 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = tuanfeng.name,
      prompt = "#fengsui_heg__tuanfeng-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ids = pickOnePerSuit(room)
    if #ids == 0 then return end
    U.hideSkillGeneral(player, tuanfeng.name)
    room:obtainCard(player, ids, true, fk.ReasonPrey, player, tuanfeng.name)
  end,
})

tuanfeng:addEffect(fk.Damage, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return data and data.from == player and player:hasShownSkill(tuanfeng.name) and
      player.room.current ~= nil
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = tuanfeng.name,
      prompt = "#fengsui_heg__tuanfeng-handlimit::" .. player.room.current.id,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local current = room.current
    if not current then return end
    room:addPlayerMark(current, MarkEnum.AddMaxCardsInTurn, 2)
    local total = math.floor(current:getMark(MarkEnum.AddMaxCardsInTurn))
    room:setPlayerMark(current, handlimit_mark, "手牌上限+" .. total)
    room:broadcastProperty(current, "MaxCards")
  end,
})

tuanfeng:addEffect(fk.TurnEnd, {
  global = true,
  can_refresh = function(self, event, target, player, data)
    return target and target:getMark(handlimit_mark) ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    target.room:setPlayerMark(target, handlimit_mark, 0)
  end,
})

-- 标记名留空，界面上只显示标记值本身（如“手牌上限+4”），避免与数值重复
Fk:loadTranslationTable{
  ["@fengsui_heg__tuanfeng_handlimit"] = "",
}

return tuanfeng
