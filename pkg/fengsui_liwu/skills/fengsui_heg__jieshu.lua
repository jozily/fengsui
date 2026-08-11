local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local jieshu = fk.CreateSkill{
  name = "fengsui_heg__jieshu",
}

local function isCurio(card)
  return card and card.type == Card.TypeEquip and card.package and card.package.name == "nine_variations"
end

jieshu:addEffect(fk.CardUseFinished, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(jieshu.name) or player:getMark("@fengsui_heg__jieshu") > 0 or
      player.room.current == nil or (data.extra_data and data.extra_data.fengsui_heg__jieshu_cleared) then return false end
    local n = #data.tos
    if n == 0 then return false end
    return table.find(U.getNationalCardNames({ "trick" }), function(name)
      return U.getLegalTargetNum(player, Fk:cloneCard(name)) >= n
    end) ~= nil
  end,
  on_cost = function(self, event, target, player, data)
    local n = #data.tos
    local names = table.filter(U.getNationalCardNames({ "trick" }), function(name)
      return U.getLegalTargetNum(player, Fk:cloneCard(name)) >= n
    end)
    local room = player.room
    room:setPlayerMark(player, "fengsui_heg__jieshu_target_num", n)
    local use
    repeat
      use = room:askToUseVirtualCard(player, {
        name = names,
        skill_name = jieshu.name,
        prompt = "#fengsui_heg__jieshu:::" .. n,
        cancelable = true,
        skip = true,
        extra_data = { bypass_times = true },
      })
    until not use or #use.tos == n
    room:setPlayerMark(player, "fengsui_heg__jieshu_target_num", 0)
    if use then
      event:setCostData(self, { use = use, n = n })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local cost = event:getCostData(self)
    player.room:setPlayerMark(player, "@fengsui_heg__jieshu", cost.n)
    cost.use.extraUse = true
    player.room:useCard(cost.use)
  end,
})

jieshu:addEffect("targetmod", {
  extra_target_func = function(self, player, skill, card)
    if card and table.contains(card.skillNames, jieshu.name) then
      return player:getMark("fengsui_heg__jieshu_target_num")
    end
    return 0
  end,
})

jieshu:addEffect(fk.CardUseFinished, {
  can_refresh = function(self, event, target, player, data)
    local n = player:getMark("@fengsui_heg__jieshu")
    return target == player and n > 0 and not data.card:isVirtual() and #data.tos == n
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@fengsui_heg__jieshu", 0)
    data.extra_data = data.extra_data or {}
    data.extra_data.fengsui_heg__jieshu_cleared = true
  end,
})

jieshu:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    if player:getMark("@fengsui_heg__jieshu") == 0 then return false end
    return table.find(data, function(move)
      return move.to == player and move.toArea == Card.PlayerHand and table.find(move.moveInfo, function(info)
        return isCurio(Fk:getCardById(info.cardId))
      end)
    end) ~= nil
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@fengsui_heg__jieshu", 0)
  end,
})

return jieshu
