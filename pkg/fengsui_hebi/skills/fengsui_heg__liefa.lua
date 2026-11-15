local H = require "packages.fengsui.hegemony_util"

local liefa = fk.CreateSkill{
  name = "fengsui_heg__liefa",
  related_skills = {"heg__bingxin", "niaoxiang"},
}

liefa:addEffect("arraysummon", { array_type = "formation" })

local function formsSiege(player)
  for _, victim in ipairs(player.room.alive_players) do
    if victim ~= player and H.inSiegeRelation(player, player, victim) then return true end
  end
  return false
end

-- 两个版本的烈伐都在技能表里，借出的标记必须按技能名隔离，否则其中
-- 一版做全场重算时会把另一版借出去的「冰心」当成残留清掉。
local BORROW_SKILLS = { "fengsui_heg__liefa", "fengsui_heg__liefaRemake2" }

local function bingxinMark(owner)
  return liefa.name .. "_bingxin_" .. owner.id
end

local function niaoxiangMark(owner)
  return liefa.name .. "_niaoxiang_" .. owner.id
end

-- 该角色是否还需保留烈伐借出的「冰心」：武将牌自带，或还有另一名存活且
-- 仍持有烈伐的角色把技能借给了它。
-- 暗置武将牌记的是伪武将名，个别模式下 inGeneralSkills 会取不到武将表；
-- 这里只判断「技能是否武将自带」，取不到就按「不是自带」处理。
local function hasNativeSkill(p, name)
  local ok, place = pcall(H.inGeneralSkills, p, name)
  return ok and place ~= nil
end

local function keepBingxin(room, p, skipMark)
  if hasNativeSkill(p, "heg__bingxin") then return true end
  for _, other in ipairs(room.players) do
    if other:isAlive() then
      for _, skillName in ipairs(BORROW_SKILLS) do
        local m = skillName .. "_bingxin_" .. other.id
        if m ~= skipMark and other:hasSkill(skillName) and p:getMark(m) > 0 then
          return true
        end
      end
    end
  end
  return false
end

local function refreshBorrowed(room, owner, forceOff)
  -- 阵法技在拥有者阵亡、暗置或失去技能后即失效，借出去的技能必须立刻回收。
  local active = not forceOff and owner:isAlive() and owner:hasSkill(liefa.name)
  local formation = active and H.inFormationRelation(owner, owner)
  local bmark = bingxinMark(owner)

  -- 遍历 room.players 而非 alive_players：阵亡者自己身上也可能挂着冰心与
  -- 标记，只扫存活角色会留下残骸。
  for _, p in ipairs(room.players) do
    local should = formation and p:isAlive() and H.inFormationRelation(owner, p)
    if should and p:getMark(bmark) == 0 then
      if not p:hasSkill("heg__bingxin") then
        room:handleAddLoseSkills(p, "heg__bingxin", nil, false, true)
      end
      room:setPlayerMark(p, bmark, 1)
    elseif not should and p:getMark(bmark) > 0 then
      room:setPlayerMark(p, bmark, 0)
      if not keepBingxin(room, p, bmark) then
        room:handleAddLoseSkills(p, "-heg__bingxin", nil, false, true)
      end
    end
  end

  local siege = active and formsSiege(owner)
  local nmark = niaoxiangMark(owner)
  if siege and owner:getMark(nmark) == 0 then
    if not owner:hasSkill("niaoxiang") then
      room:handleAddLoseSkills(owner, "niaoxiang", nil, false, true)
    end
    room:setPlayerMark(owner, nmark, 1)
  elseif not siege and owner:getMark(nmark) > 0 then
    room:setPlayerMark(owner, nmark, 0)
    if not hasNativeSkill(owner, "niaoxiang") then
      room:handleAddLoseSkills(owner, "-niaoxiang", nil, false, true)
    end
  end
end

local refresh = {
  global = true,
  mute = true,
  can_refresh = function(self, event, target, player, data)
    -- 阵亡 / 角色被调离时必须无条件进一次刷新：若霍弋是唯一持有者且已死，
    -- 全场再没有满足条件的人，只靠 hasSkill 判断会让清理根本不执行。
    if event == fk.Death or event == fk.Deathed or event == H.PlayerRemoved then
      return true
    end
    if event == fk.EventLoseSkill then
      return data and data.skill and data.skill.name == liefa.name
    end
    return player:hasSkill(liefa.name, true, true)
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.Death or event == fk.Deathed or event == H.PlayerRemoved then
      -- 直接按死者回收它借出的那一份，不依赖死者是否还在 player 遍历里；
      -- 其余角色各自重算，存活来源借给死者的技能也会一并收回。
      if target then refreshBorrowed(player.room, target, true) end
      refreshBorrowed(player.room, player)
      return
    end
    local losing = event == fk.EventLoseSkill and data and data.skill and
      data.skill.name == liefa.name and (data.who or target) == player
    refreshBorrowed(player.room, player, losing)
  end,
}

liefa:addEffect(fk.TurnStart, refresh)
liefa:addEffect(fk.GeneralRevealed, refresh)
liefa:addEffect(fk.GeneralHidden, refresh)
liefa:addEffect(fk.AfterPropertyChange, refresh)
liefa:addEffect(fk.EventAcquireSkill, refresh)
liefa:addEffect(fk.EventLoseSkill, refresh)
liefa:addEffect(fk.Death, refresh)
liefa:addEffect(fk.Deathed, refresh)
liefa:addEffect(H.PlayerRemoved, refresh)

liefa:addEffect(fk.GeneralRevealed, {
  global = true,
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    -- 阵亡者的武将牌由国战规则在 GameOverJudge 中公开，同样会走本时机。
    -- 对尸体发动换将会重新弹出选将框，故须排除。
    if not target or not target:isAlive() or not player:isAlive() then return false end
    if not player:hasSkill(liefa.name) or not H.compareKingdomWith(target, player) then return false end
    return H.inFormationRelation(player, player) == formsSiege(player)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = liefa.name, prompt = "#fengsui_heg__liefa-transform::" .. target.id,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    -- 变更与否交给被明置者自己决定。
    if room:askToSkillInvoke(target, {
      skill_name = liefa.name,
      prompt = "#fengsui_heg__liefa-be-changed",
    }) then
      H.transformGeneral(room, target, false, false)
    end
  end,
})

Fk:loadTranslationTable {
  ["#fengsui_heg__liefa-be-changed"] = "烈伐：你可以变更副将",
}

return liefa
