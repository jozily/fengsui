-- 延誉（贾谧）
-- 当一名同势力角色明置武将牌后，你可以令其选择一项：1.摸两张牌；
-- 2.本回合使用牌无次数距离限制。
local H = require "packages.fengsui.hegemony_util"

local yanyu = fk.CreateSkill { name = "fengsui_heg__yanyu" }

-- 本回合使用牌无次数距离限制
local free_mark = "fengsui_heg__yanyu_free-turn"

yanyu:addEffect(fk.GeneralRevealed, {
  can_trigger = function(self, _, target, player)
    -- 阵亡者的亮将由国战规则在 GameOverJudge 中强制公开，不属延誉的结算范围。
    return target and target:isAlive() and player:isAlive() and
      player:hasShownSkill(yanyu.name) and
      H.compareKingdomWith(player, target)
  end,
  on_cost = function(self, _, target, player)
    return player.room:askToSkillInvoke(player, {
      skill_name = yanyu.name,
      prompt = "#fengsui_heg__yanyu-invoke::" .. target.id,
    })
  end,
  on_use = function(self, _, target, player)
    local room = player.room
    local choice = room:askToChoice(target, {
      choices = { "fengsui_heg__yanyu_draw", "fengsui_heg__yanyu_free" },
      skill_name = yanyu.name,
      prompt = "#fengsui_heg__yanyu-choice",
    })
    if choice == "fengsui_heg__yanyu_draw" then
      target:drawCards(2, yanyu.name)
    else
      room:addPlayerMark(target, free_mark, 1)
    end
  end,
})

yanyu:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card)
    return player:getMark(free_mark) > 0
  end,
  bypass_distances = function(self, player, skill, card)
    return player:getMark(free_mark) > 0
  end,
})

return yanyu
