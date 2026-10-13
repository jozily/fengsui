local H = require "packages.fengsui.hegemony_util"
local D = require "packages.fengsui.pkg.fengsui_hebi.daoli_util"
_G.__fengsui_heg_daoli_stolen = _G.__fengsui_heg_daoli_stolen or {}
_G.__fengsui_heg_daoli_skills = _G.__fengsui_heg_daoli_skills or {}
_G.__fengsui_heg_daoli_pending = _G.__fengsui_heg_daoli_pending or {}

local function collectSkills(target)
  local result = {}
  for _, name in ipairs({ H.getActualGeneral(target, false), H.getActualGeneral(target, true) }) do
    local general = name and Fk.generals[name]
    if general then
      for _, skillName in ipairs(general:getSkillNameList(true)) do
        local skill = Fk.skills[skillName]
        if skill and not skill:hasTag(Skill.Lord) and not skill:hasTag(Skill.Limited) and
          not skill:hasTag(Skill.Compulsory) and not table.contains(result, skillName) then
          table.insert(result, skillName)
        end
      end
    end
  end
  return result
end

local daoli_on_death = fk.CreateSkill { name = "fengsui_heg__daoli_on_death" }
daoli_on_death:addEffect(fk.Death, {
  global = true,
  can_trigger = function(self, _, target, player)
    return target == player and
      (player:hasShownSkill("fengsui_heg__daoli") or
        player:hasShownSkill("fengsui_heg__beiqiu"))
  end,
  on_use = function(self, _, _, player)
    local room = player.room
    local candidates = table.filter(room.alive_players, function(p)
      return H.compareKingdomWith(player, p)
    end)
    if #candidates == 0 then return end
    local chooser = candidates[1]
    local tos = room:askToChoosePlayers(chooser, {
      targets = candidates, min_num = 1, max_num = 1,
      skill_name = "fengsui_heg__daoli", prompt = "#fengsui_heg__daoli-clean",
      cancelable = false,
    })
    local receiver = tos and tos[1]
    if not receiver then return end
    D.prepare(room, receiver, player)
  end,
})

return daoli_on_death
