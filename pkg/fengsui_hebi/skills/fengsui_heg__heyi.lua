local heyi = fk.CreateSkill { name = "fengsui_heg__heyi" }

local function replaceCard(player, gainTop)
  local room = player.room
  local top, bottom = room.draw_pile[1], room.draw_pile[#room.draw_pile]
  if not top or not bottom or top == bottom then return end
  room:showCards({ top, bottom }, player)
  local gainId, replaceId, replaceTop
  if gainTop then gainId, replaceId, replaceTop = top, bottom, false
  else gainId, replaceId, replaceTop = bottom, top, true end
  room:obtainCard(player, gainId, true, fk.ReasonPrey, player, heyi.name)
  if room:getCardArea(replaceId) ~= Card.DrawPile then return end
  local id = room:askToChooseCard(player, {
    target = player, flag = "he", skill_name = heyi.name,
    prompt = "#fengsui_heg__heyi-replace",
  })
  if not id then return end
  room:moveCardTo(id, Card.DrawPile, nil, fk.ReasonPut, heyi.name, nil, true, player)
  table.removeOne(room.draw_pile, id)
  if replaceTop then table.insert(room.draw_pile, 1, id) else table.insert(room.draw_pile, id) end
end

local function canTrigger(player, mark)
  return player:hasShownSkill(heyi.name) and player:getMark(mark) == 0
end

heyi:addEffect(fk.Damage, {
  can_trigger = function(self, _, target, player)
    return target == player and canTrigger(player, "fengsui_heg__heyi_out-round")
  end,
  on_cost = function(self, _, _, player)
    return player.room:askToSkillInvoke(player, { skill_name = heyi.name, prompt = "#fengsui_heg__heyi-invoke" })
  end,
  on_use = function(self, _, _, player)
    player.room:setPlayerMark(player, "fengsui_heg__heyi_out-round", 1)
    replaceCard(player, true)
  end,
})

heyi:addEffect(fk.Damaged, {
  can_trigger = function(self, _, target, player)
    return target == player and canTrigger(player, "fengsui_heg__heyi_in-round")
  end,
  on_cost = function(self, _, _, player)
    return player.room:askToSkillInvoke(player, { skill_name = heyi.name, prompt = "#fengsui_heg__heyi-invoke" })
  end,
  on_use = function(self, _, _, player)
    player.room:setPlayerMark(player, "fengsui_heg__heyi_in-round", 1)
    replaceCard(player, false)
  end,
})

return heyi
