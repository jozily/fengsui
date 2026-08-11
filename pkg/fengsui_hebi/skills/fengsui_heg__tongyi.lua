local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local tongyi = fk.CreateSkill{
  name = "fengsui_heg__tongyi",
}

tongyi:addEffect(fk.EnterDying, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(tongyi.name) and H.allGeneralsRevealed(player) and
      data.damage and data.damage.from and not data.damage.from:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = tongyi.name,
      prompt = "#fengsui_heg__tongyi-invoke::" .. data.damage.from.id,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room, from = player.room, data.damage.from
    U.hideSkillGeneral(player, tongyi.name)
    local top = room:getNCards(1)[1]
    if not top then return end
    room:moveCardTo(top, Card.Processing, nil, fk.ReasonJustMove, tongyi.name, nil, true, player)
    local hand = room:askToChooseCard(player, {
      target = from,
      flag = "h",
      skill_name = tongyi.name,
      prompt = "#fengsui_heg__tongyi-show::" .. from.id,
    })
    room:showCards({hand}, from)
    if Fk:getCardById(top):compareColorWith(Fk:getCardById(hand)) then
      room:recover{who = player, num = 1, recoverBy = player, skillName = tongyi.name}
    end
    if room:getCardArea(top) == Card.Processing then
      room:moveCards{
        ids = {top},
        toArea = Card.DrawPile,
        moveReason = fk.ReasonPut,
        proposer = player,
        skillName = tongyi.name,
        moveVisible = true,
        drawPilePosition = 1,
      }
    end
  end,
})

Fk:loadTranslationTable{
  ["#fengsui_heg__tongyi-invoke"] = "通意：你可以暗置此武将牌并亮出牌堆顶与 %dest 的一张手牌",
  ["#fengsui_heg__tongyi-show"] = "通意：请选择 %dest 的一张手牌亮出",
}

return tongyi
