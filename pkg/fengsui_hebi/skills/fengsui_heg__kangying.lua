local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"
local kangying = fk.CreateSkill { name = "fengsui_heg__kangying" }
local firstMainMark = "fengsui_heg__kangying_first_main"
local firstDeputyMark = "fengsui_heg__kangying_first_deputy"
local damageMark = "fengsui_heg__kangying_damage-turn"
local damageVisible = "@fengsui_heg__kangying_damage-turn"
local deputyVisible = "@fengsui_heg__kangying_deputy-turn"

local function displayRole(player)
  local shown = {}
  if player.general ~= "anjiang" then
    local name = H.getActualGeneral(player, false)
    if name then table.insert(shown, Fk:translate(name)) end
  end
  if player.deputyGeneral ~= "anjiang" then
    local name = H.getActualGeneral(player, true)
    if name then table.insert(shown, Fk:translate(name)) end
  end
  if #shown == 0 then return "座次" .. tostring(player.seat) .. "号位" end
  return table.concat(shown, " ")
end

local function isZutiMainFirst(player)
  return player and player:isAlive() and player.general ~= "anjiang" and
    H.getActualGeneral(player, false) == "fengsui_heg__zuti" and
    player:getMark(firstMainMark) > 0 and
    H.getActualGeneral(player, true) == player:getMark(firstDeputyMark)
end

kangying:addEffect(fk.GeneralShown, {
  can_refresh = function(self, _, target, player, data)
    return target == player and data and data.m and player:getMark(firstMainMark) == 0 and
      H.getActualGeneral(player, false) == "fengsui_heg__zuti" and player.deputyGeneral == "anjiang"
  end,
  on_refresh = function(self, _, target, player)
    player.room:setPlayerMark(player, firstMainMark, 1)
    player.room:setPlayerMark(player, firstDeputyMark, H.getActualGeneral(player, true))
  end,
})

kangying:addEffect(fk.DamageCaused, {
  global = true,
  anim_type = "support",
  can_trigger = function(self, _, target, player)
    if target ~= player or not isZutiMainFirst(player) or player.deputyGeneral == "anjiang" then return false end
    return table.find(player.room.alive_players, function(p)
      return p ~= player and H.compareKingdomWith(p, player) and U.hasGeneral(p, true)
    end) ~= nil
  end,
  on_cost = function(self, event, _, player)
    local room = player.room
    local candidates = table.filter(room.alive_players, function(p)
      return p ~= player and H.compareKingdomWith(p, player) and U.hasGeneral(p, true)
    end)
    local chosen = room:askToChoosePlayers(player, {
      targets = candidates, min_num = 1, max_num = 1, cancelable = true,
      skill_name = kangying.name, prompt = "#fengsui_heg__kangying-choose",
    })
    if not chosen[1] then return false end
    if not room:askToSkillInvoke(chosen[1], {
      skill_name = kangying.name, prompt = "#fengsui_heg__kangying-invoke::" .. player.id,
    }) then return false end
    event:setCostData(self, { target = chosen[1] })
    return true
  end,
  on_use = function(self, event, _, player)
    local room = player.room
    local other = event:getCostData(self).target
    if not other or not other:isAlive() or player.deputyGeneral == "anjiang" then return end
    H.swapDeputy(room, other, player)
    room:setPlayerMark(other, damageMark, 1)
    room:setPlayerMark(other, damageVisible, "亢膺 加伤")
    room:setPlayerMark(other, deputyVisible, "亢膺 " .. displayRole(player))
  end,
})

kangying:addEffect(fk.DamageCaused, {
  global = true,
  can_trigger = function(self, _, target, player)
    return target == player and player:isAlive() and player:getMark(damageMark) > 0
  end,
  on_use = function(self, _, _, player, data)
    data:changeDamage(1)
    player.room:setPlayerMark(player, damageMark, 0)
    player.room:setPlayerMark(player, damageVisible, 0)
    player.room:setPlayerMark(player, deputyVisible, 0)
  end,
})

Fk:loadTranslationTable {
  ["#fengsui_heg__kangying-choose"] = "亢膺：选择一名同势力角色与你副将易位",
  ["#fengsui_heg__kangying-invoke"] = "亢膺：是否与你副将易位，并获得本轮下一次造成的伤害+1？",
  ["@fengsui_heg__kangying_damage-turn"] = "亢膺 加伤",
  ["@fengsui_heg__kangying_deputy-turn"] = "亢膺",
}
return kangying
