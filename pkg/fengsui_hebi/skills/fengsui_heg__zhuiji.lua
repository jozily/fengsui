local Util = require "packages.fengsui.pkg.fengsui_hebi.util"
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
    return player.phase == Player.Play and player:hasShownSkill(ZNAME) and
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
local function reduce(self, player)
  local n = player:getMark(ZNAME .. "-damage")
  if n > 0 then player.room:setPlayerMark(player, ZNAME .. "-damage", n - 1) end
  if n == 1 then
    player.room:setPlayerMark(player, ZNAME .. "-disabled", 0)
    player.room:setPlayerMark(player, "@fengsui_heg__zhuiji", 0)
  end
end
zhuiji:addEffect(fk.Damage, { can_trigger = function(self, _, target, player, data) return target == player and player:hasShownSkill(ZNAME) and player:getMark(ZNAME .. "-damage") > 0 end, on_use = function(self, _, _, player) reduce(self, player) end })
zhuiji:addEffect(fk.Damaged, { can_trigger = function(self, _, target, player, data) return target == player and player:hasShownSkill(ZNAME) and player:getMark(ZNAME .. "-damage") > 0 end, on_use = function(self, _, _, player) reduce(self, player) end })
return zhuiji
