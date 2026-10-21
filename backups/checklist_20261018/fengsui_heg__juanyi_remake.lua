local H = require "packages.fengsui.hegemony_util"
local juanyi = fk.CreateSkill { name = "fengsui_heg__juanyi" }
local function gained(player, data)
  local counts, ret = {}, {}
  for _, move in ipairs(data or {}) do
    local to = move.to
    if to and to:isAlive() and move.toArea == Card.PlayerHand and H.compareKingdomWith(player, to) and move.moveInfo then counts[to] = (counts[to] or 0) + #move.moveInfo end
  end
  for p, n in pairs(counts) do if n >= 2 then table.insert(ret, p) end end
  return ret
end
juanyi:addEffect(fk.AfterCardsMove, {
  global = true,
  can_trigger = function(self, _, _, player, data) return player:hasShownSkill(self.name) and #gained(player, data) > 0 end,
  on_cost = function(self, event, _, player, data)
    local tos = player.room:askToChoosePlayers(player, {targets = gained(player, data), min_num = 1, max_num = 1, skill_name = self.name, prompt = "#fengsui_heg__juanyi-target", cancelable = true})
    if #tos == 0 then return false end; event:setCostData(self, tos[1]); return true
  end,
  on_use = function(self, event, _, player)
    local room, target = player.room, event:getCostData(self); if not target or target.dead then return end
    target:drawCards(1, self.name)
    local tos = table.filter(room.alive_players, function(p) return p ~= target end); if #tos == 0 or target:isNude() then return end
    local chosen = room:askToChoosePlayers(target, {targets = tos, min_num = 1, max_num = 1, skill_name = self.name, prompt = "#fengsui_heg__juanyi-recipient", cancelable = false})[1]
    if not chosen then return end
    local card = room:askToChooseCard(target, {target = target, flag = "he", skill_name = self.name, prompt = "#fengsui_heg__juanyi-give"}); if not card then return end
    room:obtainCard(chosen, card, false, fk.ReasonGive, target, self.name)
    if not H.compareKingdomWith(target, chosen) and not chosen:isNude() then
      local id = room:askToChooseCard(target, {
        target = chosen, flag = "he", skill_name = self.name,
        prompt = "#fengsui_heg__juanyi-discard::" .. chosen.id,
      })
      if id then room:throwCard({id}, self.name, chosen, target) end
    end
  end,
})
return juanyi
