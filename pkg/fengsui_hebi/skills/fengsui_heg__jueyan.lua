local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local jueyan = fk.CreateSkill{
  name = "fengsui_heg__jueyan",
}

jueyan:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jueyan.name) and #data:getAllTargets() == 1 and
      data.to ~= player and H.allGeneralsRevealed(player)
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = jueyan.name,
      prompt = "#fengsui_heg__jueyan-invoke::" .. data.to.id,
    }) then
      event:setCostData(self, { to = data.to })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).to
    U.hideSkillGeneral(player, jueyan.name)

    local choices = {"fengsui_heg__jueyan_draw"}
    if not player:isKongcheng() and not to:isKongcheng() then
      table.insert(choices, "fengsui_heg__jueyan_pindian")
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      prompt = "#fengsui_heg__jueyan-choice::" .. to.id,
      skill_name = jueyan.name,
    })

    if choice == "fengsui_heg__jueyan_draw" then
      player:drawCards(1, jueyan.name)
    else
      local pindian = player:pindian({to}, jueyan.name)
      local result = pindian.results[to]
      if result and result.winner == player then
        room:damage{from = player, to = to, damage = 1, skillName = jueyan.name}
      elseif result and result.winner == to then
        room:damage{from = to, to = player, damage = 1, skillName = jueyan.name}
      end
    end
  end,
})

return jueyan
