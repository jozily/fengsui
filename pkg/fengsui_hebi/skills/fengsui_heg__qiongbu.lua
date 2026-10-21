local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local qiongbu = fk.CreateSkill { name = "fengsui_heg__qiongbu" }

local function canTrigger(target, player)
  return target and target ~= player and target:isAlive() and
    player:hasShownSkill(qiongbu.name) and H.allGeneralsRevealed(player)
end

local function cost(self, event, _, player)
  if player.room:askToSkillInvoke(player, {
    skill_name = qiongbu.name, prompt = "#fengsui_heg__qiongbu-invoke",
  }) then
    return true
  end
  return false
end

local function use(self, _, target, player)
  local room = player.room
  if H.allGeneralsRevealed(target) then
    room:drawCards(player, 1, qiongbu.name)
    if target:isAlive() then room:drawCards(target, 1, qiongbu.name) end
    return
  end
  local place = U.getSkillPlace(player, qiongbu.name)
  if place ~= nil then
    player:hideGeneral(place)
    room:damage { from = player, to = target, damage = 1, skillName = qiongbu.name }
  end
end

for _, event in ipairs({ fk.GeneralRevealed, fk.GeneralHidden }) do
  qiongbu:addEffect(event, {
    global = true,
    can_trigger = function(self, _, target, player)
      return canTrigger(target, player)
    end,
    on_cost = cost,
    on_use = use,
  })
end

return qiongbu
