local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local baizu = fk.CreateSkill {
  name = "fengsui_heg__baizu",
  tags = { Skill.Compulsory },
}

local function selectableKingdoms(player)
  local kingdoms = {}
  local room = (player and player.room) or (Fk.currentRoom and Fk:currentRoom())
  if not room or not room.alive_players then return kingdoms end
  for _, p in ipairs(room.alive_players) do
    local kingdom = H.getKingdom(p)
    if p ~= player and kingdom ~= "unknown"  then
      table.insertIfNeed(kingdoms, kingdom)
    end
  end
  return kingdoms
end

baizu:addEffect("active", {
  card_num = 0,
  target_num = function(self, player) return #selectableKingdoms(player) end,
  card_filter = U.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    local kingdom = H.getKingdom(to_select)
    return to_select ~= player  and kingdom ~= "unknown" and
      not table.find(selected, function(p) return H.getKingdom(p) == kingdom end)
  end,
  can_use = Util.FalseFunc,
  on_use = function() end,
})

baizu:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, _, target, player)
    return target == player and player:hasSkill(baizu.name) and player.phase == Player.Finish and
      player:isWounded() and not player:isNude() and #selectableKingdoms(player) > 0
  end,
  on_use = function(self, _, _, player)
    local room = player.room
    local kingdoms = selectableKingdoms(player)
    local chosen = {}
    local success, result = room:askToUseActiveSkill(player, {
      skill_name = baizu.name, prompt = "#fengsui_heg__baizu-choose-all:::" .. #kingdoms,
      cancelable = false, skip = true,
    })
    if success and result then chosen = result.targets end
    if #chosen < #kingdoms then
      for _, kingdom in ipairs(kingdoms) do
        if not table.find(chosen, function(p) return H.getKingdom(p) == kingdom end) then
          local fallback = table.find(room.alive_players, function(p)
            return p ~= player  and H.getKingdom(p) == kingdom
          end)
          if fallback then table.insert(chosen, fallback) end
        end
      end
    end
    table.insert(chosen, player)
    local cards_map = room:askToJointCards(player, {
      players = chosen, min_num = 1, max_num = 1, include_equip = true,
      skill_name = baizu.name, cancelable = false,
      prompt = "#fengsui_heg__baizu-discard", will_throw = true,
    })
    local player_card, moves = nil, {}
    local discarded = {}
    for _, p in ipairs(chosen) do
      local ids = cards_map[p] or {}
      if #ids > 0 then
        local card = Fk:getCardById(ids[1])
        discarded[p] = card.type
        if p == player then player_card = card.type end
        table.insert(moves, {
          ids = ids, from = p, toArea = Card.DiscardPile,
          moveReason = fk.ReasonDiscard, proposer = p, skillName = baizu.name,
        })
      end
    end
    if #moves > 0 then room:moveCards(table.unpack(moves)) end
    if not player_card then return end
    local type_counts = {}
    for _, card_type in pairs(discarded) do
      type_counts[card_type] = (type_counts[card_type] or 0) + 1
    end
    local should_transform = false
    for p, ctype in pairs(discarded) do
      if type_counts[ctype] == 1 and p:isAlive() then
        room:loseHp(p, 1, baizu.name)
        if p.dead then should_transform = true end
      end
    end
    if should_transform and player:isAlive() and H.hasGeneral(player, true) then
      H.transformGeneral(room, player, false, false, 1, baizu.name)
    end
  end,
})

return baizu
