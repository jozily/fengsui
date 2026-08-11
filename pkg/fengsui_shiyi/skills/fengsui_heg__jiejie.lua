local fengsui_heg__jiejie = fk.CreateSkill{
  name = "fengsui_heg__jiejie",
  attached_skill_name = "fengsui_heg__jiejie&",
  max_branches_use_time = {
    ["fengsui_heg__jiejie_most"] = {
      [Player.HistoryRound] = 2,
    },
  },
}

Fk:loadTranslationTable{
  ["fengsui_heg__jiejie"] = "诫节",
  [":fengsui_heg__jiejie"] = "每名角色的出牌阶段限一次，当前回合角色可以令你观看其手牌，然后你可以选择一种花色，若其手牌："..
  "包含此花色，其本回合使用此花色的牌无次数限制，然后弃置其余花色的手牌；不包含此花色，其从牌堆或弃牌堆中随机获得此花色的一张牌。"..
  "每轮限两次，若其本轮以此法令你观看的牌所包含的花色为唯一最多，你视为对其发动一次〖清识〗。",

  ["#fengsui_heg__jiejie"] = "诫节：观看你的手牌，然后选择一种花色，根据是否包含此花色执行效果",
  ["#fengsui_heg__jiejie-choice"] = "诫节：选择一种花色，包含此花色则其弃置其他花色手牌，否则其获得一张此花色牌",
  ["@fengsui_heg__jiejie-round"] = "诫节",

  ["$fengsui_heg__jiejie1"] = "职守，人之大义也，安可不出？",
  ["$fengsui_heg__jiejie2"] = "为人执鞭而弃其事，不祥，不可也。",
  ["$fengsui_heg__jiejie3"] = "军旅之间可以济者，唯仁与恕。",
  ["$fengsui_heg__jiejie4"] = "在职思其所司，在义思其所立。",
}

local function findSkillOwner(skill_name)
  return table.filter(Fk:currentRoom().alive_players, function (p)
    return p:hasSkill(skill_name) and p:usedSkillTimes(skill_name, Player.HistoryPhase) == 0
  end)
end

fengsui_heg__jiejie:addEffect("active", {
  anim_type = "control",
  prompt = "#fengsui_heg__jiejie",
  card_num = 0,
  min_target_num = 0,
  max_target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng() and #findSkillOwner(fengsui_heg__jiejie.name) > 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function (self, player, to_select, selected)
    if #findSkillOwner(fengsui_heg__jiejie.name) == 1 then
      return false
    else
      return #selected == 0 and table.contains(findSkillOwner(fengsui_heg__jiejie.name), to_select)
    end
  end,
  feasible = function (self, player, selected)
    if #findSkillOwner(fengsui_heg__jiejie.name) == 1 then
      return #selected == 0
    else
      return #selected == 1
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target
    if #effect.tos > 0 then
      target = effect.tos[1]
      target:addSkillUseHistory(fengsui_heg__jiejie.name, 1)
    else
      target = player
    end
    local suits = {}
    for _, id in ipairs(player:getCardIds("h")) do
      table.insertIfNeed(suits, Fk:getCardById(id).suit)
    end
    table.removeOne(suits, Card.NoSuit)
    local yes = #suits > target:getMark("@fengsui_heg__jiejie-round")
    if yes then
      room:setPlayerMark(target, "@fengsui_heg__jiejie-round", #suits)
    end
    local choice = room:askToViewCardsAndChoice(target, {
      cards = player:getCardIds("h"),
      choices = { "log_spade", "log_heart", "log_club", "log_diamond", "Cancel" },
      skill_name = fengsui_heg__jiejie.name,
      prompt = "#fengsui_heg__jiejie-choice::"..player.id,
    })
    if choice ~= "Cancel" then
      if table.find(player:getCardIds("h"), function (id)
        return Fk:getCardById(id):getSuitString(true) == choice
      end) then
        local others = table.filter(player:getCardIds("h"), function (id)
          return Fk:getCardById(id):getSuitString(true) ~= choice and not player:prohibitDiscard(id)
        end)
        if #others > 0 then
          room:throwCard(others, fengsui_heg__jiejie.name, player, player)
        end
        if not player.dead then
          room:addTableMarkIfNeed(player, "fengsui_heg__jiejie-turn", choice)
        end
      else
        local card = room:getCardsFromPileByRule(".|.|" .. string.sub(choice, 5))
        if #card == 0 then
          card = room:getCardsFromPileByRule(".|.|" .. string.sub(choice, 5), 1, "discardPile")
        end
        if #card > 0 then
          room:obtainCard(player, card, false, fk.ReasonPrey, player, fengsui_heg__jiejie.name)
        end
      end
    end
    if
      yes and
      not player.dead and
      not target.dead and
      fengsui_heg__jiejie:withinBranchTimesLimit(player, "fengsui_heg__jiejie_most", Player.HistoryRound)
    then
      player:addSkillBranchUseHistory(fengsui_heg__jiejie.name, "fengsui_heg__jiejie_most", 1)
      local skill = Fk.skills["fengsui_heg__qingshi"]
      local event = fk.Damaged:new(room, target, {})
      event:setCostData(skill, {tos = {player}})
      skill:use(event, target, target, {})
    end
  end,
})

fengsui_heg__jiejie:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and table.contains(player:getTableMark("fengsui_heg__jiejie-turn"), data.card:getSuitString(true))
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
})

fengsui_heg__jiejie:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card)
    local mark = player:getTableMark("fengsui_heg__jiejie-turn")
    if #mark > 0 then
      return card and card:matchVSPattern(".|.|" ..
        table.concat(table.map(mark, function(suit) return string.sub(suit, 5) end), ","))
    end
  end,
})

return fengsui_heg__jiejie
