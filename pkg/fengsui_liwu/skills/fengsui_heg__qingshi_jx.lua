local s = fk.CreateSkill {name = "fengsui_heg__qingshi_jx"}
s:addEffect(fk.TargetConfirmed, {
  can_trigger = function(self, _, target, player, data)
    return target == player and player:hasSkill(s.name) and player:getMark(s.name .. "-round") == 0 and
      data.from ~= player and data.card.color == Card.Black and not player:isNude()
  end,
  on_cost = function(self, event, _, player)
    local cards = player.room:askToDiscard(player, {min_num = 1, max_num = 1, include_equip = true,
      pattern = ".|.|black", skill_name = s.name, cancelable = true, skip = true})
    if #cards > 0 then event:setCostData(self, cards); return true end
  end,
  on_use = function(self, event, _, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self), s.name, player, player)
    local choice = room:askToChoice(player, {choices = {"fengsui_heg__qingshi_jx_nullify", "fengsui_heg__qingshi_jx_obtain"}, skill_name = s.name})
    if choice == "fengsui_heg__qingshi_jx_nullify" then
      room:setPlayerMark(player, s.name .. "-round", 1)
      data.use.nullifiedTargets = data.use.nullifiedTargets or {}
      table.insertIfNeed(data.use.nullifiedTargets, player)
    else
      local ids = Card:getIdList(data.card)
      local useEvent = room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
      if useEvent then useEvent:addExitFunc(function()
        if player.dead then return end
        local obtainable = table.filter(ids, function(id) return room:getCardArea(id) == Card.DiscardPile end)
        if #obtainable > 0 then room:obtainCard(player, obtainable, true, fk.ReasonPrey, player, s.name) end
      end) end
    end
  end,
})
s:addEffect("invalidity", {
  invalidity_func = function(self, from, skill)
    return skill.name == s.name and from:getMark(s.name .. "-round") > 0
  end,
})
Fk:loadTranslationTable{
  ["fengsui_heg__qingshi_jx_nullify"] = "令此牌对你无效且本轮清饰失效",
  ["fengsui_heg__qingshi_jx_obtain"] = "此牌结算完毕后从弃牌堆获得之",
}
return s
