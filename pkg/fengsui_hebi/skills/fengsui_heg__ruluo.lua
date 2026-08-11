local H = require "packages.fengsui.hegemony_util"

local ruluo = fk.CreateSkill{
  name = "fengsui_heg__ruluo",
  related_skills = {"heg__xiace", "ld__qice"},
}

local gained_mark = "fengsui_heg__ruluo_gained"

ruluo:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play and player:hasSkill(ruluo.name)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = ruluo.name,
      prompt = "#fengsui_heg__ruluo-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(H.getGeneralsRevealedNum(player), ruluo.name)
    if player.dead then return end
    local hand = player:getCardIds("h")
    if #hand > 0 then room:showCards(hand, player) end
    local basic = #table.filter(hand, function(id) return Fk:getCardById(id).type == Card.TypeBasic end)
    local trick = #table.filter(hand, function(id) return Fk:getCardById(id).type == Card.TypeTrick end)
    local skill_name
    if basic > trick then skill_name = "heg__xiace" end
    if basic < trick then skill_name = "ld__qice" end
    if skill_name then
      room:handleAddLoseSkills(player, skill_name)
      room:addTableMarkIfNeed(player, gained_mark, skill_name)
      room:setPlayerMark(player, "@fengsui_heg__ruluo-round", skill_name)
    end
  end,
})

ruluo:addEffect(fk.TurnStart, {
  global = true,
  mute = true,
  can_refresh = function(self, event, target, player, data)
    return #player:getTableMark(gained_mark) > 0 and player:getMark("@fengsui_heg__ruluo-round") == 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, skill_name in ipairs(player:getTableMark(gained_mark)) do
      room:handleAddLoseSkills(player, "-" .. skill_name)
    end
    room:setPlayerMark(player, gained_mark, 0)
  end,
})

return ruluo
