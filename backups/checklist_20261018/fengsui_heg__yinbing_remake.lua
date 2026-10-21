local H = require "packages.fengsui.hegemony_util"

local yinbing = fk.CreateSkill{
  name = "fengsui_heg__yinbing",
  tags = { Skill.Compulsory, Skill.MainPlace },
}

local function uniqueBigKingdom(player)
  if not H.isBigKingdomPlayer(player) then return false end
  local kingdom = H.getKingdom(player)
  for _, p in ipairs(player.room.alive_players) do
    if p ~= player and H.isBigKingdomPlayer(p) and H.getKingdom(p) ~= kingdom then return false end
  end
  return true
end

local function currentCardUser(room)
  if not room or not room.logic then return nil end
  local event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
  return event and event.data and event.data.from
end

yinbing:addEffect("prohibit", {
  global = true,
  prohibit_response = function(self, responder, card)
    local room = responder.room or Fk:currentRoom()
    if not room then return false end
    local source = currentCardUser(room)
    if not source or source == responder then return false end
    for _, owner in ipairs(room.alive_players) do
      if owner:hasSkill(yinbing.name) and owner:hasShownSkill(yinbing.name) then
        if responder == owner and uniqueBigKingdom(owner) and H.compareKingdomWith(source, owner) then
          return true
        end
        if source == owner and H.isSmallKingdomPlayer(owner) and H.isBigKingdomPlayer(responder) then
          return true
        end
      end
    end
    return false
  end,
})

return yinbing
