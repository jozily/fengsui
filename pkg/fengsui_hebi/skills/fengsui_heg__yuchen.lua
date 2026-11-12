local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local yuchen = fk.CreateSkill { name = "fengsui_heg__yuchen" }
local bonus_mark = "fengsui_heg__yuchen_bonus"
local reuse_mark = "fengsui_heg__yuchen_reuse-turn"

-- 新版：同势力角色使用单体伤害牌指定他人后，弃一张同花色的牌令此牌伤害+1；
-- 若此牌未造成伤害，原目标视为对技能拥有者使用此牌且伤害+1。
local function sameSuitCards(player, suit)
  return table.filter(player:getCardIds("he"), function(id)
    return Fk:getCardById(id).suit == suit
  end)
end

yuchen:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(yuchen.name) or player:getMark(reuse_mark) > 0 then return false end
    if not data or not data.card or not data.card.is_damage_card or not data.from then return false end
    if not data.use or #data.use.tos ~= 1 then return false end
    local to = data.to
    if not to or to == data.from or not to:isAlive() then return false end
    if not H.compareKingdomWith(data.from, player) then return false end
    if data.card:getMark(bonus_mark) > 0 then return false end
    return #sameSuitCards(player, data.card.suit) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = sameSuitCards(player, data.card.suit)
    cards = U.chooseCardsFromList(room, player, cards, 1, 1,
      "#fengsui_heg__yuchen-invoke", yuchen.name, true)
    if #cards > 0 then
      event:setCostData(self, { cards = cards })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, yuchen.name, player, player)
    data.card:setMark(bonus_mark, 1)
  end,
})

yuchen:addEffect(fk.DamageCaused, {
  global = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yuchen.name) and data and data.card and
      (data.card:getMark(bonus_mark) > 0 or player:getMark(reuse_mark) > 0)
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
})

yuchen:addEffect(fk.CardUseFinished, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yuchen.name) and data and data.card and
      data.card:getMark(bonus_mark) > 0 and player:getMark(reuse_mark) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local dealt = 0
    if data.damageDealt then
      for _, n in pairs(data.damageDealt) do dealt = dealt + (tonumber(n) or 0) end
    end
    if dealt > 0 then return end
    local origin = data.tos and data.tos[1]
    if not origin or not origin:isAlive() or not player:isAlive() then return end
    local cardName = data.card.name
    if not cardName then return end
    -- reuse_mark 同时兼作「伤害+1」标记与递归保护：反打的牌在 TargetSpecified
    -- 阶段会被跳过，DamageCaused 阶段据此 +1；调用返回后即清除。
    room:setPlayerMark(player, reuse_mark, 1)
    room:useVirtualCard(cardName, nil, origin, player, yuchen.name, true)
    room:setPlayerMark(player, reuse_mark, 0)
  end,
})

Fk:loadTranslationTable {
  ["fengsui_heg__yuchen"] = "毓尘",
  [":fengsui_heg__yuchen"] = "当一名同势力角色使用单体伤害牌指定其他角色后，你可以弃置一张同花色的牌令此牌伤害+1，若此牌未造成伤害，原目标视为对你使用此牌且伤害+1。",
  ["#fengsui_heg__yuchen-invoke"] = "毓尘：请选择一张与此牌花色相同的牌弃置",
}

return yuchen
