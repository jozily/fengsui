local H = require "packages.fengsui.hegemony_util"

local juezhi = fk.CreateSkill{
  name = "fengsui_heg__juezhi",
}

Fk:addPoxiMethod{
  name = "fengsui_heg__juezhi",
  prompt = "#fengsui_heg__juezhi-choose",
  card_filter = function(to_select, selected, data)
    local card = Fk:getCardById(to_select)
    return table.every(selected, function(id)
      local chosen = Fk:getCardById(id)
      return chosen.suit ~= card.suit and chosen.number ~= card.number
    end)
  end,
  feasible = Util.TrueFunc,
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
    local chosen = room:askToPoxi(player, {
      poxi_type = juezhi.name,
      data = {{juezhi.name, pool}},
      cancelable = true,
    })

    if #chosen > 0 then
      room:obtainCard(player, chosen, true, fk.ReasonPrey, player, juezhi.name)
    end
  end,
})

return juezhi
