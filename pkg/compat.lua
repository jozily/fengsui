local H = require "packages.hegemony.util"
local FengsuiH = require "packages.fengsui.hegemony_util"

-- Keep the extended transform contract inside Fengsui so the official
-- hegemony package can remain untouched.
function H.transformGeneral(room, player, isMain, isHidden, num, skillName)
  return FengsuiH.transformGeneral(room, player, isMain, isHidden, num, skillName)
end

function H.wildChooseKingdom(player, generalName)
  local room = player.room
  local allChoices = table.clone(H.wildKingdoms)
  local choices = table.clone(allChoices)
  for _, p in ipairs(room.players) do
    table.removeOne(choices, p.role)
  end

  local choice
  if player.general == generalName and H.kingdomMapper[generalName] and
      H.kingdomMapper[generalName] ~= player.role and table.contains(choices, H.kingdomMapper[generalName]) then
    choice = H.kingdomMapper[generalName]
  else
    if #choices == 0 then choices = table.clone(allChoices) end
    choice = room:askToChoice(player, {
      choices = choices,
      skill_name = "game_rule",
      prompt = "#wild-choose",
      cancelable = false,
      all_choices = allChoices,
    })
  end

  player.role = choice
  room:setPlayerProperty(player, "role_shown", true)
  room:broadcastProperty(player, "role")
  room:sendLog{
    type = "#WildChooseKingdom",
    from = player.id,
    arg = choice,
    arg2 = "wild",
  }
  return choice
end

if not H._fengsuiOriginalInFormationRelation then
  H._fengsuiOriginalInFormationRelation = H.inFormationRelation
  H.inFormationRelation = function(player, target)
    if H._fengsuiOriginalInFormationRelation(player, target) then return true end
    local room = (player and player.room) or (target and target.room) or Fk:currentRoom()
    if not room or not player or not target or not H.compareKingdomWith(player, target) then return false end
    local ignoresRelation = player:getMark("@fengsui_heg__zhouwang-round") > 0 or
      target:getMark("@fengsui_heg__zhouwang-round") > 0 or table.find(room.alive_players, function(p)
      return p:hasSkill("fengsui_heg__chenji") and H.compareKingdomWith(p, player)
    end) ~= nil
    if not ignoresRelation then return false end
    if player ~= target then return true end
    return table.find(room.alive_players, function(p)
      return p ~= player and H.compareKingdomWith(p, player)
    end) ~= nil
  end
end

if not H._fengsuiOriginalInSiegeRelation then
  H._fengsuiOriginalInSiegeRelation = H.inSiegeRelation
  H.inSiegeRelation = function(player, target, victim)
    if H._fengsuiOriginalInSiegeRelation(player, target, victim) then return true end
    if not player or not target or not victim or victim == player or victim == target or
      victim.kingdom == "unknown" or H.compareKingdomWith(player, victim) or
      not H.compareKingdomWith(player, target) then return false end
    return table.find(player.room.alive_players, function(p)
      return p:hasSkill("fengsui_heg__chenji") and H.compareKingdomWith(p, player)
    end) ~= nil
  end
end

-- 戚举会把部分角色暂时置为“未确定势力”。官方阵法召唤技的
-- canUse 仍会用该势力去索引已确定势力人数表，得到 nil 后直接与
-- 人数比较，AI 在生成响应时就会报 “attempt to compare nil with number”。
-- 未确定势力本身不能发动这类阵法召唤技，因此在风随兼容层提前拒绝，
-- 不改动 packages/hegemony 的源文件。
if H.ArraySummonSkill and not H.ArraySummonSkill._fengsuiUnknownKingdomGuard then
  local originalArraySummonCanUse = H.ArraySummonSkill.canUse
  H.ArraySummonSkill.canUse = function(self, player, card)
    if not player or player.kingdom == "unknown" then return false end
    return originalArraySummonCanUse(self, player, card)
  end
  H.ArraySummonSkill._fengsuiUnknownKingdomGuard = true
end

-- 军巍临时获得“付授”时，官方实现会直接索引暗将名 anjiang，
-- 导致首亮或暗置过程中 getInvalidity/技能刷新报错。保留官方逻辑，
-- 但跳过当前仍为暗将的位置。
local fushou = Fk.skills and Fk.skills["heg__fushou"]
if fushou and not fushou._fengsuiSafeSync then
  local function sync(player, losing)
    local room = player and player.room
    if not room then return end
    local Heg = require "packages.hegemony.util"
    local targets = table.filter(room.alive_players, function(p)
      return Heg.compareKingdomWith(p, player)
    end)
    for _, p in ipairs(targets) do
      local main = p.general ~= "anjiang" and Fk.generals[p.general] or nil
      local deputy = p.deputyGeneral ~= "anjiang" and Fk.generals[p.deputyGeneral] or nil
      for _, g in ipairs({main, deputy}) do
        if g then
          for _, name in ipairs(g:getSkillNameList()) do
            local sk = Fk.skill_skels[name]
            local isDeputySkill = sk and sk:hasTag(Skill.DeputyPlace)
            local isMainSkill = sk and sk:hasTag(Skill.MainPlace)
            if (g == main and isDeputySkill) or (g == deputy and isMainSkill) then
              room:handleAddLoseSkills(p, losing and ("-" .. name) or name, nil, true, false)
            end
          end
        end
      end
    end
  end
  fushou.on_acquire = function(player) sync(player, false) end
  fushou.on_lose = function(player) sync(player, true) end
  fushou._fengsuiSafeSync = true
end

-- 允许风随技能给移除武将事件补充触发技能名，完整走官方的
-- GeneralRemoving/GeneralRemoved 特效链，同时保持旧的两参数调用兼容。
if H.removeGeneral and not H._fengsuiRemoveGeneralWithSkill then
  local originalRemoveGeneral = H.removeGeneral
  H.removeGeneral = function(player, isDeputy, skillName)
    if not skillName then return originalRemoveGeneral(player, isDeputy) end
    local data = H.GeneralRemoveData:new{ who = player, isDeputy = isDeputy or false, skillName = skillName }
    local event = H.GameEvent.RemoveGeneral:create(data)
    local _, ret = event:exec()
    return ret
  end
  H._fengsuiRemoveGeneralWithSkill = true
end

if Room and not Room._fengsuiKnownBothWrapped then
  local originalAskToChoice = Room.askToChoice
  Room.askToChoice = function(self, player, params)
    local choice = originalAskToChoice(self, player, params)
    local capture = self._fengsuiKnownBothCapture
    if capture and player == capture.player and params.skill_name == "known_both" then
      capture.choice = choice
    end
    return choice
  end
  Room._fengsuiKnownBothWrapped = true
end

-- 麒麟弓等旧技能使用 card_data 选择牌时没有传 prompt；AI 的卡牌选择
-- 处理器会对 prompt 做字符串解析，因此必须补一个稳定的默认提示。
if Room and not Room._fengsuiChooseCardPromptWrapped then
  local originalAskToChooseCard = Room.askToChooseCard
  Room.askToChooseCard = function(self, player, params)
    if params and not params.prompt then params.prompt = "#fengsui-card-choose" end
    return originalAskToChooseCard(self, player, params)
  end
  Room._fengsuiChooseCardPromptWrapped = true
end

Fk:loadTranslationTable{
  ["#ChangeHiddenGeneral"] = "%from 变更了 %arg（暗置）",
  ["#fengsui-card-choose"] = "请选择一张牌",
}

return H
