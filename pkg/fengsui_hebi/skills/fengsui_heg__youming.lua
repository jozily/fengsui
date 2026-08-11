local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local youming = fk.CreateSkill{
  name = "fengsui_heg__youming",
}

youming:addEffect(fk.TargetConfirmed, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(youming.name) and
      H.allGeneralsRevealed(player) and data.from and data.from ~= player and
      not data.from:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = youming.name,
      prompt = "#fengsui_heg__youming-invoke::" .. data.from.id,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    U.hideSkillGeneral(player, youming.name)
    local selected = U.chooseCardsFromList(room, player, data.from:getCardIds("h"), 1, 1,
      "#fengsui_heg__youming-top::" .. data.from.id, youming.name, false)
    local id = selected[1]
    if not id then return end
    room:moveCards{
      ids = {id},
      from = data.from,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonPut,
      proposer = player,
      skillName = youming.name,
      moveVisible = false,
      visiblePlayers = {player, data.from},
      drawPilePosition = 1,
    }
  end,
})

youming:addEffect(fk.EnterDying, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(youming.name) and
      H.allGeneralsRevealed(player) and data.damage and data.damage.from and
      not data.damage.from:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = youming.name,
      prompt = "#fengsui_heg__youming-dying::" .. data.damage.from.id,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from = data.damage.from
    U.hideSkillGeneral(player, youming.name)
    local top = room:getNCards(1)[1]
    if not top then return end
    room:moveCardTo(top, Card.Processing, nil, fk.ReasonJustMove, youming.name, nil, true, player)
    local hand = room:askToChooseCard(player, {
      target = from,
      flag = "h",
      skill_name = youming.name,
      prompt = "#fengsui_heg__youming-show::" .. from.id,
    })
    room:showCards({hand}, from)
    if Fk:getCardById(top):compareColorWith(Fk:getCardById(hand)) then
      room:recover{who = player, num = 1, recoverBy = player, skillName = youming.name}
    end
    if room:getCardArea(top) == Card.Processing then
      room:moveCards{
        ids = {top},
        toArea = Card.DrawPile,
        moveReason = fk.ReasonPut,
        proposer = player,
        skillName = youming.name,
        moveVisible = true,
        drawPilePosition = 1,
      }
    end
  end,
})

return youming
