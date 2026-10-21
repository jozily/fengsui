local H = require "packages.fengsui.hegemony_util"

local weiluan = fk.CreateSkill{
  name = "fengsui_heg__weiluan",
}

weiluan:addEffect(fk.TargetConfirmed, {
  anim_type = "defensive",
  can_trigger = function(self, _, target, player, data)
    return target and player:hasSkill(weiluan.name) and
      H.compareKingdomWith(target, player) and data.card and data.card.trueName == "slash"
  end,
  on_cost = function(self, _, target, player)
    return player.room:askToSkillInvoke(player, {
      skill_name = weiluan.name,
      prompt = "#fengsui_heg__weiluan-invoke::" .. target.id,
    })
  end,
  on_use = function(self, _, target)
    if target:isAlive() then
      target:setChainState(true)
      target:drawCards(1, weiluan.name)
    end
  end,
})

return weiluan
