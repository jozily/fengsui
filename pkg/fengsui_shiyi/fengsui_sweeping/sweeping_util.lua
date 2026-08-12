local H = require "packages.hegemony.util"

local M = {}

local function getRoom(value)
  if value and value.alive_players then return value end
  if value and value.room then return value.room end
  return Fk:currentRoom()
end

function M.sameKingdomCount(player)
  local room = getRoom(player)
  if not room or not room.alive_players then return 0 end
  return #table.filter(room.alive_players, function(p)
    return H.compareKingdomWith(player, p)
  end)
end

function M.kingdomCount(room)
  room = getRoom(room)
  if not room or not room.alive_players then return 0 end
  local kingdoms = {}
  for _, p in ipairs(room.alive_players) do
    local kingdom = H.getKingdom(p)
    if kingdom and kingdom ~= "unknown" and kingdom ~= "hidden" then
      table.insertIfNeed(kingdoms, kingdom)
    end
  end
  return #kingdoms
end

function M.becomeWild(player, generalName)
  local room = player.room
  if player.kingdom == "wild" then return false end
  room:setPlayerProperty(player, "kingdom", "wild")
  room:setPlayerMark(player, "__heg_wild", 1)
  H.wildChooseKingdom(player, generalName)
  return true
end

function M.askOneToBuildCountry(player, target, skillName)
  if not target or target.dead or player.dead or target:getMark("__heg_join_wild") ~= 0 or
    target.kingdom == "wild" or string.find(target.general, "lord", 1, true) then
    return false
  end
  local room = player.room
  local choice = room:askToChoice(target, {
    choices = { "heg_rule_join_country:" .. player.id .. "::" .. player.role, "Cancel" },
    skill_name = skillName,
    prompt = "#wild_join-choose",
  })
  if choice == "Cancel" then return false end
  room:setPlayerProperty(target, "role_shown", true)
  room:setPlayerProperty(target, "role", player.role)
  room:sendLog { type = "#WildChooseKingdom", from = target.id, arg = player.role, arg2 = "wild" }
  room:setPlayerProperty(target, "kingdom", "wild")
  room:setPlayerMark(target, "__heg_join_wild", 1)
  room:setPlayerMark(player, "__heg_construct_wild", 1)
  room:sendLog { type = "#SuccessBuildCountry", from = player.id, arg = player.role, arg2 = target.general }
  room:recover { who = target, num = 1, recoverBy = player, skillName = skillName }
  if target:isAlive() and target:getHandcardNum() < 4 then
    target:drawCards(4 - target:getHandcardNum(), skillName)
  end
  return true
end

function M.useMouLijian(player, skillName)
  local room = player.room
  local mou = Fk.skills["mou__lijian"]
  if not mou then return {} end
  room:setPlayerMark(player, "fengsui_limited_heg__sweeping_resolving", 1)
  room:setPlayerMark(player, "fengsui_limited_heg__sweeping_damaged", 0)
  local success, result = room:askToUseActiveSkill(player, {
    skill_name = "mou__lijian",
    prompt = "#fengsui_limited_heg__sweeping-lijian",
    cancelable = false,
    no_indicate = false,
  })
  room:setPlayerMark(player, "fengsui_limited_heg__sweeping_resolving", 0)
  local ids = player:getTableMark("fengsui_limited_heg__sweeping_damaged")
  room:setPlayerMark(player, "fengsui_limited_heg__sweeping_damaged", 0)
  return table.filter(table.map(ids, function(id) return room:getPlayerById(id) end), function(p)
    return p and p:isAlive() and p ~= player
  end)
end

return M
