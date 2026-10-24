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
    return true
  end,
  on_use = function(self, _, target, player, data)
    local room = player.room
    local card_name = data.card.trueName
    data.extraUse = true
    room:setPlayerMark(player, used_mark, player:getMark(used_mark) + 1)
    local names = player:getMark(name_mark)
    if type(names) ~= "string" then names = "" end
    if not string.find("|" .. names .. "|", "|" .. card_name .. "|", 1, true) then
      names = names == "" and card_name or (names .. "|" .. card_name)
      room:setPlayerMark(player, name_mark, names)
    end
    room:recastCard(Card:getIdList(data.card), player, xinyou.name)
    room.logic:breakEvent()
  end,
})

xinyou:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card)
    return player:hasShownSkill(xinyou.name) and card and card.type == Card.TypeBasic and
      player:getMark(used_mark) < player:getMark(count_mark)
  end,
})

xinyou:addEffect(fk.TurnEnd, {
  can_trigger = function(self, _, target, player)
    return target == player and player:hasShownSkill(xinyou.name) and
      player:getMark(used_mark) == 0 and H.allGeneralsRevealed(player)
  end,
  on_use = function(self, _, _, player)
    H.hideBySkillName(player, xinyou.name)
  end,
})

xinyou:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    local count = player:getMark(count_mark)
    if not player:hasShownSkill(xinyou.name) or not card or card.type ~= Card.TypeBasic then return false end
    if count == 0 then return true end
    if player:getMark(used_mark) < count then return false end
    local names = player:getMark(name_mark)
    return type(names) ~= "string" or not string.find("|" .. names .. "|", "|" .. card.trueName .. "|", 1, true)
  end,
})

return xinyou
