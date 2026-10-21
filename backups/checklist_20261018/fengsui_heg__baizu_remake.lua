local H = require "packages.fengsui.hegemony_util"

local baizu = fk.CreateSkill{
  name = "fengsui_heg__baizu",
  tags = {Skill.Compulsory},
}

local function getSelectableKingdoms(player)
  local kingdoms = {}
  local room = player.room or Fk:currentRoom()
  if not room then return kingdoms end
  for _, p in ipairs(room.alive_players) do
    local kingdom = H.getKingdom(p)
    if p ~= player and kingdom ~= "unknown" then
      table.insertIfNeed(kingdoms, kingdom)
    end
  end
  return kingdoms
end

baizu:addEffect("active", {
  card_num = 0,
  target_num = function(self, player)
    return #getSelectableKingdoms(player)
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    local kingdom = H.getKingdom(to_select)
    return to_select ~= player and kingdom ~= "unknown" and
      not table.find(selected, function(p) return H.getKingdom(p) == kingdom end)
  end,
  can_use = Util.FalseFunc,
  on_use = function() end,
})

baizu:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(baizu.name) and player.phase == Player.Finish and
           player:isWounded() and not player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local kingdoms = getSelectableKingdoms(player)
    local chosen_targets = {}
    if #kingdoms > 0 then
      local success, result = room:askToUseActiveSkill(player, {
        skill_name = baizu.name,
        prompt = "#fengsui_heg__baizu-choose-all:::" .. #kingdoms,
        cancelable = false,
        skip = true,
      })
      if success and result then
        chosen_targets = result.targets
      else
        for _, kingdom in ipairs(kingdoms) do
          local fallback = table.find(room.alive_players, function(p)
            return p ~= player and H.getKingdom(p) == kingdom
          end)
          if fallback then
            table.insert(chosen_targets, fallback)
          end
        end
      end
    end

    table.insert(chosen_targets, player)

    local cards_map = room:askToJointCards(player, {
      players = chosen_targets,
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = baizu.name,
      cancelable = false,
      prompt = "#fengsui_heg__baizu-discard",
      will_throw = true,
    })

    local discards = {}
    local move_infos = {}
    for _, t in ipairs(chosen_targets) do
      local ids = cards_map[t] or {}
      if #ids > 0 then
        discards[t.id] = Fk:getCardById(ids[1]).type
        table.insert(move_infos, {
          ids = ids,
          from = t,
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonDiscard,
          proposer = t,
          skillName = baizu.name,
        })
      end
    end
    if #move_infos > 0 then
      room:moveCards(table.unpack(move_infos))
    end

    local type_count = {}
    for pid, ctype in pairs(discards) do
      type_count[ctype] = (type_count[ctype] or 0) + 1
    end

    local to_lose_hp = {}
    for pid, ctype in pairs(discards) do
      if type_count[ctype] > 1 then
        local t = room:getPlayerById(pid)
        -- 为后续结算奖励，提前记录其受伤前的国籍身份
        table.insert(to_lose_hp, { target = t, k = H.getKingdom(t) })
      end
    end

    local dead_info = {}
    for _, info in ipairs(to_lose_hp) do
      local t = info.target
      if t and t:isAlive() then
        room:loseHp(t, 1, baizu.name)
        if t.dead then
          table.insert(dead_info, info.k)
        end
      end
    end

    for _, dk in ipairs(dead_info) do
      if dk == H.getKingdom(player) then
        local deputy = player.deputyGeneral == "anjiang" and player:getMark("__heg_deputy") or player.deputyGeneral
        if deputy and deputy ~= "" then
      H.removeGeneral(player, true)
        end
      else
        local kingdom_num = #table.filter(room.alive_players, function(p)
          return H.getKingdom(p) == dk
        end)
        if kingdom_num > 0 then
          player:drawCards(kingdom_num, baizu.name)
        end
      end
    end

  end,
})

return baizu
