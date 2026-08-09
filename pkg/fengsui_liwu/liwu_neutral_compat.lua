local Compat = {}

local installed = false
local neutralKingdom = "fengsui_neutral"
local neutralAllKingdom = "fengsui_neutralall"
local baseKingdoms = { "wei", "shu", "wu", "qun", "jinh" }

local function generalKingdoms(general)
  local kingdoms = {}
  for _, kingdom in ipairs({ general.kingdom, general.subkingdom }) do
    if kingdom then
      local mapped = Fk:getKingdomMap(kingdom)
      if #mapped > 0 then
        table.insertTableIfNeed(kingdoms, mapped)
      else
        table.insertIfNeed(kingdoms, kingdom)
      end
    end
  end
  return kingdoms
end

local function canPair(general, deputy)
  if not general or not deputy or general == deputy then return false end
  if general.kingdom == neutralAllKingdom and deputy.kingdom == neutralAllKingdom then return false end
  if general.kingdom == neutralAllKingdom and deputy.kingdom == "wild" then return false end
  if deputy.kingdom == neutralAllKingdom and general.kingdom == "wild" then return false end
  if general.kingdom == "wild" then
    return deputy.kingdom ~= "wild" and deputy.kingdom ~= neutralKingdom and deputy.kingdom ~= neutralAllKingdom
  end
  if deputy.kingdom == "wild" then return false end
  if general.kingdom == neutralKingdom and deputy.kingdom == neutralKingdom then return false end
  return table.find(generalKingdoms(general), function(kingdom)
    return table.contains(generalKingdoms(deputy), kingdom)
  end) ~= nil
end

local function neutralPairKingdoms(general, deputy, enabledKingdoms)
  if not general or not deputy or general == deputy then return nil end
  local other
  if general.kingdom == neutralAllKingdom then
    other = deputy
  elseif deputy.kingdom == neutralAllKingdom then
    other = general
  else
    return nil
  end
  if other.kingdom == "wild" or other.kingdom == neutralKingdom or other.kingdom == neutralAllKingdom then
    return {}
  end
  return table.filter(generalKingdoms(other), function(kingdom)
    return table.contains(baseKingdoms, kingdom) and
      (not enabledKingdoms or #enabledKingdoms == 0 or table.contains(enabledKingdoms, kingdom))
  end)
end

local function installChooseRule()
  Fk.choose_general_rule["heg_general_choose"] = {
    name = "heg_general_choose",
    card_filter = function(toSelect, selected, data, extraData)
      if #selected == extraData.n then return false end
      if #selected == 0 then
        return table.find(data, function(name)
          return canPair(Fk.generals[toSelect], Fk.generals[name])
        end) ~= nil
      end
      return table.every(selected, function(name)
        return canPair(Fk.generals[name], Fk.generals[toSelect])
      end)
    end,
    feasible = function(selected, data, extraData)
      if #selected ~= extraData.n then return false end
      for i = 1, #selected do
        for j = i + 1, #selected do
          if not canPair(Fk.generals[selected[i]], Fk.generals[selected[j]]) then return false end
        end
      end
      return true
    end,
    prompt = function(data, extraData)
      if extraData.prompt then return extraData.prompt end
      local prompt = Fk:translate("#AskForChooseGenerals")
      prompt = prompt:gsub("%%1", Fk:translate(extraData.skillName or "Fight"))
      return prompt:gsub("%%2", math.floor(extraData.n))
    end,
    default_choice = function(data, extraData)
      if extraData.n == 1 then return table.random(data, 1) end
      for i = 1, #data - 1 do
        for j = i + 1, #data do
          if canPair(Fk.generals[data[i]], Fk.generals[data[j]]) then
            return { data[i], data[j] }
          end
        end
      end
      return {}
    end,
  }
end

local function chooseGenerals(self)
  local room = self and self.room
  if not room then return end
  local generalNum = math.max(room:getSettings("generalNum"), 5)
  room:doBroadcastNotify("ShowToast", Fk:translate("#HegInitialNotice"))

  local lord = room:getLord()
  room:setCurrent(lord)
  lord.role = "hidden"

  local allKingdoms = {}
  table.forEach(room.general_pile, function(name)
    table.insertTableIfNeed(allKingdoms, generalKingdoms(Fk.generals[name]))
  end)
  table.removeOne(allKingdoms, "wild")
  if #allKingdoms > 4 and not room:getSettings("notBanToFourKingdoms") then
    local kingdoms = table.random(allKingdoms, 4)
    local unused = table.filter(allKingdoms, function(kingdom)
      return not table.contains(kingdoms, kingdom)
    end)
    room:sendLog{
      type = "#KingdomFiltered",
      arg = table.concat(table.map(unused, Util.TranslateMapper), " "),
      arg2 = table.concat(table.map(kingdoms, Util.TranslateMapper), " "),
      toast = true,
    }
    for i = #room.general_pile, 1, -1 do
      local general = Fk.generals[room.general_pile[i]]
      if general.kingdom ~= neutralKingdom and general.kingdom ~= neutralAllKingdom and
        not table.find(generalKingdoms(general), function(kingdom)
          return table.contains(kingdoms, kingdom)
        end) then
        table.remove(room.general_pile, i)
      end
    end
    allKingdoms = kingdoms
  end
  table.sort(allKingdoms)
  room:setBanner("all_kingdoms", allKingdoms)

  local players = room.players
  local generals = room:getNGenerals(#players * generalNum)
  table.shuffle(generals)
  local req = Request:new(players, "AskForGeneral")
  req.timeout = room:getSettings("generalTimeout")
  for index, player in ipairs(players) do
    local choices = table.slice(generals, (index - 1) * generalNum + 1, index * generalNum + 1)
    table.sort(choices, function(a, b) return Fk.generals[a].kingdom > Fk.generals[b].kingdom end)
    for i = 1, #choices - 1 do
      for j = i + 1, #choices do
        if canPair(Fk.generals[choices[i]], Fk.generals[choices[j]]) then
          req:setDefaultReply(player, { choices[i], choices[j] })
          break
        end
      end
      if req.default_reply[player.id] then break end
    end
    req:setData(player, { choices, 2, false, true })
  end

  local selected = {}
  for _, player in ipairs(players) do
    local result = req:getResult(player)
    local general, deputy = result[1], result[2]
    room:setPlayerGeneral(player, general, true)
    room:setDeputyGeneral(player, deputy)
    table.insertTableIfNeed(selected, { general, deputy })
    room:setPlayerMark(player, "__heg_general", general)
    room:setPlayerMark(player, "__heg_deputy", deputy)
    room:setPlayerGeneral(player, "anjiang", true)
    room:setDeputyGeneral(player, "anjiang")
  end

  generals = table.filter(generals, function(general) return not table.contains(selected, general) end)
  room:returnToGeneralPile(generals)

  req = Request:new(players, "AskForChoices")
  req.focus_text = "AskForKingdom"
  req.receive_decode = false
  for _, player in ipairs(players) do
    local general = Fk.generals[player:getMark("__heg_general")]
    local deputy = Fk.generals[player:getMark("__heg_deputy")]
    local kingdoms
    if general.kingdom == "wild" then
      kingdoms = generalKingdoms(deputy)
      room:setPlayerMark(player, "__heg_wild", 1)
    elseif general.kingdom == neutralAllKingdom then
      kingdoms = table.filter(generalKingdoms(deputy), function(kingdom)
        return table.contains(allKingdoms, kingdom)
      end)
    elseif deputy.kingdom == neutralAllKingdom then
      kingdoms = table.filter(generalKingdoms(general), function(kingdom)
        return table.contains(allKingdoms, kingdom)
      end)
    else
      local deputyKingdoms = generalKingdoms(deputy)
      kingdoms = table.filter(generalKingdoms(general), function(kingdom)
        return table.contains(deputyKingdoms, kingdom) and table.contains(allKingdoms, kingdom)
      end)
    end

    if not table.contains(allKingdoms, "wu") and
      (player:getMark("__heg_deputy") == "mouxusheng" or player:getMark("__heg_general") == "mouxusheng") then
      table.insertIfNeed(kingdoms, "wu")
      table.insertIfNeed(allKingdoms, "wu")
    end
    assert(#kingdoms > 0, "neutral general pair has no available kingdom")
    req:setData(player, {
      kingdoms, allKingdoms, { 1, 1 }, false, "AskForKingdom", "#ChooseHegInitialKingdom", false, true,
    })
    req:setDefaultReply(player, room:tableRandomPick(kingdoms, 1))
  end
  req:ask()
  for _, player in ipairs(players) do
    local kingdom = req:getResult(player)[1]
    room:setPlayerMark(player, "__heg_kingdom", kingdom)
    room:setPlayerMark(player, "__heg_init_kingdom", kingdom)
  end
end

function Compat.install()
  if installed then return end
  installed = true
  if not Fk._fengsuiNeutralAllWrapped then
    local originalGetKingdomInHegemony = Fk.getKingdomInHegemony
    local originalCanMatchInHegemony = Fk.canMatchInHegemony
    Fk.getKingdomInHegemony = function(self, general, deputy, enabledKingdoms)
      local kingdoms = neutralPairKingdoms(self.generals[general], self.generals[deputy or ""], enabledKingdoms)
      if kingdoms ~= nil then return kingdoms end
      return originalGetKingdomInHegemony(self, general, deputy, enabledKingdoms)
    end
    Fk.canMatchInHegemony = function(self, general, deputy, enabledKingdoms)
      local kingdoms = neutralPairKingdoms(self.generals[general], self.generals[deputy], enabledKingdoms)
      if kingdoms ~= nil then return #kingdoms > 0 end
      return originalCanMatchInHegemony(self, general, deputy, enabledKingdoms)
    end
    Fk._fengsuiNeutralAllWrapped = true
  end
  local mode = require "packages.hegemony.pkg.gamemodes.new_hegemony_mode"
  table.insertTableIfNeed(mode.whitelist, { "fengsui_hebi", "fengsui_liwu", "fengsui_cards" })
  installChooseRule()
  local originalLogic = mode.logic
  mode.logic = function()
    installChooseRule()
    local logic = originalLogic()
    logic.chooseGenerals = chooseGenerals
    return logic
  end
end

return Compat
