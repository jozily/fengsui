local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local jinshi = fk.CreateSkill { name = "fengsui_heg__jinshi", tags = { Skill.Compulsory } }
local readyMark = "fengsui_heg__jinshi_ready"

-- 前半段「明置另一张武将牌后失去体力并暗置此武将牌」要求另一张武将牌在
-- 触发时确实处于明置状态。fk.GeneralRevealed 延迟到回合／阶段退出才触发，
-- 期间【取声】等技能可能已把另一张暗置；只看事件的 data 会把这种情形
-- 误判为可以发动。这里改按当前 general / deputyGeneral 判断暗将 "anjiang"，
-- 与【取声】的 otherGeneralShown 写法保持一致。
local function otherGeneralStillShown(player)
  local place = U.getSkillPlace(player, jinshi.name)
  if place == nil then return false end
  local name
  if place then
    name = player.general          -- 技能在副将，另一张是主将
  else
    name = player.deputyGeneral    -- 技能在主将，另一张是副将
  end
  return type(name) == "string" and name ~= "" and name ~= "anjiang"
end

local function otherGeneralShown(player, data)
  local place = U.getSkillPlace(player, jinshi.name)
  if place == nil or data == nil then return false end
  return (place == false and data.d ~= nil) or (place == true and data.m ~= nil)
end

local function punish(player)
  -- 同一触发链里若别的技能先把另一张暗置，这里再兜一次
  if not otherGeneralStillShown(player) then return end
  local place = U.getSkillPlace(player, jinshi.name)
  if place == nil then return end
  local room = player.room
  player:hideGeneral(place)
  room:loseHp(player, 1, jinshi.name)
  room:setPlayerMark(player, readyMark, 1)
end

jinshi:addEffect(fk.GeneralRevealed, {
  global = true,
  can_trigger = function(self, _, target, player, data)
    return target == player and player:hasShownSkill(jinshi.name) and
      otherGeneralStillShown(player) and otherGeneralShown(player, data)
  end,
  on_use = function(self, _, _, player)
    punish(player)
  end,
})

jinshi:addEffect(H.GeneralTransformed, {
  global = true,
  can_trigger = function(self, _, target, player, data)
    local place = U.getSkillPlace(player, jinshi.name)
    return target == player and player:hasShownSkill(jinshi.name) and
      otherGeneralStillShown(player) and
      place ~= nil and data and data.isMain == place
  end,
  on_use = function(self, _, _, player)
    punish(player)
  end,
})

jinshi:addEffect(H.GeneralRemoved, {
  global = true,
  can_trigger = function(self, _, target, player, data)
    local place = U.getSkillPlace(player, jinshi.name)
    return target == player and player:hasShownSkill(jinshi.name) and
      otherGeneralStillShown(player) and
      place ~= nil and data and data.isDeputy ~= place
  end,
  on_use = function(self, _, _, player)
    punish(player)
  end,
})

-- 「下次明置此武将牌时摸牌」是对已受惩罚的补偿，不受另一张武将牌
-- 是否明置的限制，只看技能本身明置且带有 readyMark。
jinshi:addEffect(fk.GeneralRevealed, {
  can_trigger = function(self, _, target, player, data)
    local place = U.getSkillPlace(player, jinshi.name)
    if place == nil or data == nil then return false end
    local thisShown = (place == false and data.m ~= nil) or (place == true and data.d ~= nil)
    return target == player and player:hasShownSkill(jinshi.name) and
      player:getMark(readyMark) > 0 and thisShown
  end,
  on_use = function(self, _, _, player)
    local room = player.room
    room:setPlayerMark(player, readyMark, 0)
    local n = player.maxHp - player:getHandcardNum()
    if n > 0 then room:drawCards(player, n, jinshi.name) end
  end,
})

return jinshi
