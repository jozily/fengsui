local H = require "packages.fengsui.hegemony_util"

local xinmai = fk.CreateSkill{
  name = "fengsui_heg__xinmai",
}

local slash_mark = "fengsui_heg__xinmai_slashes-turn"

xinmai:addEffect(fk.AfterCardsMove, {
  global = true,
  mute = true,
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(xinmai.name) and table.find(data, function(move)
      return move.toArea == Card.DiscardPile and table.find(move.moveInfo, function(info)
        return Fk:getCardById(info.cardId).trueName == "slash"
      end)
    end) ~= nil
  end,
  on_refresh = function(self, event, target, player, data)
    local slashes = player:getTableMark(slash_mark)
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          if Fk:getCardById(info.cardId).trueName == "slash" then
            table.insertIfNeed(slashes, info.cardId)
          end
        end
      end
    end
    player.room:setPlayerMark(player, slash_mark, slashes)
  end,
})

xinmai:addEffect("active", {
  anim_type = "offensive",
  prompt = "#fengsui_heg__xinmai-active",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    local room = Fk:currentRoom()
    return player:usedSkillTimes(xinmai.name, Player.HistoryPhase) == 0 and
      table.find(player:getTableMark(slash_mark), function(id)
        return room:getCardArea(id) == Card.DiscardPile
      end) ~= nil
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player, target = effect.from, effect.tos[1]
    local cards = table.filter(player:getTableMark(slash_mark), function(id)
      return room:getCardArea(id) == Card.DiscardPile
    end)
    if #cards == 0 then return end
    room:obtainCard(target, cards, true, fk.ReasonJustMove, player, xinmai.name)
    if target.dead then return end

    local choices = {"fengsui_heg__xinmai_damage"}
    if H.allGeneralsRevealed(target) then
      table.insert(choices, "fengsui_heg__xinmai_hide")
    end
    local choice = room:askToChoice(target, {
      choices = choices,
      prompt = "#fengsui_heg__xinmai-choice",
      skill_name = xinmai.name,
    })
    if choice == "fengsui_heg__xinmai_damage" then
      room:damage{from = player, to = target, damage = 1, damageType = fk.ThunderDamage, skillName = xinmai.name}
    else
      H.doHideGeneral(room, target, target, xinmai.name)
    end
  end,
})

return xinmai
