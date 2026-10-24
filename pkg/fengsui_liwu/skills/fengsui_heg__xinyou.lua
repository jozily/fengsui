local H = require "packages.fengsui.hegemony_util"

local xinyou = fk.CreateSkill {
  name = "fengsui_heg__xinyou",
  tags = { Skill.Compulsory },
}

local count_mark = "fengsui_heg__xinyou_count"
local used_mark = "fengsui_heg__xinyou_used-turn"
local name_mark = "fengsui_heg__xinyou_name-turn"
local visible_mark = "@fengsui_heg__xinyou"

local function updateVisible(room, player)
  room:setPlayerMark(player, visible_mark, tostring(player:getMark(count_mark)))
end

xinyou:addEffect(fk.GeneralRevealed, {
  can_refresh = function(self, _, target, player)
    return target == player and player:hasShownSkill(xinyou.name) and
      player:getMark(visible_mark) == 0
  end,
  on_refresh = function(self, _, target, player)
    local room = player.room
    if player:getMark(count_mark) == 0 then room:setPlayerMark(player, count_mark, 0) end
    updateVisible(room, player)
  end,
})

xinyou:addEffect(fk.TurnStart, {
  can_refresh = function(self, _, target, player)
    return target == player and player:hasShownSkill(xinyou.name)
  end,
  on_refresh = function(self, _, target, player)
    player.room:setPlayerMark(player, used_mark, 0)
    player.room:setPlayerMark(player, name_mark, 0)
  end,
})

xinyou:addEffect(fk.PreCardUse, {
  can_trigger = function(self, _, target, player, data)
    if target ~= player or not player:hasShownSkill(xinyou.name) or not data.card or
        data.card.type ~= Card.TypeBasic then return false end
    local limit = player:getMark(count_mark)
    local used = player:getMark(used_mark)
    if limit <= used or #Card:getIdList(data.card) == 0 then return false end
    local locked = player:getMark(name_mark)
    return locked == 0 or locked == data.card.trueName
  end,
  on_use = function(self, _, target, player, data)
    local room = player.room
    local card_name = data.card.trueName
    room:setPlayerMark(player, used_mark, player:getMark(used_mark) + 1)
    if player:getMark(name_mark) == 0 then room:setPlayerMark(player, name_mark, card_name) end
    room:recastCard(Card:getIdList(data.card), player, xinyou.name)
    room.logic:breakEvent()
  end,
})

xinyou:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    local locked = player:getMark(name_mark)
    local count = player:getMark(count_mark)
    if not player:hasShownSkill(xinyou.name) or not card or card.type ~= Card.TypeBasic then return false end
    if count == 0 then return true end
    return locked ~= 0 and card.trueName ~= locked
  end,
})

return xinyou
