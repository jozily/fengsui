local H = require "packages.fengsui.hegemony_util"

local yuandi = fk.CreateSkill {
  name = "fengsui_heg__yuandi",
  tags = { Skill.Compulsory },
}

local seen_player_mark = "fengsui_heg__yuandi_seen"
local xinyou_count = "fengsui_heg__xinyou_count"
local xinyou_visible = "@fengsui_heg__xinyou"
local kingdom_visible = "@fengsui_heg__yuandi"
local recorded_kingdoms = "fengsui_heg__yuandi_kingdoms"
local owner_first_vanguard = "fengsui_heg__yuandi_owner_first_vanguard"

local function isWildOrigin(player)
  return player.role == "wild" or player:getMark("__heg_wild") > 0 or
    player:getMark("__heg_join_wild") > 0 or player:getMark("__heg_construct_wild") > 0 or
    player:getMark("_wild_gained") > 0 or player:getMark("__heg_init_kingdom") == "wild"
end

local function updateXinyou(room, owner)
  room:setPlayerMark(owner, xinyou_visible, tostring(owner:getMark(xinyou_count)))
end

local function getFirstKingdom(room)
  local cached = room:getTag("fengsui_heg__yuandi_first_kingdom")
  if cached and cached ~= "unknown" then return cached end
  local first = room:getTag("TheFirstToShowRewarded")
  for _, p in ipairs(room.players) do
    if first == p.id or tostring(first) == tostring(p.id) then
      local kingdom = H.getKingdom(p)
      if kingdom ~= "unknown" then
        room:setTag("fengsui_heg__yuandi_first_kingdom", kingdom)
        return kingdom
      end
      break
    end
  end
  return nil
end

local function recordKingdom(room, target)
  local kingdom = H.getKingdom(target)
  if kingdom == "unknown" or kingdom == "wild" then return end
  local tag = "fengsui_heg__yuandi_seen_" .. kingdom
  if room:getTag(tag) then return end
  room:setTag(tag, true)
  local kingdoms = room:getTag(recorded_kingdoms)
  if type(kingdoms) ~= "table" then kingdoms = {} end
  table.insertIfNeed(kingdoms, kingdom)
  room:setTag(recorded_kingdoms, kingdoms)
end

local function recordFirstKingdom(room, target)
  local kingdom = H.getKingdom(target)
  if kingdom == "unknown" or kingdom == "wild" then return end
  local tag = "fengsui_heg__yuandi_seen_" .. kingdom
  if room:getTag(tag) then return end
  room:setTag(tag, true)
  local kingdoms = room:getTag(recorded_kingdoms)
  if type(kingdoms) ~= "table" then kingdoms = {} end
  table.insertIfNeed(kingdoms, kingdom)
  room:setTag(recorded_kingdoms, kingdoms)
end

local function updateKingdomVisible(room, owner)
  if not owner:hasShownSkill(yuandi.name) then return end
  local kingdoms = {}
  local recorded = room:getTag(recorded_kingdoms)
  if type(recorded) == "table" then
    for _, kingdom in ipairs(recorded) do
      table.insertIfNeed(kingdoms, Fk:translate(kingdom))
    end
  end
  for _, target in ipairs(room.players) do
    if target:getMark("@!!vanguard") > 0 then
      local kingdom = H.getKingdom(target)
      if kingdom ~= "unknown" and kingdom ~= "wild" then
        table.insertIfNeed(kingdoms, Fk:translate(kingdom))
      end
    end
  end
  table.sort(kingdoms)
  room:setPlayerMark(owner, kingdom_visible, table.concat(kingdoms, " "))
end

local function canHandleReveal(target, player, data)
  -- 拥有者自己的明置由下方"拥有者保底"效果独家处理，
  -- 否则这里与保底各发一枚先驱，拥有者会拿到两枚。
  if target == player then return false end
  local has_reveal_data = data and (data.m or data.d or (type(data) == "table" and #data > 0))
  if not (target and has_reveal_data and player:hasSkill(yuandi.name, true)) then return false end
    if target:getMark(seen_player_mark) > 0 then return false end
    local kingdom = H.getKingdom(target)
    if kingdom == "unknown" or kingdom == "wild" then return false end
    -- The native rule rewards the first revealed player before this fallback
    -- runs.  Record that player's kingdom so the same kingdom cannot receive
    -- a second vanguard from Yuandi.
    local first_kingdom = getFirstKingdom(player.room)
    if first_kingdom == kingdom then
      recordFirstKingdom(player.room, target)
      player.room:setPlayerMark(target, seen_player_mark, 1)
      return false
    end
    -- 该角色只要已经亮过一张武将牌，就应被记录为该势力的已处理角色。
    -- 即使该势力此前已被其他角色记录，也要写入 seen_player_mark，
    -- 否则此人随后亮出第二张武将牌时会再次进入本技能。
    local kingdom_tag = "fengsui_heg__yuandi_seen_" .. kingdom
    if player.room:getTag(kingdom_tag) then
      player.room:setPlayerMark(target, seen_player_mark, 1)
      return false
    end
    return true
end

local function handleReveal(target, player)
    local room = player.room
    room:setPlayerMark(target, seen_player_mark, 1)
    local first_id = room:getTag("TheFirstToShowRewarded")
    local first_player = first_id == target.id or tostring(first_id) == tostring(target.id)
    if not first_id then
      -- The mode rule may set this tag later in the same reveal event. Keep
      -- Yuandi's first-reveal exception deterministic regardless of priority.
      room:setTag("TheFirstToShowRewarded", target.id)
      first_player = true
    end
    if first_player then
      -- The first revealed role is recorded, but does not receive Yuandi's Vanguard.
      recordFirstKingdom(room, target)
    else
      recordKingdom(room, target)
      H.addHegMark(room, target, "vanguard")
    end
    updateKingdomVisible(room, player)
end

yuandi:addEffect(fk.GeneralShown, {
  global = true,
  can_trigger = function(self, _, target, player, data)
    return canHandleReveal(target, player, data)
  end,
  on_use = function(self, _, target, player)
    handleReveal(target, player)
  end,
})

-- Some reveal paths publish GeneralRevealed after the kingdom has been set.
-- Handle it as a fallback; seen_player_mark makes the two events idempotent.
yuandi:addEffect(fk.GeneralRevealed, {
  global = true,
  can_trigger = function(self, _, target, player, data)
    return canHandleReveal(target, player, data)
  end,
  on_use = function(self, _, target, player)
    handleReveal(target, player)
  end,
})

yuandi:addEffect(fk.AfterSkillEffect, {
  global = true,
  can_trigger = function(self, _, target, player, data)
    return target and data and data.skill and data.skill.name == "vanguard_skill&" and
      player:hasSkill(yuandi.name, true) and H.getKingdom(target) ~= "wild" and
      not isWildOrigin(target)
  end,
  on_use = function(self, _, target, player)
    local room = player.room
    room:setPlayerMark(player, xinyou_count, player:getMark(xinyou_count) + 1)
    updateXinyou(room, player)
  end,
})

yuandi:addEffect(fk.GeneralRevealed, {
  can_refresh = function(self, _, target, player)
    return target == player and player:hasShownSkill(yuandi.name) and
      player:getMark(kingdom_visible) == 0
  end,
  on_refresh = function(self, _, target, player)
    updateKingdomVisible(player.room, player)
  end,
})

-- 元嫡拥有者首次明置自己带有本技能的武将牌时，也获得一枚先驱。
-- 单独处理该效果，避免全场首亮的势力排除逻辑把拥有者一并跳过。
local function ownerFirstReveal(self, _, target, player)
  return target == player and player:hasShownSkill(self.name) and
    player:getMark(owner_first_vanguard) == 0
end

local function grantOwnerFirstVanguard(self, _, target, player)
  local room = player.room
  room:setPlayerMark(player, owner_first_vanguard, 1)
  -- 补上原本由全局处理器完成的两件事：标记该角色已处理、
  -- 记录其势力（此后同势力角色明置不再从元嫡获得先驱）。
  room:setPlayerMark(player, seen_player_mark, 1)
  recordKingdom(room, player)
  H.addHegMark(room, player, "vanguard")
  updateKingdomVisible(room, player)
end

yuandi:addEffect(fk.GeneralShown, {
  can_trigger = ownerFirstReveal,
  on_use = grantOwnerFirstVanguard,
})

yuandi:addEffect(fk.GeneralRevealed, {
  can_trigger = ownerFirstReveal,
  on_use = grantOwnerFirstVanguard,
})

return yuandi
