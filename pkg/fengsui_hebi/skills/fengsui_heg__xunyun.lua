-- 勋殒（李娴）
-- 锁定技，当你首次进入濒死状态时，你令伤害来源移除副将，
-- 然后令一名其他同势力角色合璧。
local H = require "packages.fengsui.hegemony_util"

local xunyun = fk.CreateSkill{
  name = "fengsui_heg__xunyun",
  tags = { Skill.Compulsory },
}

xunyun:addEffect(fk.EnterDying, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xunyun.name) and
      player:usedSkillTimes(xunyun.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from = data.damage and data.damage.from
    -- 移除副将（普通移除，非废除）
    if from and from:isAlive() and H.hasGeneral(from, true) then
      if H.getActualGeneral(from, true) and H.getActualGeneral(from, true) ~= "" then
        H.removeGeneral(from, true, xunyun.name)
      end
    end

    local candidates = table.filter(room.alive_players, function(p)
      return p ~= player and H.compareKingdomWith(p, player)
    end)
    if #candidates == 0 then return end
    local chosen = room:askToChoosePlayers(player, {
      targets = candidates,
      min_num = 1,
      max_num = 1,
      skill_name = xunyun.name,
      prompt = "#fengsui_heg__xunyun-change",
      cancelable = false,
    })
    if #chosen > 0 then
      H.askToHebiOrTransform(room, chosen[1], xunyun.name, true)
    end
  end,
})

Fk:loadTranslationTable{
  ["#fengsui_heg__xunyun-change"] = "勋殒：令另一名同势力角色合璧",
}

return xunyun
