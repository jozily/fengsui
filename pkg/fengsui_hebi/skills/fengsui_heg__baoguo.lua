local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local baoguo = fk.CreateSkill { name = "fengsui_heg__baoguo", tags = { Skill.Limited } }

baoguo:addEffect(fk.EnterDying, {
  global = true,
  can_trigger = function(self, _, target, player)
    local room = player.room
    return player:hasSkill(baoguo.name) and player:usedSkillTimes(baoguo.name, Player.HistoryGame) == 0 and
      target and H.compareKingdomWith(target, player) and player.kingdom ~= "unknown" and
      H.isSmallKingdomPlayer(player) and #U.getMajorKingdoms(room) > 0 and
      table.find(room.alive_players, function(p)
        return H.compareKingdomWith(p, player) and not p:isNude()
      end) ~= nil
  end,
  on_cost = function(self, event, target, player)
    return player.room:askToSkillInvoke(player, {
      skill_name = baoguo.name, prompt = "#fengsui_heg__baoguo-invoke::" .. target.id,
    })
  end,
  on_use = function(self, _, _, player)
    local room = player.room
    local friends = table.filter(room.alive_players, function(p) return H.compareKingdomWith(p, player) end)
    room:sortByAction(friends)
    for _, p in ipairs(friends) do
      if p:isAlive() and not p:isNude() and room:askToSkillInvoke(p, {
        skill_name = baoguo.name, prompt = "#fengsui_heg__baoguo-execute",
      }) then
        local majors = table.filter(room.alive_players, function(q)
          return q:isAlive() and H.isBigKingdomPlayer(q)
        end)
        if #majors > 0 then
          local to = room:askToChoosePlayers(p, {
            targets = majors, min_num = 1, max_num = 1,
            prompt = "#fengsui_heg__baoguo-major", skill_name = baoguo.name,
            cancelable = false,
          })[1]
          if to then
            local ids = p:getCardIds("he")
            if #ids > 0 then
              room:moveCards{ ids = ids, from = p, to = to, toArea = Card.PlayerHand,
                moveReason = fk.ReasonGive, proposer = p, skillName = baoguo.name }
            end
            if p:isAlive() then
              room:recover{ who = p, num = 1, recoverBy = player, skillName = baoguo.name }
              if p:isAlive() and H.hasGeneral(p, true) then
                H.transformGeneral(room, p, false, false, 1, baoguo.name)
              end
            end
          end
        end
      end
    end
  end,
})

return baoguo
