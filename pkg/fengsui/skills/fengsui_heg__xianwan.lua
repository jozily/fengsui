local H = require "packages.hegemony.util"
local U = require "packages.hegemony.pkg.fengsui.util"

local xianwan = fk.CreateSkill{
  name = "fengsui_heg__xianwan",
}

local function matches(pattern, name)
  return pattern and (pattern == name or string.find(pattern, name, 1, true) ~= nil)
end

xianwan:addEffect(fk.AskForCardUse, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xianwan.name) and
      H.allGeneralsRevealed(player) and matches(data.pattern, "slash")
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = xianwan.name,
      prompt = "#fengsui_heg__xianwan-slash",
    })
  end,
  on_use = function(self, event, target, player, data)
    U.hideSkillGeneral(player, xianwan.name)
    local card = Fk:cloneCard("slash")
    card.skillName = xianwan.name
    data.result = { from = player, tos = {}, card = card }
    return true
  end,
})

xianwan:addEffect(fk.AskForCardResponse, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xianwan.name) and
      H.allGeneralsRevealed(player) and
      (matches(data.pattern, "jink") or matches(data.pattern, "slash"))
  end,
  on_cost = function(self, event, target, player, data)
    local name = matches(data.pattern, "jink") and "jink" or "slash"
    event:setCostData(self, { name = name })
    return player.room:askToSkillInvoke(player, {
      skill_name = xianwan.name,
      prompt = "#fengsui_heg__xianwan-" .. name,
    })
  end,
  on_use = function(self, event, target, player, data)
    U.hideSkillGeneral(player, xianwan.name)
    local card = Fk:cloneCard(event:getCostData(self).name)
    card.skillName = xianwan.name
    data.result = { from = player, card = card }
    return true
  end,
})

return xianwan
