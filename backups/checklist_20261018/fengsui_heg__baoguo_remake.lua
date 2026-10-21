local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local baoguo = fk.CreateSkill{
  name = "fengsui_heg__baoguo",
  tags = {Skill.Limited},
}

baoguo:addEffect(fk.EnterDying, {
  global = true,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(baoguo.name) or player:usedSkillTimes(baoguo.name, Player.HistoryGame) > 0 then return false end
    if not H.compareKingdomWith(target, player) then return false end
    local majors = U.getMajorKingdoms(player.room)
    return not table.contains(majors, H.getKingdom(player))
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = baoguo.name,
      prompt = "#fengsui_heg__baoguo-invoke::" .. target.id,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local majors = U.getMajorKingdoms(room)
    local major_players = table.filter(room.alive_players, function(p)
      return table.contains(majors, H.getKingdom(p))
    end)
    local X = #major_players

    local friends = table.filter(room.alive_players, function(p)
      return H.compareKingdomWith(p, player)
    end)
    room:sortByAction(friends)
    for _, p in ipairs(friends) do
      if p:isAlive() then
        local choices = {}
        if X > 0 and #major_players > 0 and #p:getCardIds("he") >= X then
          table.insert(choices, "fengsui_heg__baoguo_give")
        end
        if H.hasGeneral(p, true) and #(room.general_pile or room.generalPile or {}) > 0 then
          table.insert(choices, "fengsui_heg__baoguo_transform")
        end
        if #choices > 0 then
          local choice = #choices == 1 and choices[1] or room:askToChoice(p, { choices = choices, prompt = "#fengsui_heg__baoguo-choice", skill_name = baoguo.name })
          if choice == "fengsui_heg__baoguo_give" then
            local cards = U.chooseCardsFromList(room, p, p:getCardIds("he"), X, X, "#fengsui_heg__baoguo-cards::" .. X, baoguo.name, false)
            local tos = room:askToChoosePlayers(p, { targets = major_players, min_num = 1, max_num = 1, prompt = "#fengsui_heg__baoguo-major::" .. X, skill_name = baoguo.name, cancelable = false })
            room:moveCards{ ids = cards, from = p, to = tos[1], toArea = Card.PlayerHand, moveReason = fk.ReasonGive, proposer = p, skillName = baoguo.name }
            if p:isAlive() and p:isWounded() then room:recover{ who = p, num = 1, recoverBy = player, skillName = baoguo.name } end
          else
            H.transformGeneral(room, p, false, false, 3, baoguo.name)
          end
        end
      end
    end
  end,
})

return baoguo
