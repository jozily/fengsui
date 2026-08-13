local H = require "packages.fengsui.hegemony_util"

local shunyi = fk.CreateSkill{name = "fengsui_limited_heg__shunyi"}

Fk:loadTranslationTable{
  ["fengsui_limited_heg__shunyi"] = "瞬移",
  [":fengsui_limited_heg__shunyi"] = "出牌阶段限一次，你可以移动场上一张牌。若你以此法移动的角色中有与你势力不同的角色，此技能失效直至你造成伤害。",
  ["#fengsui_limited_heg__shunyi"] = "瞬移：移动场上一张牌",
  ["@fengsui_limited_heg__shunyi"] = "瞬移失效",
}

shunyi:addEffect("active", {
  anim_type = "control",
  prompt = "#fengsui_limited_heg__shunyi",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(shunyi.name, Player.HistoryPhase) == 0 and
      player:getMark("@fengsui_limited_heg__shunyi") == 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    if not room or #room:canMoveCardInBoard() == 0 then return end
    local tos = room:askToChooseToMoveCardInBoard(player, {
      prompt = "#fengsui_limited_heg__shunyi", skill_name = shunyi.name, cancelable = false,
    })
    if #tos ~= 2 then return end
    local result = room:askToMoveCardInBoard(player, {
      target_one = tos[1], target_two = tos[2], skill_name = shunyi.name,
    })
    if result and (not H.compareKingdomWith(player, result.from) or
      not H.compareKingdomWith(player, result.to)) then
      room:setPlayerMark(player, "@fengsui_limited_heg__shunyi", 1)
    end
  end,
})

shunyi:addEffect(fk.Damage, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@fengsui_limited_heg__shunyi") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@fengsui_limited_heg__shunyi", 0)
  end,
})

shunyi:addEffect("invalidity", {
  invalidity_func = function(self, from, skill)
    return from:getMark("@fengsui_limited_heg__shunyi") > 0 and skill.name == shunyi.name
  end,
})

return shunyi
