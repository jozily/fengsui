-- 申情原版存档（2026-11-12 改版前）：出牌阶段限一次，令一名同势力角色合璧或令两名角色副将易位。
-- 现役版本见 fengsui_heg__shenqing.lua，此文件未挂载到任何武将，仅作回退备份。
local H = require "packages.fengsui.hegemony_util"

local shenqing = fk.CreateSkill {
  name = "fengsui_heg__shenqingRemake2",
}

shenqing:addEffect("active", {
  anim_type = "support",
  prompt = "#fengsui_heg__shenqingRemake2-invoke",
  card_num = 0,
  min_target_num = 1,
  max_target_num = 2,
  target_filter = function(self, player, to_select, selected)
    return H.compareKingdomWith(player, to_select) and
      not table.contains(selected, to_select) and #selected < 2
  end,
  can_use = function(self, player)
    return player.phase == Player.Play and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local targets = table.filter(effect.tos or {}, function(p) return p and p:isAlive() end)
    if #targets == 0 then return end
    if #targets == 1 then
      H.askToHebiOrTransform(room, targets[1], shenqing.name, false)
      return
    end
    local choice = room:askToChoice(player, {
      choices = { "fengsui_heg__shenqingRemake2_hebi", "fengsui_heg__shenqingRemake2_swap" },
      skill_name = shenqing.name,
      prompt = "#fengsui_heg__shenqingRemake2-choice",
    })
    if choice == "fengsui_heg__shenqingRemake2_hebi" then
      local to = room:askToChoosePlayers(player, {
        targets = targets, min_num = 1, max_num = 1,
        skill_name = shenqing.name, prompt = "#fengsui_heg__shenqingRemake2-hebi",
      })
      if #to > 0 then H.askToHebiOrTransform(room, to[1], shenqing.name, false) end
    else
      H.swapDeputy(room, targets[1], targets[2])
    end
  end,
})

Fk:loadTranslationTable {
  ["fengsui_heg__shenqingRemake2"] = "申情",
  [":fengsui_heg__shenqingRemake2"] = "出牌阶段限一次，你可以选择场上至多两名同势力角色，然后选择一项：1.令其中一名角色<a href='heg__hebi'>合璧</a>；2.令两名角色副将<a href='heg__yiwei'>易位</a>。",
  ["#fengsui_heg__shenqingRemake2-invoke"] = "申情：选择至多两名同势力角色",
  ["#fengsui_heg__shenqingRemake2-choice"] = "申情：请选择一项",
  ["#fengsui_heg__shenqingRemake2-hebi"] = "申情：选择一名角色令其合璧",
  ["fengsui_heg__shenqingRemake2_hebi"] = "令其中一名角色合璧",
  ["fengsui_heg__shenqingRemake2_swap"] = "令两名角色副将易位",
}

shenqing:addTest(function(room, me)
  lu.assertEquals(type(H.askToHebiOrTransform), "function")
  lu.assertEquals(Fk:translate("give"), "交给")
  lu.assertEquals(Fk:translate("fengsui_hebi"), "烽燧燎原-合璧")
  lu.assertEquals(Fk:translate("fengsui_hebi_choice"), "合璧")
  lu.assertEquals(Fk:translate("fengsui_transform"), "变更副将")
end)

return shenqing
