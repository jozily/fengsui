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
    local team = {}
    for _, p in ipairs(data.tos) do
       if p ~= player and H.compareKingdomWith(p, player) then table.insert(team, p) end
    end
    if #team > 0 then
      data.nullifiedTargets = data.nullifiedTargets or {}
      table.insertTableIfNeed(data.nullifiedTargets, team)
    end
  end,
})

laoyan:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if data.extra_data and data.extra_data.laoyan_trigger == player.id then
       -- 判断是否没受到伤害
       local hurt = false
       if data.damageDealt and data.damageDealt[player] and data.damageDealt[player] > 0 then hurt = true end
       return not hurt and target ~= player
    end
    return false
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
