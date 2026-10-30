local H = require "packages.fengsui.hegemony_util"

local shenqing = fk.CreateSkill {
  name = "fengsui_heg__shenqing",
  tags = { Skill.Limited },
}

shenqing:addEffect("active", {
  anim_type = "support",
  prompt = "#fengsui_heg__shenqing-invoke",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player.phase == Player.Play and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local friends = table.filter(room.alive_players, function(p)
      return H.compareKingdomWith(player, p)
    end)
    for _, target in ipairs(friends) do
      if target:isAlive() then
        local invoke = room:askToSkillInvoke(target, {
          skill_name = shenqing.name,
          prompt = "#fengsui_heg__shenqing-hebi::" .. player.id,
        })
        if invoke then
          H.askToHebiOrTransform(room, target, shenqing.name, false)
        end
      end
    end
  end,
})

Fk:loadTranslationTable {
  ["fengsui_heg__shenqing"] = "申情",
  [":fengsui_heg__shenqing"] = "限定技，出牌阶段，你可以令所有同势力角色依次选择是否<a href='heg__hebi'>合璧</a>。",
  ["#fengsui_heg__shenqing-invoke"] = "申情：令所有同势力角色依次选择是否合璧",
  ["#fengsui_heg__shenqing-hebi"] = "申情：%src 令你选择是否合璧",
}

shenqing:addTest(function(room, me)
  lu.assertEquals(type(H.askToHebiOrTransform), "function")
  lu.assertEquals(Fk:translate("give"), "交给")
  lu.assertEquals(Fk:translate("fengsui_hebi"), "烽燧燎原-合璧")
  lu.assertEquals(Fk:translate("fengsui_hebi_choice"), "合璧")
  lu.assertEquals(Fk:translate("fengsui_transform"), "变更副将")
end)

return shenqing
