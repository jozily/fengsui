-- 张裕【故梦】（旧版【命定】按原名留在 fengsui_heg__mingding.lua 作存档）
--
-- 限定技，当一名拥有“谶”的角色进入濒死状态时，若其副将未被移除，
-- 你可令其移除之并将体力值恢复至1，然后永久获得其“谶”。
--
-- 与旧版命定的区别：只认当前仍持有的「谶」，不再从获得记录里随机补一个；
-- 也不再要求同势力（能持有「谶」本就来自虞照的同势力触发）。
local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local gumeng = fk.CreateSkill {
  name = "fengsui_heg__gumeng",
  tags = { Skill.Limited },
}

local chan_mark = "fengsui_heg__yuzhao_chan"
local wait_mark = "fengsui_heg__yuzhao_wait"
local used_mark = "fengsui_heg__gumeng_used"

local function getChan(target)
  local v = target:getMark(chan_mark)
  return type(v) == "string" and v ~= "" and v or nil
end

gumeng:addEffect(fk.EnterDying, {
  can_trigger = function(self, _, target, player)
    return target and player:hasSkill(self.name) and
      player:getMark(used_mark) == 0 and
      getChan(target) ~= nil and H.hasGeneral(target, true)
  end,
  on_cost = function(self, _, _, player)
    return player.room:askToSkillInvoke(player, {
      skill_name = self.name,
      prompt = "#fengsui_heg__gumeng-invoke",
    })
  end,
  on_use = function(self, _, target, player)
    local room = player.room
    room:setPlayerMark(player, used_mark, 1)
    local chan = getChan(target)

    -- 先清掉临时标记，避免该角色自己的结束阶段把「谶」回收并触发摸牌；副将移除时
    -- 挂在副将上的技能会一并消失，所以移除后再把「谶」补成永久技能。
    room:setPlayerMark(target, chan_mark, 0)
    room:setPlayerMark(target, wait_mark, 0)

    U.removeGeneralByName(target, H.getActualGeneral(target, true))
    room:recover {
      who = target,
      num = math.max(0, 1 - target.hp),
      recoverBy = player,
      skillName = self.name,
    }

    if chan and Fk.skills[chan] and not target:hasSkill(chan, true, true) then
      room:handleAddLoseSkills(target, chan)
    end
  end,
})

return gumeng
