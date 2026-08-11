local H = require "packages.fengsui.hegemony_util"

local laoyan = fk.CreateSkill{
  name = "fengsui_heg__laoyan",
  tags = { Skill.Compulsory },
}

local function noTargetDamaged(data)
  for _, damage in pairs(data.damageDealt or {}) do
    if damage and damage > 0 then return false end
  end
  return true
end

laoyan:addEffect(fk.CardUsing, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(laoyan.name) and target ~= player and data.card and #data.tos > 1 and
      table.contains(data.tos, player) and #player:getCardIds("he") >= 2
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:askToDiscard(player, {
      min_num = 2,
      max_num = 2,
      include_equip = true,
      skill_name = laoyan.name,
      cancelable = false,
      prompt = "#fengsui_heg__laoyan-discard",
    })
    data.extra_data = data.extra_data or {}
    data.extra_data.fengsui_heg__laoyan_triggers = data.extra_data.fengsui_heg__laoyan_triggers or {}
    table.insertIfNeed(data.extra_data.fengsui_heg__laoyan_triggers, player.id)

    local team = table.filter(data.tos, function(p)
      return p ~= player and H.compareKingdomWith(p, player)
    end)
    if #team > 0 then
      data.nullifiedTargets = data.nullifiedTargets or {}
      table.insertTableIfNeed(data.nullifiedTargets, team)
    end
  end,
})

laoyan:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    local triggers = (data.extra_data or {}).fengsui_heg__laoyan_triggers
    return type(triggers) == "table" and table.contains(triggers, player.id) and noTargetDamaged(data)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, laoyan.name)
  end,
})

laoyan:addTest(function(room, me)
  lu.assertTrue(noTargetDamaged({}))
  lu.assertTrue(noTargetDamaged({ damageDealt = {} }))
  lu.assertFalse(noTargetDamaged({ damageDealt = { [me.id] = 1 } }))
end)

return laoyan
