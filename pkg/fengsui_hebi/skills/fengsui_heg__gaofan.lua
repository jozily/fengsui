local H = require "packages.fengsui.hegemony_util"

local gaofan = fk.CreateSkill{
  name = "fengsui_heg__gaofan",
  attached_skill_name = "fengsui_heg__gaofan_response&",
}

local function generalPosition(player)
  for _, is_deputy in ipairs({false, true}) do
    local general = Fk.generals[H.getActualGeneral(player, is_deputy)]
    if general and table.contains(general:getSkillNameList(), gaofan.name) then
      return is_deputy
    end
  end
end

local function canSwap(owner, responder)
  local is_deputy = generalPosition(owner)
  return is_deputy ~= nil and H.hasGeneral(owner, is_deputy) and
    H.hasGeneral(responder, is_deputy)
end

local function findOwner(room, responder, source)
  if not responder or not source or responder == source or not responder:isAlive() or not source:isAlive() then
    return
  end
  return table.find(room.alive_players, function(owner)
    local counterpart = owner == responder and source or responder
    return owner:hasShownSkill(gaofan.name) and (owner == responder or owner == source) and
      H.compareKingdomWith(owner, counterpart) and canSwap(owner, counterpart)
  end)
end

local function attachToResponder(room, responder, source)
  local owner = findOwner(room, responder, source)
  if not owner then return end
  room:setPlayerMark(responder, "fengsui_heg__gaofan_owner", owner.id)
  room:setPlayerMark(responder, "fengsui_heg__gaofan_source", source.id)
  room:setPlayerMark(responder, "fengsui_heg__gaofan_counterpart", owner == responder and source.id or responder.id)
  if not responder:hasSkill(gaofan.attached_skill_name) then
    room:handleAddLoseSkills(responder, gaofan.attached_skill_name, nil, false, true)
  end
end

gaofan:addEffect(fk.HandleAskForPlayCard, {
  global = true,
  can_refresh = function(self, event, target, player, data)
    if data.afterRequest or not data.eventData or not data.eventData.from then return false end
    local source = data.eventData.from
    if data.user then return findOwner(player.room, data.user, source) ~= nil end
    return table.find(player.room.alive_players, function(responder)
      return findOwner(player.room, responder, source) ~= nil
    end) ~= nil
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local source = data.eventData.from
    if data.user then
      attachToResponder(room, data.user, source)
    else
      for _, responder in ipairs(room.alive_players) do
        attachToResponder(room, responder, source)
      end
    end
  end,
})

gaofan:addEffect(fk.HandleAskForPlayCard, {
  global = true,
  can_refresh = function(self, event, target, player, data)
    return data.afterRequest and table.find(player.room.alive_players, function(p)
      return p:getMark("fengsui_heg__gaofan_owner") ~= 0
    end) ~= nil
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, responder in ipairs(room.alive_players) do
      if responder:getMark("fengsui_heg__gaofan_owner") ~= 0 then
        room:setPlayerMark(responder, "fengsui_heg__gaofan_owner", 0)
        room:setPlayerMark(responder, "fengsui_heg__gaofan_source", 0)
        room:setPlayerMark(responder, "fengsui_heg__gaofan_counterpart", 0)
        if responder:hasSkill(gaofan.attached_skill_name) then
          room:handleAddLoseSkills(responder, "-" .. gaofan.attached_skill_name, nil, false, true)
        end
      end
    end
  end,
})

return gaofan
