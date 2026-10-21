local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local baoguo = fk.CreateSkill{
  name = "fengsui_heg__baoguoRemake",
  tags = { Skill.Limited },
}

baoguo:addEffect(fk.EnterDying, {
  global = true,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(baoguo.name) or player:usedSkillTimes(baoguo.name, Player.HistoryGame) > 0 then
      return false
    end
    if not H.compareKingdomWith(target, player) then return false end
    return not table.contains(U.getMajorKingdoms(player.room), H.getKingdom(player))
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = baoguo.name,
      prompt = "#fengsui_heg__baoguoRemake-invoke::" .. target.id,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local majors = U.getMajorKingdoms(room)
    local majorPlayers = table.filter(room.alive_players, function(p)
      return table.contains(majors, H.getKingdom(p))
    end)
    local x = #majorPlayers
    local friends = table.filter(room.alive_players, function(p)
      return H.compareKingdomWith(p, player)
    end)
    room:sortByAction(friends)
    for _, p in ipairs(friends) do
      if p:isAlive() then
        local can_remove = H.hasGeneral(p, true)
        local can_give = x > 0 and #p:getCardIds("he") >= x
        local choices = { "fengsui_heg__baoguoRemake_opt2" }
        if can_remove or can_give then table.insert(choices, 1, "fengsui_heg__baoguoRemake_opt1") end
        local choice = room:askToChoice(p, { choices = choices, prompt = "#fengsui_heg__baoguoRemake-choice", skill_name = baoguo.name })
        if choice == "fengsui_heg__baoguoRemake_opt1" then
          local sub_choices = {}
          if can_remove then table.insert(sub_choices, "fengsui_heg__baoguoRemake_remove") end
          if can_give then table.insert(sub_choices, "fengsui_heg__baoguoRemake_give") end
          local sub = room:askToChoice(p, { choices = sub_choices, prompt = "#fengsui_heg__baoguoRemake-subchoice::" .. x, skill_name = baoguo.name })
          if sub == "fengsui_heg__baoguoRemake_remove" then H.removeGeneral(p, true) else
            local cards = U.chooseCardsFromList(room, p, p:getCardIds("he"), x, x, "#fengsui_heg__baoguoRemake-cards::" .. x, baoguo.name, false)
            local tos = room:askToChoosePlayers(p, { targets = majorPlayers, min_num = 1, max_num = 1, prompt = "#fengsui_heg__baoguoRemake-major::" .. x, skill_name = baoguo.name, cancelable = false })
            room:moveCards{ ids = cards, from = p, to = tos[1], toArea = Card.PlayerHand, moveReason = fk.ReasonGive, proposer = p, skillName = baoguo.name }
          end
          if p:isAlive() and p:isWounded() then room:recover { who = p, num = 1, recoverBy = player, skillName = baoguo.name } end
        else p:drawCards(x, baoguo.name) end
      end
    end
  end,
})

return baoguo
