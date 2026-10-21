local H = require "packages.fengsui.hegemony_util"

local guishang = fk.CreateSkill { name = "fengsui_heg__guishang" }

local function chooseKingdomTargets(room, player)
  local result, used = {}, {}
  local ownKingdom = H.getKingdom(player)
  local kingdoms = {}
  for _, p in ipairs(room.alive_players) do
    if p.kingdom ~= "unknown" and p.kingdom ~= "wild" and H.getKingdom(p) ~= ownKingdom then
      used[p.kingdom] = false; kingdoms[p.kingdom] = true
    end
  end
  local names = {}
  for kingdom in pairs(kingdoms) do table.insert(names, kingdom) end
  table.sort(names)
  for _, kingdom in ipairs(names) do
    local choices = table.filter(room.alive_players, function(p)
      return p.kingdom == kingdom and not table.contains(result, p)
    end)
    if #choices > 0 then
      local to = room:askToChoosePlayers(player, { targets = choices, min_num = 1, max_num = 1,
        skill_name = guishang.name, prompt = "#fengsui_heg__guishang-target::" .. kingdom, cancelable = false })[1]
      if to then table.insert(result, to) end
    end
  end
  return result
end

guishang:addEffect("active", {
  prompt = "#fengsui_heg__guishang",
  card_num = 0, target_num = 0,
  can_use = function(self, player)
    return player.phase == Player.Play and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function() return false end,
  on_use = function(self, room, effect)
    local player = effect.from
    local targets = chooseKingdomTargets(room, player)
    if #targets == 0 then return end
    local _, commandData = H.askToCommand(player, { tos = targets, skill_name = guishang.name })
    local succeeded = {}
    for _, p in ipairs(commandData and commandData.succeed_list or {}) do succeeded[p] = true end
    for _, to in ipairs(targets) do
      if to:isAlive() and player:isAlive() then
        local card = room:askToChoice(player, {
          choices = { "befriend_attacking", "await_exhausted" },
          skill_name = guishang.name, prompt = "#fengsui_heg__guishang-card::" .. to.id,
        })
        local from, tos
        if succeeded[to] then from, tos = to, {player} else from, tos = player, {to} end
        if from:isAlive() and tos[1]:isAlive() then
          room:useVirtualCard(card, nil, from, tos, guishang.name, true)
        end
      end
    end
  end,
})

return guishang
