local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local juanzhi = fk.CreateSkill{
  name = "fengsui_heg__juanzhiRemake",
}

juanzhi:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(juanzhi.name) and target.phase == Player.Start and H.compareKingdomWith(target, player)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = player:getCardIds("he")
    if #cards == 0 then return false end
    local cid = U.chooseCardsFromList(room, player, cards, 1, 1,
      "#fengsui_heg__juanzhiRemake-recast", juanzhi.name, true)
    if #cid > 0 then
      event:setCostData(self, { card_id = cid[1] })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cid = event:getCostData(self).card_id
    local card = Fk:getCardById(cid)
    local cType = card.type
    room:recastCard(cid, player, juanzhi.name)
    room:setPlayerMark(player, "fengsui_heg__juanzhiRemake_type_" .. cType .. "-turn", 1)
    room:addTableMarkIfNeed(player, "@fengsui_heg__juanzhiRemake-turn", card.trueName)
  end,
})

juanzhi:addEffect(fk.TargetConfirmed, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(juanzhi.name) and data.card then
      return player:getMark("fengsui_heg__juanzhiRemake_type_" .. data.card.type .. "-turn") > 0
    end
    return false
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local same_count = #table.filter(room.alive_players, function(p) return H.compareKingdomWith(p, player) end)
    if same_count == 0 then return false end

    local available_tos = table.filter(room.alive_players, function(p)
      return not table.contains(data.tos, p) and not data.from:isProhibited(p, data.card) and
        data.card.skill:modTargetFilter(data.from, p, data.tos, data.card, {})
    end)
    if #available_tos == 0 then return false end

    local tos = room:askToChoosePlayers(player, {
       targets = available_tos,
       min_num = 1, max_num = same_count,
       prompt = "#fengsui_heg__juanzhiRemake-targets:::" .. same_count,
       skill_name = juanzhi.name,
       cancelable = true,
    })
    if #tos > 0 then
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local extra_tos = event:getCostData(self).tos
    for _, to in ipairs(extra_tos) do
      data:addTarget(to)
      room:sendLog{
        type = "#UseCardAddTarget",
        toast = true,
        arg = data.card.name,
        from = data.from.id,
        to = {to.id},
      }
    end
  end,
})

return juanzhi
