local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local yunie = fk.CreateSkill{
  name = "fengsui_heg__yunie",
}

yunie:addEffect(fk.AskForRetrial, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yunie.name) and H.allGeneralsRevealed(player) and
      #player.room:canMoveCardInBoard() > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if not room:askToSkillInvoke(player, {
      skill_name = yunie.name,
      prompt = "#fengsui_heg__yunie-invoke::" .. target.id,
    }) then return false end

    local tos = room:askToChooseToMoveCardInBoard(player, {
      prompt = "#fengsui_heg__yunie-move",
      skill_name = yunie.name,
      cancelable = true,
    })
    if #tos == 2 then
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    U.hideSkillGeneral(player, yunie.name)

    local tos = event:getCostData(self).tos
    local moved = room:askToMoveCardInBoard(player, {
      target_one = tos[1],
      target_two = tos[2],
      skill_name = yunie.name,
    })
    if not moved then return end

    local old_id = data.card:getEffectiveId()
    local vcard = Fk:cloneCard(data.card.name, moved.card.suit, moved.card.number)
    vcard.skillName = yunie.name
    data.card = vcard
    room:sendLog{
      type = "#ChangedJudge",
      from = player.id,
      to = {data.who.id},
      arg = yunie.name,
      arg2 = vcard:toLogString(),
    }
    if old_id and room:getCardArea(old_id) == Card.Processing then
      room:moveCardTo(old_id, Card.DiscardPile, nil, fk.ReasonJudge,
        yunie.name, nil, true, player)
    end
  end,
})

yunie:addEffect(fk.AfterCardsMove, {
  global = true,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(yunie.name, true, true) then return false end
    local is_deputy = U.getSkillPlace(player, yunie.name)
    if is_deputy == nil then return false end
    if (is_deputy and player.deputyGeneral ~= "anjiang") or
      (not is_deputy and player.general ~= "anjiang") then return false end

    for _, move in ipairs(data) do
      if move.from == player then
        for _, info in ipairs(move.moveInfo) do
          if (info.fromArea == Card.PlayerHand and player:isKongcheng()) or
            (info.fromArea == Card.PlayerEquip and #player:getCardIds("e") == 0) or
            (info.fromArea == Card.PlayerJudge and #player:getCardIds("j") == 0) then
            return true
          end
        end
      end
    end
    return false
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = yunie.name,
      prompt = "#fengsui_heg__yunie-reveal",
    })
  end,
  on_use = function(self, event, target, player, data)
    U.revealSkillGeneral(player, yunie.name)
  end,
})

return yunie
