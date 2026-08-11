local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local lingzhi = fk.CreateSkill{
  name = "fengsui_heg__lingzhi",
}

local lingzhi_trigger = {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return (target == player or data.from == player) and target ~= data.from and
      player:hasSkill(lingzhi.name) and
      player:usedSkillTimes(lingzhi.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local opp = (target == player) and data.from or target
    if not opp or opp.dead or player:isNude() then return false end

    local cids = U.chooseCardsFromList(room, player, player:getCardIds("he"), 1, 1,
      "#fengsui_heg__lingzhi", lingzhi.name, true)
    if #cids > 0 then
      event:setCostData(self, { opp = opp, cid = cids[1] })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local opp = event:getCostData(self).opp
    local cid = event:getCostData(self).cid
    room:showCards({cid}, player)

    local cType = Fk:getCardById(cid).type
    local diff_cards = table.filter(opp:getCardIds("he"), function(id) return Fk:getCardById(id).type ~= cType end)
    local choice = "fengsui_heg__lingzhi_damage"

    if #diff_cards > 0 then
       choice = room:askToChoice(opp, {
         choices = {"fengsui_heg__lingzhi_give", "fengsui_heg__lingzhi_damage"},
       })
    end

    if choice == "fengsui_heg__lingzhi_give" then
       local gcid = U.chooseCardsFromList(room, opp, diff_cards, 1, 1,
         "#fengsui_heg__lingzhi-give", lingzhi.name, false)
       if #gcid > 0 then
         room:moveCardTo(gcid, Card.PlayerHand, player, fk.ReasonGive, lingzhi.name, nil, false, opp)
       end
    else
       room:obtainCard(opp, cid, true, fk.ReasonPrey)
       room:damage{ from = player, to = opp, damage = 1, skillName = lingzhi.name }
    end
  end,
}

lingzhi:addEffect(fk.Damaged, lingzhi_trigger)
lingzhi:addEffect(fk.Damage, lingzhi_trigger)

return lingzhi
