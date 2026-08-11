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
    if from and from:isAlive() then
      if H.getActualGeneral(from, true) and H.getActualGeneral(from, true) ~= "" then
        H.removeGeneral(from, true)
      end
      room:setPlayerMark(from, "@fengsui_heg__xunyun_nochange", 1)
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
      cancelable = true,
    })
    if #chosen > 0 then
      H.askToHebiOrTransform(room, chosen[1], xunyun.name, false)
    end
  end,
})

xunyun:addEffect(H.GeneralTransforming, {
  global = true,
  can_trigger = function(self, event, target, player, data)
    return target:getMark("@fengsui_heg__xunyun_nochange") > 0 and not data.isMain
  end,
  on_use = function(self, event, target, player, data)
    return true
  end,
})

Fk:loadTranslationTable{
  ["#fengsui_heg__xunyun-change"] = "勋殒：你可以令另一名同势力角色合璧或变更副将",
  ["@fengsui_heg__xunyun_nochange"] = "勋殒：无法变更副将",
}

return xunyun
