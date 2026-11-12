local H = require "packages.fengsui.hegemony_util"

local guitu = fk.CreateSkill{
  name = "fengsui_heg__guitu",
}

-- 逻辑标记（隐藏）与显示标记分开：显示标记的值必须是空串，
-- 界面上才只出现翻译文本「归土」两个字，不会带出数值或目标 id。
-- 两者都带 -turn 后缀，由引擎在回合开始/结束时一并清除。
local limit_mark = "fengsui_heg__guitu_limit-turn"
local show_mark = "@fengsui_heg__guitu-turn"

guitu:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(guitu.name) and
      data.damage > 1 and H.hasGeneral(player, true)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = guitu.name,
      prompt = "#fengsui_heg__guitu-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    H.removeGeneral(player, true)
    data:preventDamage()
    local from = data.from
    if from and from:isAlive() then
      local room = player.room
      room:setPlayerMark(from, limit_mark, 1)
      room:setPlayerMark(from, show_mark, "")
      -- 记录被限制者，隐藏标记不参与界面显示。
      room:addTableMarkIfNeed(player, "fengsui_heg__guitu_targets-turn", from.id)
      -- 手牌上限已变化，立刻刷新客户端显示（思疾 siji.lua 同款写法）。
      room:broadcastProperty(from, "MaxCards")
    end
  end,
})

guitu:addEffect("maxcards", {
  global = true,
  fixed_func = function(self, player)
    if player:getMark(limit_mark) > 0 then return 0 end
  end,
  -- Player:getMaxCards() 先取所有 fixed_func 的最大值，再叠加所有 correct_func，
  -- 最后才 math.max(..., 0)。只写 fixed_func = 0 时，其它技能的 correct_func
  -- （福绵的 +1、秘计/思疾的 +N 等）会把 0 抬成正数，「手牌上限为0」随之失效。
  -- 这里补一个足够大的负修正，保证最终一定被夹到 0。
  correct_func = function(self, player)
    if player:getMark(limit_mark) > 0 then return -999 end
    return 0
  end,
})

return guitu
