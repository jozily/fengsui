local zhengchi = fk.CreateSkill {
  name = "fengsui_heg__zhengchi",
}

local function movedHandCards(move)
  if not move or move.toArea ~= Card.PlayerHand then return {} end
  return table.map(move.moveInfo or {}, function(info) return info.cardId end)
end

local function ownerGave(player, move)
  return move.from == player and move.to and move.to ~= player and #movedHandCards(move) > 0
end

local function ownerReceived(player, move)
  return move.to == player and move.from and move.from ~= player and #movedHandCards(move) > 0
end

zhengchi:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self.name, true) then return false end
    for _, move in ipairs(data or {}) do
      if ownerGave(player, move) or ownerReceived(player, move) then return true end
    end
    return false
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local options = {}
    for _, move in ipairs(data or {}) do
      if ownerGave(player, move) then
        table.insert(options, { kind = "damage", to = move.to, ids = movedHandCards(move) })
      elseif ownerReceived(player, move) then
        local ids = movedHandCards(move)
        local other = table.filter(player:getCardIds("h"), function(id) return not table.contains(ids, id) end)
        if #other > 0 then table.insert(options, { kind = "recover", to = move.from, ids = ids, other = other }) end
      end
    end
    if #options == 0 then return false end
    local cost = options[1]
    if not room:askToSkillInvoke(player, {
      skill_name = self.name,
      prompt = cost.kind == "damage" and
        "#fengsui_heg__zhengchi-damage::" .. cost.to.id or
        "#fengsui_heg__zhengchi-recover",
    }) then return false end
    event:setCostData(self, cost)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cost = event:getCostData(self)
    if cost.kind == "damage" then
      local to = cost.to
      if to and to:isAlive() then
        room:damage { from = to, to = player, damage = 1, skillName = self.name }
        local ids = table.filter(cost.ids, function(id) return room:getCardArea(id) == Card.PlayerHand and
          table.contains(to:getCardIds("h"), id) end)
        if #ids > 0 then room:throwCard(ids, self.name, to, player) end
      end
    else
      local ids = room:askToCards(player, {
        min_num = 1, max_num = #cost.other, include_equip = false,
        skill_name = self.name, pattern = tostring(Exppattern{ id = cost.other }),
        prompt = "#fengsui_heg__zhengchi-discard",
      })
      if #ids > 0 then
        room:throwCard(ids, self.name, player, player)
        room:recover { who = player, num = 1, recoverBy = player, skillName = self.name }
      end
    end
  end,
})

Fk:loadTranslationTable {
  ["#fengsui_heg__zhengchi-damage"] = "正斥：是否令 %dest 对你造成1点伤害并弃置获得的牌？",
  ["#fengsui_heg__zhengchi-recover"] = "正斥：是否弃置其他手牌并回复1点体力？",
  ["#fengsui_heg__zhengchi-discard"] = "正斥：请选择要弃置的其他手牌",
}

return zhengchi
