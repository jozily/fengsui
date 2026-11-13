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
  -- 拥有者自己的明置由下方"拥有者保底"效果独家处理：那里一次性发放
  -- "你"与"本势力首个明置"两份奖励（同时满足时合计两枚先驱），
  -- 这里再处理会造成重复发放。
  if target == player then return false end
  -- 国战规则在 GameOverJudge 中会公开阵亡者的武将牌，同样触发亮将时机。
  -- 死者的势力不该被记入元嫡，也不该拿到先驱。
  if not target or not target:isAlive() or not player:isAlive() then return false end
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

-- 判断某势力是否已有其他角色明置过武将牌。不能只看元嫡自己写的
-- fengsui_heg__yuandi_seen_<势力>：元嫡生效之前（谢灵毓尚未明置带本技能
-- 的武将牌时）明置的同势力角色不会被写进该 tag，只按 tag 判断会把
-- "本势力早就有人亮过"误判成"本势力首亮"，多给一枚先驱。
local function isFirstInKingdom(room, player, kingdom)
  for _, p in ipairs(room.players) do
    if p ~= player and (p.general ~= "anjiang" or p.deputyGeneral ~= "anjiang") and
      H.getKingdom(p) == kingdom then
      return false
    end
  end
  return true
end

-- 判断拥有者本人是否为全场首亮。优先用模式规则写入的 tag；tag 尚未
-- 写入时改看场上是否已有其他角色明置过武将牌，避免依赖 GeneralShown /
-- GeneralRevealed 两条效果的执行顺序。
local function isFirstShownInRoom(room, player)
  local first_id = room:getTag("TheFirstToShowRewarded")
  if first_id then
    return first_id == player.id or tostring(first_id) == tostring(player.id)
  end
  for _, p in ipairs(room.players) do
    if p ~= player and p:isAlive() and
      (p.general ~= "anjiang" or p.deputyGeneral ~= "anjiang") then
      return false
    end
  end
  return true
end

-- 元嫡拥有者首次明置自己带有本技能的武将牌时，获得"你"那一枚先驱。
-- 只有她同时是本势力首个明置武将牌的角色时，才再获得"每个势力首个
-- 明置"那一枚，合计两枚；本势力已有他人先亮、或本势力就是全场首亮
-- 角色所属势力，都只给一枚。单独处理该效果，避免全场首亮的势力排除
-- 逻辑把拥有者一并跳过；两份奖励在这里一次性发放，也免去两处各发
-- 一枚的顺序依赖。
local function ownerFirstReveal(self, _, target, player)
  return target == player and player:hasShownSkill(self.name) and
    player:getMark(owner_first_vanguard) == 0
end

local function grantOwnerFirstVanguard(self, _, target, player)
  -- can_trigger 可能被批量求值，这里再挡一次，确保同一角色只发放一次，
  -- 否则 count=1 的场景执行两遍也会变成两枚。
  if player:getMark(owner_first_vanguard) > 0 then return end
  local room = player.room
  room:setPlayerMark(player, owner_first_vanguard, 1)
  -- 补上原本由全局处理器完成的两件事：标记该角色已处理、
  -- 记录其势力（此后同势力角色明置不再从元嫡获得先驱）。
  room:setPlayerMark(player, seen_player_mark, 1)
  local kingdom = H.getKingdom(player)
  local first_kingdom = getFirstKingdom(room)
  local unclaimed = kingdom ~= "unknown" and kingdom ~= "wild" and
    first_kingdom ~= kingdom and
    not room:getTag("fengsui_heg__yuandi_seen_" .. kingdom) and
    isFirstInKingdom(room, player, kingdom)
  local count = (unclaimed and not isFirstShownInRoom(room, player)) and 2 or 1
  recordKingdom(room, player)
  H.addHegMark(room, player, "vanguard", count)
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
