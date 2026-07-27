local H = require "packages.hegemony.util"
local U = require "packages.hegemony.pkg.fengsui.util"

local yuyuan = fk.CreateSkill{
  name = "fengsui_heg__yuyuan",
}

yuyuan:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(yuyuan.name) or #data.tos ~= 1 then return false end
    if data.card.type ~= Card.TypeBasic and not data.card:isCommonTrick() then return false end

    local uses = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
      local use = e.data
      return use.from == player and #use.tos == 1 and
        (use.card.type == Card.TypeBasic or use.card:isCommonTrick())
    end, Player.HistoryTurn)
    if #uses ~= 1 or uses[1].data ~= data then return false end

    return table.find(data:getExtraTargets(), function(p) return p.kingdom == "unknown" end) ~= nil
  end,
  on_cost = function(self, event, target, player, data)
    local targets = table.filter(data:getExtraTargets(), function(p) return p.kingdom == "unknown" end)
    local tos = player.room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = #targets,
      prompt = "#fengsui_heg__yuyuan-extra:::" .. data.card:toLogString(),
      skill_name = yuyuan.name,
      cancelable = true,
    })
    if #tos > 0 then
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    for _, to in ipairs(event:getCostData(self).tos) do
      data:addTarget(to)
    end
    data.extra_data = data.extra_data or {}
    data.extra_data.fengsui_heg__yuyuan = table.simpleClone(event:getCostData(self).tos)
  end,
})

yuyuan:addEffect(fk.CardUseFinished, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    local added = (data.extra_data or {}).fengsui_heg__yuyuan
    return target == player and player:hasSkill(yuyuan.name) and type(added) == "table" and
      H.allGeneralsRevealed(player) and table.every(added, function(p)
        return not (data.damageDealt and data.damageDealt[p])
      end)
  end,
  on_use = function(self, event, target, player, data)
    U.hideSkillGeneral(player, yuyuan.name)
  end,
})

return yuyuan
