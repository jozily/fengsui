-- 延誉 · 旧版存档（不挂载任何武将，留作 Remake）
-- 旧效果：当一名与你势力相同的角色明置武将牌后，若你的武将牌均明置，你可以令其
-- 选择一项：1.摸两张牌，本轮无法再明置任何武将牌；2.获得一枚阴阳鱼标记，然后你
-- 弃置一张牌并暗置此武将牌。
local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"
local yanyu = fk.CreateSkill { name = "fengsui_heg__yanyuRemake" }

yanyu:addEffect(fk.GeneralRevealed, {
  can_trigger = function(self, _, target, player)
    -- 阵亡者的亮将由国战规则在 GameOverJudge 中强制公开，不属延誉的结算范围。
    return target and target:isAlive() and player:isAlive() and
      player:hasShownSkill(yanyu.name) and
      H.getGeneralsRevealedNum(player) == 2 and
      H.compareKingdomWith(player, target)
  end,
  on_cost = function(self, _, target, player)
    return player.room:askToSkillInvoke(player, {
      skill_name = yanyu.name,
      prompt = "#fengsui_heg__yanyuRemake-invoke::" .. target.id,
    })
  end,
  on_use = function(self, _, target, player)
    local room = player.room
    local choices = {"fengsui_heg__yanyuRemake_draw"}
    if not player:isNude() then table.insert(choices, "fengsui_heg__yanyuRemake_mark") end
    local choice = room:askToChoice(target, {
      choices = choices,
      skill_name = yanyu.name, prompt = "#fengsui_heg__yanyuRemake-choice",
    })
    if choice == "fengsui_heg__yanyuRemake_draw" then
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
          prompt = "#fengsui_heg__yanyuRemake-discard",
        })
      end
      if not player.dead then U.hideSkillGeneral(player, yanyu.name) end
    end
  end,
})

return yanyu
