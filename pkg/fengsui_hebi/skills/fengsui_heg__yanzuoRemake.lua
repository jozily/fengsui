local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local yanzuo = fk.CreateSkill{
  name = "fengsui_heg__yanzuoRemake",
}

yanzuo:addEffect("active", {
  anim_type = "offensive",
  prompt = "#fengsui_heg__yanzuoRemake",
  min_card_num = 2,
  max_card_num = 999,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(yanzuo.name, Player.HistoryPhase) == 0 and
      #player:getCardIds("he") >= 2
  end,
  card_filter = function(self, player, to_select, selected)
    if not table.contains(player:getCardIds("he"), to_select) then return false end
    return #selected == 0 or Fk:getCardById(to_select).type == Fk:getCardById(selected[1]).type
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local cards = effect.cards
    if #cards < 2 then return end

    local card_type = Fk:getCardById(cards[1]).type
    room:recastCard(cards, player, yanzuo.name)
    if player.dead or card_type == Card.TypeEquip then return end

    local names = table.filter(U.getNationalCardNames({"basic", "trick"}), function(name)
      local card = Fk:cloneCard(name)
      if card.type ~= card_type then return false end
      card:addSubcards(cards)
      card.skillName = yanzuo.name
      return U.getLegalTargetNum(player, card) >= #cards
    end)
    if #names == 0 then return end

    room:setPlayerMark(player, "fengsui_heg__yanzuoRemake_target_num", #cards)
    local use
    repeat
      use = room:askToUseVirtualCard(player, {
        name = names,
        skill_name = yanzuo.name,
        prompt = "#fengsui_heg__yanzuoRemake-name:::" .. #cards,
        cancelable = true,
        skip = true,
        extra_data = {
          bypass_distances = true,
          bypass_times = true,
        },
      })
    until not use or #use.tos == #cards
    room:setPlayerMark(player, "fengsui_heg__yanzuoRemake_target_num", 0)

    if use then
      use.extraUse = true
      room:useCard(use)
    end
  end,
})

yanzuo:addEffect("targetmod", {
  bypass_distances = function(self, player, card_skill, card, to)
    return card and table.contains(card.skillNames, yanzuo.name)
  end,
  extra_target_func = function(self, player, card_skill, card)
    if card and table.contains(card.skillNames, yanzuo.name) then
      return player:getMark("fengsui_heg__yanzuoRemake_target_num")
    end
    return 0
  end,
})

return yanzuo
