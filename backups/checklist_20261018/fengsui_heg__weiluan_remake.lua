local H = require "packages.fengsui.hegemony_util"

local weiluan = fk.CreateSkill{
  name = "fengsui_heg__weiluan",
}

weiluan:addEffect(fk.TargetConfirmed, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(weiluan.name) and
           H.compareKingdomWith(target, player) and H.allGeneralsRevealed(target) and
           data.card and data.card.is_damage_card
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = weiluan.name,
      prompt = "#fengsui_heg__weiluan-invoke::" .. target.id,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    H.doHideGeneral(room, target, target, weiluan.name)

    target:drawCards(2, weiluan.name)
    if target:isAlive() and not target:isKongcheng() then
      local card = room:askToChooseCard(target, {
        target = target,
        flag = "h",
        prompt = "#fengsui_heg__weiluan-top",
        skill_name = weiluan.name,
      })
      if card then
        room:moveCards({
          ids = { card },
          from = target,
          toArea = Card.DrawPile,
          moveReason = fk.ReasonPut,
          proposer = target,
          skillName = weiluan.name,
          drawPilePosition = 1,
          moveVisible = true,
        })
      end
    end
  end,
})

return weiluan
