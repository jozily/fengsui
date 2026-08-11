local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local yuyuan = fk.CreateSkill{
  name = "fengsui_heg__yuyuan",
}

local function isFirstCardThisTurn(player)
  local events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 2, function(e)
    local use = e.data
    return use.from == player and
      (use.card.type == Card.TypeBasic or use.card:isCommonTrick())
  end, Player.HistoryTurn)
  return #events == 1
end

local function noDamageDealt(data)
  for _, damage in pairs(data.damageDealt or {}) do
    if damage and damage > 0 then return false end
  end
  return true
end

yuyuan:addEffect(fk.PreCardUse, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(yuyuan.name) or not isFirstCardThisTurn(player) then
      return false
    end
    local card = data.card
    if card.type ~= Card.TypeBasic and not card:isCommonTrick() then return false end
    if #data.tos ~= 1 then return false end
    return table.find(player.room.alive_players, function(p)
      return p ~= player and p.kingdom == "unknown" and not table.contains(data.tos, p)
    end) ~= nil
  end,
  on_cost = function(self, event, target, player, data)
    local candidates = table.filter(player.room.alive_players, function(p)
      return p ~= player and p.kingdom == "unknown" and not table.contains(data.tos, p)
    end)
    local chosen = player.room:askToChoosePlayers(player, {
      targets = candidates,
      min_num = 1,
      max_num = #candidates,
      prompt = "#fengsui_heg__yuyuan-extra",
      skill_name = yuyuan.name,
      cancelable = true,
    })
    if #chosen > 0 then
      event:setCostData(self, {tos = chosen})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.fengsui_heg__yuyuan_targets = {}
    for _, p in ipairs(event:getCostData(self).tos) do
      data:addTarget(p)
      table.insert(data.extra_data.fengsui_heg__yuyuan_targets, p.id)
    end
  end,
})

yuyuan:addEffect(fk.CardUseFinished, {
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(yuyuan.name) then return false end
    local ids = (data.extra_data or {}).fengsui_heg__yuyuan_targets
    if type(ids) ~= "table" or #ids == 0 or H.getGeneralsRevealedNum(player) < 2 then return false end
    return noDamageDealt(data)
  end,
  on_cost = function()
    return true
  end,
  on_use = function(self, event, target, player, data)
    U.hideSkillGeneral(player, yuyuan.name)
  end,
})

yuyuan:addTest(function(room, me)
  lu.assertTrue(noDamageDealt({ damageDealt = {} }))
  lu.assertFalse(noDamageDealt({ damageDealt = { [me.id] = 1 } }))
end)

Fk:loadTranslationTable{
  ["#fengsui_heg__yuyuan-extra"] = "逾垣：你可以额外指定任意名未确定势力角色为目标",
}

return yuyuan
