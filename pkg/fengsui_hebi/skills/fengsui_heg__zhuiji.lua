local H = require "packages.fengsui.hegemony_util"
local usedSkills = {
  ["yinyangfish_skill&"] = "yinyangfish",
  ["vanguard_skill&"] = "vanguard",
  ["companion_skill&"] = "companion",
  ["wild_skill&"] = "wild",
  ["fengsui_heg_ascend_skill&"] = "fengsui_heg_ascend",
  ["fengsui_heg__descend_skill&"] = "fengsui_heg__descend",
  ["fengsui_heg_ascend_skill"] = "fengsui_heg_ascend",
  ["fengsui_heg__descend_skill"] = "fengsui_heg__descend",
}
local function markForSkill(data)
  local skill = data and data.skill
  if not skill then return nil end
  local names = { skill.name }
  if skill.getSkeleton then table.insert(names, skill:getSkeleton().name) end
  for _, name in ipairs(names) do
    if usedSkills[name] then return usedSkills[name] end
    local plain = name and name:gsub("&$", "")
    if plain and usedSkills[plain] then return usedSkills[plain] end
  end
end
local zhuiji = fk.CreateSkill { name = "fengsui_heg__zhuiji" }
local ZNAME = "fengsui_heg__zhuiji"
zhuiji:addEffect("active", {
  anim_type = "draw", card_num = 0, target_num = 0, card_filter = Util.FalseFunc, target_filter = Util.FalseFunc,
  can_use = function(self, player)
    local last = player:getMark(ZNAME .. "-last")
    return player.phase == Player.Play and
      player:getMark(ZNAME .. "-disabled") == 0 and type(last) == "string" and last ~= ""
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local mark = player:getMark(ZNAME .. "-last")
    if type(mark) ~= "string" or mark == "" then return end
    H.addHegMark(player, mark)
    room:setPlayerMark(player, ZNAME .. "-disabled", 1)
    room:setPlayerMark(player, "@fengsui_heg__zhuiji", 1)
    local markText = Fk:translate("@!!" .. mark, "zh_CN")
    room:setPlayerMark(player, ZNAME .. "-damage", utf8.len(markText) or #markText)
  end,
})
zhuiji:addEffect(fk.AfterSkillEffect, {
  global = true,
  can_refresh = function(self, _, target, player, data)
    return target == player and markForSkill(data) ~= nil
  end,
  on_refresh = function(self, _, target, player, data)
    player.room:setPlayerMark(player, ZNAME .. "-last", markForSkill(data))
  end,
})

-- 标记技能之外，拟字、周王、陈梦等技能会直接消耗国战标记。统一的
-- HegMarkChanged 事件逐枚记录这些消耗，保证“最后弃置的标记”不会漏记；
-- 一次弃多枚时事件按弃置顺序发出，最后一次写入即玩家后选的那枚。
zhuiji:addEffect(H.HegMarkChanged, {
  global = true,
  can_refresh = function(self, _, target, player, data)
    return target == player and data and data.action == "use" and
      table.contains({ "yinyangfish", "vanguard", "companion", "wild", "fengsui_heg_ascend", "fengsui_heg__descend" }, data.markName)
  end,
  on_refresh = function(self, _, _, player, data)
    player.room:setPlayerMark(player, ZNAME .. "-last", data.markName)
  end,
})
-- 按实际伤害点数累计：一次造成或受到 2 点伤害即减 2，扣到 0 时解除失效。
-- 伤害事件在增减伤结算之后触发，data.damage 是最终点数；0 点的虚拟伤害不累计。
local function reduce(self, player, data)
  local n = player:getMark(ZNAME .. "-damage")
  if n <= 0 then return end
  local amount = math.floor(tonumber(data and data.damage) or 0)
  if amount < 1 then return end
  local left = n - amount
  if left <= 0 then
    player.room:setPlayerMark(player, ZNAME .. "-damage", 0)
    player.room:setPlayerMark(player, ZNAME .. "-disabled", 0)
    player.room:setPlayerMark(player, "@fengsui_heg__zhuiji", 0)
  else
    player.room:setPlayerMark(player, ZNAME .. "-damage", left)
  end
end
-- 追迹的失效解除是自动结算：受到/造成伤害扣减计数无需玩家手动确认。
-- on_cost 覆盖默认 askToSkillInvoke（否则非锁定触发技会弹“是否发动”）；
-- priority=0 让 TriggerEvent 跳过 choose-trigger 询问直接结算。
local function silentReduce(self, _, _, player, data) reduce(self, player, data) end
zhuiji:addEffect(fk.Damage, {
  priority = 0,
  can_trigger = function(self, _, target, player, data)
    return target == player and player:hasSkill(ZNAME) and player:getMark(ZNAME .. "-damage") > 0
  end,
  on_cost = function() return true end,
  on_use = silentReduce,
})
zhuiji:addEffect(fk.Damaged, {
  priority = 0,
  can_trigger = function(self, _, target, player, data)
    return target == player and player:hasSkill(ZNAME) and player:getMark(ZNAME .. "-damage") > 0
  end,
  on_cost = function() return true end,
  on_use = silentReduce,
})
return zhuiji
