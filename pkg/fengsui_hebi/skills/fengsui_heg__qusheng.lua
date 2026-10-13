local U = require "packages.fengsui.pkg.fengsui_hebi.util"
local qusheng = fk.CreateSkill { name = "fengsui_heg__qusheng" }

local function hasSameNameOtherColor(room, id)
  local card = Fk:getCardById(id)
  if not card then return false end
  return table.find(room.discard_pile, function(other)
    local c = Fk:getCardById(other)
    return other ~= id and c and c.name == card.name and c.color ~= card.color
  end) ~= nil
end

qusheng:addEffect(fk.AfterCardsMove, {
  global = true,
  can_trigger = function(self, _, target, player, data)
    return U.hasGeneralName(player, "fengsui_heg__biyu") and player:hasShownSkill(self.name) and player:getMark(self.name .. "-turn") == 0 and data and
      table.find(data, function(m)
        if m.toArea ~= Card.DiscardPile or (m.moveReason ~= fk.ReasonUse and m.moveReason ~= fk.ReasonResponse) or not m.moveInfo then return false end
        return table.find(m.moveInfo, function(info) return hasSameNameOtherColor(player.room, info.cardId) end) ~= nil
      end) ~= nil
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, { skill_name = self.name, prompt = "#fengsui_heg__qusheng-invoke" }) then
      event:setCostData(self, { moves = data })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local candidates = {}
    for _, move in ipairs(event:getCostData(self).moves or {}) do
      if move.toArea == Card.DiscardPile and (move.moveReason == fk.ReasonUse or move.moveReason == fk.ReasonResponse) and move.moveInfo then
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          local card = Fk:getCardById(id)
          if card then
            for _, other in ipairs(room.discard_pile) do
              local c = Fk:getCardById(other)
              if other ~= id and c and c.name == card.name and c.color ~= card.color then
                table.insert(candidates, { first = id, second = other })
              end
            end
          end
        end
      end
    end
    if #candidates == 0 then return end
    local pair = candidates[math.random(#candidates)]
    -- 获得匹配的弃牌；本次使用/打出的牌回到牌堆顶。
    local gain, put = pair.second, pair.first
    room:setPlayerMark(player, self.name .. "-turn", 1)
    room:obtainCard(player, gain, true, fk.ReasonPrey, player, self.name)
    if room:getCardArea(put) == Card.DiscardPile then
      room:moveCardTo(put, Card.DrawPile, nil, fk.ReasonPut, self.name, nil, true, player)
      table.removeOne(room.draw_pile, put)
      table.insert(room.draw_pile, 1, put)
    end
  end,
})

qusheng:addEffect(fk.TurnStart, { global = true, can_refresh = function(self, _, target) return target and target:getMark(self.name .. "-turn") > 0 end, on_refresh = function(self, _, target) target.room:setPlayerMark(target, self.name .. "-turn", 0) end })
return qusheng
