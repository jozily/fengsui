-- 悬河（周处）
-- 锁定技，当你明置武将牌后，你于本回合使用牌无距离和次数限制，
-- 若此时为你的回合外，你重铸所有手牌并失去此技能。
local H = require "packages.fengsui.hegemony_util"

local xuanhe = fk.CreateSkill{
  name = "fengsui_heg__xuanhe",
  tags = { Skill.Compulsory },
}

-- 本回合使用牌无距离和次数限制
local free_mark = "fengsui_heg__xuanhe_free-turn"

xuanhe:addEffect(fk.GeneralRevealed, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(xuanhe.name) then return false end
    -- 明置任意一张武将牌均触发
    return data and (data.m or data.d)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, free_mark, 1)
    -- 回合外明置：重铸所有手牌并失去此技能
    local current = room.current
    if not current or current == player or current.dead then return end
    local ids = player:getCardIds("h")
    if #ids > 0 then
      room:recastCard(ids, player, xuanhe.name)
    end
    room:handleAddLoseSkills(player, "-" .. xuanhe.name, xuanhe.name, false, true)
  end,
})

xuanhe:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card)
    return player:getMark(free_mark) > 0
  end,
  bypass_distances = function(self, player, skill, card)
    return player:getMark(free_mark) > 0
  end,
})

return xuanhe
