-- 悬河 · 旧版三存档（不挂载任何武将，留作 Remake）
-- 旧效果：主将技，锁定技，你计算体力上限时减少一个单独的阴阳鱼。当你明置此武将牌后，
-- 你本回合使用牌无距离和次数限制；若此时为你的回合外，你获得当前回合角色所有牌
-- 并主副将易位。
local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local xuanhe = fk.CreateSkill{
  name = "fengsui_heg__xuanheRemake3",
  tags = { Skill.Compulsory, Skill.MainPlace },
}

-- 本回合使用牌无距离和次数限制
local free_mark = "fengsui_heg__xuanheRemake3_free-turn"

xuanhe:addEffect(fk.GeneralRevealed, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasShownSkill(xuanhe.name) then return false end
    local place = H.inGeneralSkills(player, xuanhe.name)
    return (place == "m" and data.m) or (place == "d" and data.d)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, free_mark, 1)
    -- 回合外明置：夺走当前回合角色的所有牌，然后易位
    local current = room.current
    if not current or current == player or current.dead then return end
    local ids = current:getCardIds("hej")
    if #ids > 0 then
      room:obtainCard(player, ids, true, fk.ReasonPrey, player, xuanhe.name)
    end
    if player:isAlive() then U.swapGenerals(room, player) end
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
