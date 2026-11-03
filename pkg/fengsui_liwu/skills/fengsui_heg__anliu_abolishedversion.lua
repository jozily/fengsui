-- 暗流 · 废除副将版存档（不挂载任何武将，留作 abolishedversion）
-- 效果：锁定技，当你受到或造成伤害后，若为本局累计第X次，受伤角色废除副将并令N+1，
-- 否则其随机执行摸N张牌或暗置变更副将（X为场上势力数，N初始为0至多为5）。
local H = require "packages.fengsui.hegemony_util"

local anliu = fk.CreateSkill {
  name = "fengsui_heg__anliu_abolishedversion",
  tags = { Skill.Compulsory },
}

local damage_mark = "fengsui_heg__anliu_abolishedversion_damage"
local cycle_mark = "fengsui_heg__anliu_abolishedversion_cycle"
local initialized_mark = "fengsui_heg__anliu_abolishedversion_initialized"

local function resetDisplay(room, player)
  room:setPlayerMark(player, damage_mark, 0)
  room:setPlayerMark(player, cycle_mark, 0)
  room:setPlayerMark(player, "@fengsui_heg__anliu_abolishedversion", "0/0")
end

anliu:addEffect(fk.GeneralRevealed, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasShownSkill(anliu.name) and
      player:getMark(initialized_mark) == 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, initialized_mark, 1)
    resetDisplay(player.room, player)
  end,
})

anliu:addAcquireEffect(function(self, player)
  player.room:setPlayerMark(player, initialized_mark, 0)
  player.room:setPlayerMark(player, damage_mark, 0)
  player.room:setPlayerMark(player, cycle_mark, 0)
  player.room:setPlayerMark(player, "@fengsui_heg__anliu_abolishedversion", "0/0")
end)

local function kingdomCount(room)
  local n = 0
  for _, count in pairs(H.getKingdomPlayersNum(room)) do
    if count and count > 0 then n = n + 1 end
  end
  return math.max(1, n)
end

local function countDamage(self, player, data)
    local room = player.room
    local victim = data.to
    if not victim or not victim:isAlive() then return end
    local x = kingdomCount(room)
    local progress = (tonumber(player:getMark(damage_mark)) or 0) + 1
    local n = tonumber(player:getMark(cycle_mark)) or 0
    room:setPlayerMark(player, damage_mark, progress)
    room:setPlayerMark(player, "@fengsui_heg__anliu_abolishedversion", string.format("%d/%d", progress, n))
    if progress >= x then
      if H.hasGeneral(victim, true) then
        -- 用主技能名而非 self.name：countDamage 由 #…_3_trig 触发子技能调用时
        -- self.name 带 # 前缀，废除特效白名单匹配不上。
        -- @! 图章标记用于客户端 Photo 换 abolished 士兵图（picMarks 同步）。
        room:setPlayerMark(victim, "@!fengsui_abolish_deputy", 1)
        H.removeGeneral(victim, true, anliu.name)
        room:setPlayerMark(victim, "fengsui_heg__abolish_deputy_state", 1)
      end
      room:setPlayerMark(player, damage_mark, 0)
      n = math.min(n + 1, 5) -- N 至多为 5
      room:setPlayerMark(player, cycle_mark, n)
      room:setPlayerMark(player, "@fengsui_heg__anliu_abolishedversion", string.format("0/%d", n))
      return
    end
    if math.random(2) == 1 then
      if n > 0 then room:drawCards(victim, n, self.name) end
    elseif H.hasGeneral(victim, true) then
      H.transformGeneral(room, victim, false, true, 1, self.name)
    else
      if n > 0 then room:drawCards(victim, n, self.name) end
    end
end

anliu:addEffect(fk.Damage, {
  global = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and data and data.from == player
  end,
  on_use = function(self, event, target, player, data)
    countDamage(self, player, data)
  end,
})

anliu:addEffect(fk.Damaged, {
  global = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data and data.to == player
  end,
  on_use = function(self, event, target, player, data)
    countDamage(self, player, data)
  end,
})

Fk:loadTranslationTable {
  ["@fengsui_heg__anliu_abolishedversion"] = "暗流",
}

return anliu
