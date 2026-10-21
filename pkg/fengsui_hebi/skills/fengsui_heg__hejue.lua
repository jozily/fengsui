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

local function companionDraws(players)
  local matched = {}
  local generals = table.map(players, actualGenerals)
  for i, owner in ipairs(players) do
    local count = 0
    for _, mine in ipairs(generals[i]) do
      local paired = false
      for _, theirs in ipairs(generals) do
        for _, other in ipairs(theirs) do
          if mine:isCompanionWith(other) or other:isCompanionWith(mine) then
            paired = true
            break
          end
        end
        if paired then break end
      end
      if paired then count = count + 1 end
    end
    if count > 0 then table.insert(matched, { player = owner, count = count }) end
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
    local paired = companionDraws(tos)
    if #paired > 0 then
      for _, item in ipairs(paired) do
        if item.player:isAlive() then item.player:drawCards(item.count, self.name) end
      end
      return
    end
    local same_kingdom = table.filter(tos, function(p)
      return H.compareKingdomWith(player, p)
    end)
    if #same_kingdom == 0 then return end
    local selected = room:askToChoosePlayers(player, {
      targets = same_kingdom, min_num = 1, max_num = 1,
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
