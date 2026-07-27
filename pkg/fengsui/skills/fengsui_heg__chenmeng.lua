local H = require "packages.hegemony.util"

local chenmeng = fk.CreateSkill{
  name = "fengsui_heg__chenmeng",
}

local heg_marks = {
  ["@!!vanguard"] = "vanguard",
  ["@!!yinyangfish"] = "yinyangfish",
  ["@!!companion"] = "companion",
  ["@!!wild"] = "wild",
}

chenmeng:addEffect("active", {
  global = true,
  anim_type = "support",
  prompt = "#fengsui_heg__chenmeng",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return not player:isKongcheng() and
      table.find(player.room.alive_players, function(owner)
        return owner:hasSkill(chenmeng.name) and H.compareKingdomWith(owner, player)
      end) ~= nil and
      table.find(player:getMarkNames(), function(name)
        return heg_marks[name] and player:getMark(name) > 0
      end) ~= nil and player:usedSkillTimes(chenmeng.name, Player.HistoryPhase) == 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local choices = table.filter(player:getMarkNames(), function(name)
      return heg_marks[name] and player:getMark(name) > 0
    end)
    local choice = room:askToChoice(player, {
      choices = choices,
      prompt = "#fengsui_heg__chenmeng-mark",
      skill_name = chenmeng.name,
    })
    local hand = room:askToChooseCard(player, {
      target = player,
      flag = "h",
      prompt = "#fengsui_heg__chenmeng-exchange",
      skill_name = chenmeng.name,
    })
    local top = room:getNCards(1)[1]
    if not hand or not top then return end
    H.removeHegMark(room, player, heg_marks[choice], 1)
    room:moveCards({
      ids = {hand},
      from = player,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonPut,
      skillName = chenmeng.name,
      drawPilePosition = 1,
      moveVisible = false,
    })
    room:obtainCard(player, top, true, fk.ReasonPrey, player, chenmeng.name)
    room:setPlayerMark(player, "fengsui_heg__chenmeng_used-turn", 1)
  end,
})

chenmeng:addEffect(fk.TurnEnd, {
  global = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("fengsui_heg__chenmeng_used-turn") > 0 and
      table.every(player:getMarkNames(), function(name)
        return not heg_marks[name] or player:getMark(name) == 0
      end)
  end,
  on_use = function(self, event, target, player, data)
    H.addHegMark(player, "yinyangfish")
  end,
})

return chenmeng
