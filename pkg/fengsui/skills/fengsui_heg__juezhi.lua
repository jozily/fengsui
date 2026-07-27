local H = require "packages.hegemony.util"
local U = require "packages.hegemony.pkg.fengsui.util"

local juezhi = fk.CreateSkill{
  name = "fengsui_heg__juezhi",
}

juezhi:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#fengsui_heg__juezhi",
  can_use = function(self, player)
    return player:usedSkillTimes(juezhi.name, Player.HistoryPhase) == 0
  end,
  card_num = 0,
  target_num = 0,
  on_use = function(self, room, effect)
    local player = effect.from
    local kingdoms = {}
    for _, p in ipairs(room.alive_players) do
      local kingdom = H.getKingdom(p)
      if kingdom and kingdom ~= "unknown" then
        table.insertIfNeed(kingdoms, kingdom)
      end
    end

    local judge_cards = {}
    for _ = 1, math.max(#kingdoms, 1) do
      if player.dead then break end
      local judge = {
        who = player,
        reason = juezhi.name,
        pattern = ".",
      }
      room:judge(judge)
      if judge.card and judge.card.id then
        table.insert(judge_cards, judge.card.id)
      end
    end

    local pool = table.filter(judge_cards, function(id)
      return room:getCardArea(id) == Card.DiscardPile
    end)
    local chosen, suits, numbers = {}, {}, {}
    while #pool > 0 and not player.dead do
      local available = table.filter(pool, function(id)
        local card = Fk:getCardById(id)
        return not table.contains(suits, card.suit) and not table.contains(numbers, card.number)
      end)
      if #available == 0 then break end

      local selected = U.chooseCardsFromList(room, player, available, 1, 1,
        "#fengsui_heg__juezhi-choose", juezhi.name, true)
      if #selected == 0 then break end

      local id = selected[1]
      local card = Fk:getCardById(id)
      table.insert(chosen, id)
      table.insert(suits, card.suit)
      table.insert(numbers, card.number)
      table.removeOne(pool, id)
    end

    if #chosen > 0 then
      room:obtainCard(player, chosen, true, fk.ReasonPrey, player, juezhi.name)
    end
  end,
})

return juezhi
