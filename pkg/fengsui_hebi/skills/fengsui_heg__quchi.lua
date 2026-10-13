local U = require "packages.fengsui.pkg.fengsui_hebi.util"
local H = require "packages.fengsui.hegemony_util"
local quchi = fk.CreateSkill { name = "fengsui_heg__quchi" }

local function invoke(self, event, _, player)
  local cards = player.room:askToCards(player, {
    min_num = 2, max_num = 2, include_equip = true, cancelable = true,
    skill_name = self.name, prompt = "#fengsui_heg__quchi-recast",
  })
  if #cards ~= 2 then return false end
  event:setCostData(self, {cards = cards})
  return true
end

local function resolve(self, event, _, player)
  local room = player.room
  local place = U.getSkillPlace(player, self.name)
  if place == nil then return end
  player:hideGeneral(place)
  room:recastCard(event:getCostData(self).cards, player, self.name)
  if player.dead then return end

  local judged, colors = {}, {}
  for _ = 1, 2 do
    local judge = {who = player, reason = self.name, pattern = ".", skipDrop = true}
    room:judge(judge)
    if judge.card then
      local id = judge.card:getEffectiveId()
      if room:getCardArea(id) == Card.Processing then
        table.insert(judged, id)
        table.insert(colors, judge.card.color)
      end
    end
  end

  if #judged == 2 then
    local cards = room:askToChooseCards(player, {
      target = player, flag = {card_data = {{self.name, judged}}},
      min = 1, max = 1, skill_name = self.name,
      prompt = "#fengsui_heg__quchi-top",
    })
    local top = cards[1] or judged[1]
    local bottom = top == judged[1] and judged[2] or judged[1]
    room:moveCards {
      ids = {top}, toArea = Card.DrawPile, drawPilePosition = 1,
      moveReason = fk.ReasonPut, skillName = self.name, moveVisible = true,
    }
    room:moveCards {
      ids = {bottom}, toArea = Card.DrawPile, drawPilePosition = -1,
      moveReason = fk.ReasonPut, skillName = self.name, moveVisible = true,
    }
    if colors[1] == colors[2] and not player.dead and
      U.getSkillPlace(player, self.name) == place then
      player:revealGeneral(place)
    end
  elseif #judged > 0 then
    room:moveCards {
      ids = judged, toArea = Card.DiscardPile,
      moveReason = fk.ReasonJudge, skillName = self.name,
    }
  end
end

for _, event in ipairs({fk.Damage, fk.Damaged}) do
  quchi:addEffect(event, {
    can_trigger = function(self, _, target, player)
      return target == player and player:hasSkill(self.name) and
        H.getGeneralsRevealedNum(player) == 2 and #player:getCardIds("he") >= 2
    end,
    on_cost = invoke,
    on_use = resolve,
  })
end

return quchi
