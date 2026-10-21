local H = require "packages.fengsui.hegemony_util"
local chongjing = fk.CreateSkill { name = "fengsui_heg__chongjing", tags = { Skill.Compulsory } }

chongjing:addEffect(fk.AfterCardsMove, {
  global = true,
  can_trigger = function(self, _, _, player, data)
    return player:hasShownSkill(self.name) and data and table.find(data, function(move)
      return move.moveReason == fk.ReasonRecast and move.moveInfo and #move.moveInfo > 0
    end) ~= nil
  end,
  on_use = function(self, _, _, player, data)
    local room = player.room
    for _, move in ipairs(data) do
      if move.moveReason == fk.ReasonRecast and move.moveInfo then
        for _, info in ipairs(move.moveInfo) do
          local card = Fk:getCardById(info.cardId)
          if card then
            local mark_name = "@fengsui_heg__chongjing_kingdom-round"
            local used = player:getTableMark(mark_name)
            local tos = table.filter(room.alive_players, function(p)
              return p ~= player and H.getKingdom(p) ~= "unknown" and not table.contains(used, H.getKingdom(p))
            end)
            if #tos == 0 then return end
            local chosen = room:askToChoosePlayers(player, { targets = tos, min_num = 1, max_num = 1, skill_name = self.name, prompt = "#fengsui_heg__chongjing-target", cancelable = false })[1]
            if not chosen then return end
            room:addTableMark(player, mark_name, H.getKingdom(chosen))
            room:obtainCard(chosen, card, true, fk.ReasonPrey, player, self.name)
            local use = room:askToUseCard(chosen, { skill_name = self.name, pattern = card.name, cancelable = true, prompt = "#fengsui_heg__chongjing-use" })
            if not use then room:loseHp(chosen, 1) end
          end
        end
      end
    end
  end,
})

return chongjing
