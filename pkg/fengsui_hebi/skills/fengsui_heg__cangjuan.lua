local cangjuan = fk.CreateSkill {
  name = "fengsui_heg__cangjuan",
  tags = { Skill.Compulsory },
}

local H = require "packages.fengsui.hegemony_util"
local function zhaoshuInField(room)
  for _, p in ipairs(room.players) do
    local ids = p:getCardIds("hej")
    for _, pile in pairs(p.special_cards) do table.insertTable(ids, pile) end
    if table.find(ids, function(id) return Fk:getCardById(id).name == "heg_zhaoshu" end) then return true end
  end
  return false
end

local function findImperialOrder(room)
  for _, p in ipairs(room.players) do
    for _, id in ipairs(p:getCardIds("h")) do
      if Fk:getCardById(id).name == "imperial_order" then return id, p end
    end
  end
  for _, id in ipairs(room.draw_pile) do
    if Fk:getCardById(id).name == "imperial_order" then return id end
  end
end

local function useRealCard(room, player, ids, prompt)
  if not ids then return end
  if type(ids) ~= "table" then ids = { ids } end
  if #ids == 0 then return end
  local use = room:askToUseRealCard(player, {
    pattern = tostring(Exppattern{ id = ids }),
    skill_name = cangjuan.name,
    prompt = prompt,
    cancelable = false,
    skip = true,
    expand_pile = ids,
    extra_data = { bypass_times = true, bypass_distances = true, not_passive = false },
  })
  if use then room:useCard(use) end
  return use
end

cangjuan:addEffect(fk.GeneralRevealed, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(cangjuan.name) and
      player:getMark("fengsui_heg__cangjuan_revealed") == 0 and data and
      ((data.m and H.inGeneralSkills(player, cangjuan.name) == "m") or
       (data.d and H.inGeneralSkills(player, cangjuan.name) == "d"))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "fengsui_heg__cangjuan_revealed", 1)
    if not room:getBanner("ImperialOrderRemoved-turn") then
      local imperial, owner = findImperialOrder(room)
      if imperial then
        local use = useRealCard(room, player, imperial, "#fengsui_heg__cangjuan-imperial")
        if use and owner and owner:isAlive() then owner:drawCards(1, cangjuan.name) end
      end
    end
    if player.dead then return end
    if zhaoshuInField(room) then return end
    local zhaoshu = room:prepareDeriveCards({ { "heg_zhaoshu", Card.Club, 3 } }, "chiling_zhaoshu")[1]
    if not zhaoshu then return end
    room:moveCardTo(zhaoshu, Card.PlayerHand, player, fk.ReasonPrey, cangjuan.name, nil, true, player)
    if not player.dead and room:getCardOwner(zhaoshu) == player then
      useRealCard(room, player, zhaoshu, "#fengsui_heg__cangjuan-zhaoshu")
    end
  end,
})

return cangjuan
