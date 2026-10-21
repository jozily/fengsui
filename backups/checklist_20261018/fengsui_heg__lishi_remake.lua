local H = require "packages.fengsui.hegemony_util"
local lishi = fk.CreateSkill { name = "fengsui_heg__lishi" }
local function lost(player, data)
  local counts, ret = {}, {}
  for _, move in ipairs(data or {}) do
    local from = move.from
    if from and from:isAlive() and H.compareKingdomWith(player, from) and move.moveInfo then
      for _, info in ipairs(move.moveInfo) do if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then counts[from] = (counts[from] or 0) + 1 end end
    end
  end
  for p, n in pairs(counts) do if n >= 2 and p:getHandcardNum() <= p.hp then table.insert(ret, p) end end
  return ret
end
lishi:addEffect(fk.AfterCardsMove, {
  global = true,
  can_trigger = function(self, _, _, player, data) return player:hasShownSkill(self.name) and table.find(lost(player, data), function(p) return p == player or not player:isNude() end) ~= nil end,
  on_cost = function(self, event, _, player, data)
    local tos = player.room:askToChoosePlayers(player, {targets = table.filter(lost(player, data), function(p) return p == player or not player:isNude() end), min_num = 1, max_num = 1, skill_name = self.name, prompt = "#fengsui_heg__lishi-target", cancelable = true})
    if #tos == 0 then return false end; event:setCostData(self, tos[1]); return true
  end,
  on_use = function(self, event, _, player)
    local room, target = player.room, event:getCostData(self); if not target or target.dead then return end
    if target == player then player:drawCards(1, self.name); return end
    if player:isNude() then return end
    local card = room:askToChooseCard(player, {target = player, flag = "he", skill_name = self.name, prompt = "#fengsui_heg__lishi-give"}); if not card then return end
    room:obtainCard(target, card, false, fk.ReasonGive, player, self.name); player:drawCards(1, self.name)
  end,
})
return lishi
