local H = require "packages.fengsui.hegemony_util"
local chongjing = fk.CreateSkill {name = "fengsui_heg__chongjing", tags = {Skill.Compulsory}}
local mark = "@fengsui_heg__chongjing_kingdom-round"
chongjing:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, _, _, player, data)
    return player:hasSkill(self.name) and table.find(data, function(move)
      return move.from == player and move.moveReason == fk.ReasonRecast and #move.moveInfo > 0
    end) ~= nil
  end,
  on_use = function(self, _, _, player, data)
    local room = player.room
    for _, move in ipairs(data) do
      if move.from == player and move.moveReason == fk.ReasonRecast then
        for _, info in ipairs(move.moveInfo) do
          if player.dead then return end
          local targets = table.filter(room.alive_players, function(p)
            return H.getKingdom(p) ~= "unknown" and not table.contains(player:getTableMark(mark), H.getKingdom(p))
          end)
          if #targets == 0 then
            room:loseHp(player, 1, self.name)
          else
            local to = room:askToChoosePlayers(player, {targets = targets, min_num = 1, max_num = 1,
              skill_name = self.name, prompt = "#fengsui_heg__chongjing-target", cancelable = false})[1]
            room:addTableMark(player, mark, H.getKingdom(to))
            local id = info.cardId
            local use
            if room:getCardArea(id) == Card.DiscardPile then
              use = room:askToUseRealCard(to, {pattern = {id}, expand_pile = {id},
                skill_name = self.name, prompt = "#fengsui_heg__chongjing-use", cancelable = true, skip = true})
            end
            if use then room:useCard(use)
            elseif to:isAlive() then room:loseHp(to, 1, self.name) end
          end
        end
      end
    end
  end,
})
return chongjing
