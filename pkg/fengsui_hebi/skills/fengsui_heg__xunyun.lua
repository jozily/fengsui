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
      local choices = {"xunyun_hideAll"}
      if H.getActualGeneral(from, true) and H.getActualGeneral(from, true) ~= "" then
        table.insert(choices, 1, "xunyun_removeDeputy")
      end
      local choice = room:askToChoice(from, {
        choices = choices,
        skill_name = xunyun.name,
        prompt = "#fengsui_heg__xunyun-choice::" .. player.id,
      })
      if choice == "xunyun_removeDeputy" then
        H.removeGeneral(from, true)
      else
        if from.general ~= "anjiang" then from:hideGeneral(false) end
        if from.deputyGeneral ~= "anjiang" then from:hideGeneral(true) end
        local mark = from:getTableMark(MarkEnum.RevealProhibited .. "-round")
        table.insertIfNeed(mark, "m")
        table.insertIfNeed(mark, "d")
        room:setPlayerMark(from, MarkEnum.RevealProhibited .. "-round", mark)
      end
    end

    local candidates = table.filter(room.alive_players, function(p)
      return p ~= player and p ~= from and H.compareKingdomWith(p, player)
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

Fk:loadTranslationTable{
  ["xunyun_removeDeputy"] = "移除副将",
  ["xunyun_hideAll"] = "暗置所有武将牌且本轮无法明置",
  ["#fengsui_heg__xunyun-choice"] = "勋殒：你导致 %dest 濒死，请选择一项",
  ["#fengsui_heg__xunyun-change"] = "勋殒：你可以令另一名同势力角色合璧或变更副将",
}

return xunyun
