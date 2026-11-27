local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local qiongbu = fk.CreateSkill { name = "fengsui_heg__qiongbu", tags = { Skill.Compulsory } }

local function canTrigger(self, event, target, player, data)
  return target and target:isAlive() and
    player.room.current == player and player:hasShownSkill(qiongbu.name)
end

local function banReveal(p, skill_name)
  if not p or not p:isAlive() then return end
  for _, is_deputy in ipairs({ false, true }) do
    local general = is_deputy and p.deputyGeneral or p.general
    if general ~= "anjiang" and not p:prohibitReveal(is_deputy) then
      U.prohibitReveal(p, is_deputy, skill_name, "turn")
    end
  end
end

local function hiddenNum(p)
  local n = 0
  if p.general == "anjiang" then n = n + 1 end
  if p.deputyGeneral == "anjiang" then n = n + 1 end
  return n
end

for _, event in ipairs({ fk.GeneralRevealed, fk.GeneralHidden }) do
  local isHide = event == fk.GeneralHidden
  qiongbu:addEffect(event, {
    global = true,
    can_trigger = canTrigger,
    on_use = function(self, event, target, player, data)
      local room = player.room
      room:drawCards(player, 1, qiongbu.name)
      if target == player then
        if player:isAlive() then room:drawCards(player, 1, qiongbu.name) end
      elseif target:isAlive() then
        room:drawCards(target, 1, qiongbu.name)
      end
      banReveal(player, qiongbu.name)
      if target ~= player then banReveal(target, qiongbu.name) end
      if target == player or not isHide or player.dead or not target:isAlive() then return end
      if target:getHandcardNum() <= player:getHandcardNum() then return end
      if hiddenNum(target) <= hiddenNum(player) then return end
      local places = {}
      if target.general ~= "anjiang" then table.insert(places, "fengsui_heg__qiongbu_main") end
      if target.deputyGeneral ~= "anjiang" then table.insert(places, "fengsui_heg__qiongbu_deputy") end
      if #places == 0 then return end
      local choice = #places == 1 and places[1] or room:askToChoice(player, {
        choices = places, skill_name = qiongbu.name, prompt = "#fengsui_heg__qiongbu-place",
      })
      target:hideGeneral(choice == "fengsui_heg__qiongbu_deputy")
      if player.dead or not target:isAlive() then return end
      room:damage { from = player, to = target, damage = 1, skillName = qiongbu.name }
    end,
  })
end

return qiongbu
