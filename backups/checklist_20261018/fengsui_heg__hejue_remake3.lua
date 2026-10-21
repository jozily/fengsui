local H = require "packages.fengsui.hegemony_util"
local hejue = fk.CreateSkill { name = "fengsui_heg__hejue" }

local function actualGenerals(player)
  local ret = {}
  for _, name in ipairs({ H.getActualGeneral(player, false), H.getActualGeneral(player, true) }) do
    if name and name ~= "anjiang" and not name:startsWith("blank_") and Fk.generals[name] then
      table.insert(ret, Fk.generals[name])
    end
  end
  return ret
end

local function hasCompanionPair(players)
  local matched = {}
  for _, owner in ipairs(players) do
    local gens = actualGenerals(owner)
    for i = 1, #gens do
      for j = i + 1, #gens do
        if gens[i]:isCompanionWith(gens[j]) or gens[j]:isCompanionWith(gens[i]) then
          table.insertIfNeed(matched, owner)
        end
      end
    end
  end
  for i = 1, #players do
    for j = i + 1, #players do
      for _, g1 in ipairs(actualGenerals(players[i])) do
        for _, g2 in ipairs(actualGenerals(players[j])) do
          if g1:isCompanionWith(g2) or g2:isCompanionWith(g1) then
            table.insertIfNeed(matched, players[i])
            table.insertIfNeed(matched, players[j])
          end
        end
      end
    end
  end
  return matched
end

hejue:addEffect(fk.Damaged, {
  anim_type = "support",
  can_trigger = function(self, _, target, player)
    return target == player and player:hasSkill(self.name)
  end,
  on_cost = function(self, event, _, player)
    return player.room:askToSkillInvoke(player, { skill_name = self.name, prompt = "#fengsui_heg__hejue-invoke" })
  end,
  on_use = function(self, event, _, player)
    local room = player.room
    local tos = room:askToChoosePlayers(player, {
      targets = room.alive_players, min_num = 1, max_num = 2,
      skill_name = self.name, prompt = "#fengsui_heg__hejue-choose", cancelable = false,
    })
    if #tos == 0 then return end
    local paired = hasCompanionPair(tos)
    if #paired > 0 then
      for _, p in ipairs(paired) do
        if p:isAlive() then p:drawCards(1, self.name) end
      end
      return
    end
    local selected = room:askToChoosePlayers(player, {
      targets = tos, min_num = 1, max_num = 1,
      skill_name = self.name, prompt = "#fengsui_heg__hejue-hebi", cancelable = false,
    })
    if selected[1] then H.askToHebiOrTransform(room, selected[1], self.name, false) end
  end,
})

Fk:loadTranslationTable {
  ["#fengsui_heg__hejue-invoke"] = "合珏：是否发动？",
  ["#fengsui_heg__hejue-choose"] = "合珏：选择至多两名角色",
  ["#fengsui_heg__hejue-hebi"] = "合珏：选择一名角色令其合璧",
}
return hejue
