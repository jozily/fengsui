local U = require "packages.fengsui.pkg.fengsui_hebi.util"
local heyi = fk.CreateSkill { name = "fengsui_heg__heyi" }

local function replaceCard(player)
  local room = player.room
  local top, bottom = room.draw_pile[1], room.draw_pile[#room.draw_pile]
  if not top or not bottom then return end
  local candidates = top == bottom and { top } or { top, bottom }
  room:showCards(candidates, player)

  -- 展示的两张由自己挑一张获得，不再按「造成伤害拿顶、受到伤害拿底」写死。
  -- 只能从已展示的牌里选，避免选到牌堆中其它牌。
  local gainId = U.chooseCardsFromList(room, player, candidates, 1, 1,
    "#fengsui_heg__heyi-gain", heyi.name, false)[1]
  if not gainId then return end
  room:obtainCard(player, gainId, true, fk.ReasonPrey, player, heyi.name)

  local replaceId, replaceTop
  if gainId == top then
    replaceId, replaceTop = bottom, false
  else
    replaceId, replaceTop = top, true
  end
  if not replaceId or replaceId == gainId or
    room:getCardArea(replaceId) ~= Card.DrawPile then return end

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
  return player:getMark(mark) == 0
end

heyi:addEffect(fk.Damage, {
  can_trigger = function(self, _, target, player)
    return target == player and player:hasSkill(heyi.name) and canTrigger(player, "fengsui_heg__heyi_out-round")
  end,
  on_cost = function(self, _, _, player)
    return player.room:askToSkillInvoke(player, { skill_name = heyi.name, prompt = "#fengsui_heg__heyi-invoke" })
  end,
  on_use = function(self, _, _, player)
    player.room:setPlayerMark(player, "fengsui_heg__heyi_out-round", 1)
    replaceCard(player)
  end,
})

heyi:addEffect(fk.Damaged, {
  can_trigger = function(self, _, target, player)
    return target == player and player:hasSkill(heyi.name) and canTrigger(player, "fengsui_heg__heyi_in-round")
  end,
  on_cost = function(self, _, _, player)
    return player.room:askToSkillInvoke(player, { skill_name = heyi.name, prompt = "#fengsui_heg__heyi-invoke" })
  end,
  on_use = function(self, _, _, player)
    player.room:setPlayerMark(player, "fengsui_heg__heyi_in-round", 1)
    replaceCard(player)
  end,
})

return heyi
