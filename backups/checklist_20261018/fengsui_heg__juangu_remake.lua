local H = require "packages.fengsui.hegemony_util"

local juangu = fk.CreateSkill{
  name = "fengsui_heg__juangu",
}

local used_mark = "fengsui_heg__juangu_used-turn"

local function isEligibleCard(card)
  return card and (card.type == Card.TypeBasic or card:isCommonTrick())
end

local function hasCompanionAcross(from, to)
  local from_generals = {H.getActualGeneral(from, false), H.getActualGeneral(from, true)}
  local to_generals = {H.getActualGeneral(to, false), H.getActualGeneral(to, true)}
  for _, first in ipairs(from_generals) do
    local general = Fk.generals[first]
    if general then
      for _, second in ipairs(to_generals) do
        local other = Fk.generals[second]
        if other and (general:isCompanionWith(other) or other:isCompanionWith(general)) then
          return true
        end
      end
    end
  end
  return false
end

juangu:addEffect(fk.TargetSpecified, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if not target or not isEligibleCard(data.card) or not data.to or not player:hasSkill(juangu.name) or
      target.room.current ~= target or
      table.contains(player:getTableMark(used_mark), target.id) or
      #data:getAllTargets() ~= 1 then
      return false
    end
    return hasCompanionAcross(target, data.to)
  end,
  on_cost = function(self, event, target, player, data)
    player.room:addTableMarkIfNeed(player, used_mark, target.id)
    return player.room:askToSkillInvoke(player, {
      skill_name = juangu.name,
      prompt = "#fengsui_heg__juangu-invoke::" .. target.id .. ":" .. data.to.id,
    })
  end,
  on_use = function(self, event, target, player, data)
    if target == data.to then
      data.use.additionalEffect = (data.use.additionalEffect or 0) + 1
    else
      if target:isAlive() then target:drawCards(1, juangu.name) end
      if data.to:isAlive() then data.to:drawCards(1, juangu.name) end
    end
  end,
})

juangu:addTest(function(room, me)
  lu.assertTrue(isEligibleCard(Fk:cloneCard("slash")))
  lu.assertTrue(isEligibleCard(Fk:cloneCard("duel")))
  lu.assertFalse(isEligibleCard(Fk:cloneCard("crossbow")))
  lu.assertFalse(isEligibleCard(Fk:cloneCard("indulgence")))
end)

return juangu
