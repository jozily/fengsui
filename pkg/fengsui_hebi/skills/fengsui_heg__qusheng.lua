local U = require "packages.fengsui.pkg.fengsui_hebi.util"
local qusheng = fk.CreateSkill { name = "fengsui_heg__qusheng" }

-- 在弃牌堆中寻找与该牌同名但颜色不同的所有牌（可能有多张）
local function findMatches(room, id)
  local card = Fk:getCardById(id)
  if not card then return {} end
  local matches = {}
  for _, other in ipairs(room.discard_pile) do
    if other ~= id then
      local c = Fk:getCardById(other)
      if c and c.name == card.name and c.color ~= card.color then
        table.insert(matches, other)
      end
    end
  end
  return matches
end

-- 另一张武将牌（非取声所在的那张）是否明置；返回其位置（是否副将）
local function otherGeneralShown(player)
  local place = U.getSkillPlace(player, qusheng.name)
  if place == nil then return nil end
  local otherName = place and player.general or player.deputyGeneral
  return place, otherName ~= "anjiang"
end

qusheng:addEffect(fk.AfterCardsMove, {
  global = true,
  can_trigger = function(self, _, target, player, data)
    -- global 触发技不需要玩家拥有技能即可触发，必须自行校验技能归属，
    -- 否则武将牌暗置、技能已移除时仍会弹出询问框。
    if not player:hasSkill(qusheng.name) then return false end
    if not U.hasGeneralName(player, "fengsui_heg__biyu") then return false end
    local _, shown = otherGeneralShown(player)
    if not shown then return false end
    if not data then return false end
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile and move.moveInfo then
        for _, info in ipairs(move.moveInfo) do
          if #findMatches(player.room, info.cardId) > 0 then return true end
        end
      end
    end
    return false
  end,
  on_cost = function(self, event, target, player, data)
    local candidates = {}
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile and move.moveInfo then
        for _, info in ipairs(move.moveInfo) do
          local matches = findMatches(player.room, info.cardId)
          if #matches > 0 then
            table.insert(candidates, { orig = info.cardId, matches = matches })
          end
        end
      end
    end
    if #candidates == 0 then return false end
    if player.room:askToSkillInvoke(player, { skill_name = self.name, prompt = "#fengsui_heg__qusheng-invoke" }) then
      event:setCostData(self, { candidates = candidates })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local place = otherGeneralShown(player)
    local candidates = event:getCostData(self).candidates
    local gainIds = {}
    for _, pair in ipairs(candidates) do
      for _, m in ipairs(pair.matches) do
        if not table.contains(gainIds, m) then table.insert(gainIds, m) end
      end
    end
    local gain = gainIds[1]
    if #gainIds > 1 then
      local picked = room:askToChooseCards(player, {
        target = player, flag = { card_data = { { self.name, gainIds } } },
        min = 1, max = 1, skill_name = self.name,
        prompt = "#fengsui_heg__qusheng-choose",
      })
      gain = picked[1] or gain
    end
    local orig
    for _, pair in ipairs(candidates) do
      if table.contains(pair.matches, gain) then
        orig = pair.orig
        break
      end
    end
    player:hideGeneral(not place)
    room:obtainCard(player, gain, true, fk.ReasonPrey, player, self.name)
    if orig and room:getCardArea(orig) == Card.DiscardPile then
      room:moveCards {
        ids = { orig }, toArea = Card.DrawPile, drawPilePosition = 1,
        moveReason = fk.ReasonPut, skillName = self.name, moveVisible = true,
      }
    end
  end,
})

return qusheng
