local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"
local yanyu = fk.CreateSkill { name = "fengsui_heg__yanyu" }

yanyu:addEffect(fk.GeneralRevealed, {
  can_trigger = function(self, _, target, player)
    return target and player:hasShownSkill(yanyu.name) and
      H.getGeneralsRevealedNum(player) == 2 and
      H.compareKingdomWith(player, target)
  end,
  on_cost = function(self, _, target, player)
    return player.room:askToSkillInvoke(player, {
      skill_name = yanyu.name,
      prompt = "#fengsui_heg__yanyu-invoke::" .. target.id,
    })
  end,
  on_use = function(self, _, target, player)
    local room = player.room
    local choices = {"fengsui_heg__yanyu_draw"}
    if not player:isNude() then table.insert(choices, "fengsui_heg__yanyu_mark") end
    local choice = room:askToChoice(target, {
      choices = choices,
      skill_name = yanyu.name, prompt = "#fengsui_heg__yanyu-choice",
    })
    if choice == "fengsui_heg__yanyu_draw" then
      for _, deputy in ipairs({false, true}) do
        if H.hasGeneral(target, deputy) then
          U.prohibitReveal(target, deputy, yanyu.name, "round", "延誉 禁亮")
        end
      end
      target:drawCards(2, yanyu.name)
    else
      H.addHegMark(target, "yinyangfish")
      if not player.dead and not player:isNude() then
        room:askToDiscard(player, {
          min_num = 1, max_num = 1, include_equip = true,
          cancelable = false, skill_name = yanyu.name,
          prompt = "#fengsui_heg__yanyu-discard",
        })
      end
      if not player.dead then U.hideSkillGeneral(player, yanyu.name) end
    end
  end,
})

return yanyu
