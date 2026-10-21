local H = require "packages.fengsui.hegemony_util"

local dexiang = fk.CreateSkill{
  name = "fengsui_heg__dexiang",
}

local function eligiblePlayers(owner, data)
  local from = data.from
  if not from then return {} end
  local extra_targets = data:getExtraTargets()
  return table.filter(owner.room.alive_players, function(p)
    return H.compareKingdomWith(p, owner) and p:distanceTo(from) <= 1 and
      not table.contains(data.use.tos, p) and H.allGeneralsRevealed(p) and
      table.contains(extra_targets, p)
  end)
end

dexiang:addEffect(fk.TargetSpecified, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(dexiang.name) and
      (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and
      #data.use.tos == 1 and #eligiblePlayers(player, data) > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local candidates = eligiblePlayers(player, data)
    room:sortByAction(candidates)
    for _, p in ipairs(candidates) do
      if p:isAlive() and not table.contains(data.use.tos, p) and
        table.contains(data:getExtraTargets(), p) and
        room:askToSkillInvoke(p, {
          skill_name = dexiang.name,
          prompt = "#fengsui_heg__dexiang-invoke:::" .. data.card:toLogString(),
        }) then
        H.doHideGeneral(room, p, p, dexiang.name)
        data:addTarget(p)
      end
    end
  end,
})

return dexiang
