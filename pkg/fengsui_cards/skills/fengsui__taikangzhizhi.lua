local H = require "packages.fengsui.hegemony_util"

local taikangzhizhi_skill = fk.CreateSkill{
  name = "fengsui__taikangzhizhi_skill",
}

taikangzhizhi_skill:addEffect("cardskill", {
  prompt = "#fengsui__taikangzhizhi_skill",
  can_use = Util.CanUseFixedTarget,
  mod_target_filter = function(self, player, to_select, selected)
    return H.compareKingdomWith(to_select, player, false)
  end,
  on_effect = function(self, room, effect)
    local target = effect.to
    if target.dead then return end

    local draw = target.maxHp - target:getHandcardNum()
    if draw > 0 then target:drawCards(draw, taikangzhizhi_skill.name) end
    -- 仅「明置」的晋势力角色可额外暗置变更副将：
    -- 明置晋势力 kingdom 为 jin；暗置为 unknown，野心家为 wild，均不触发。
    if target.dead or target.kingdom ~= "jin" then return end

    local choice = room:askToChoice(target, {
      choices = {
        "fengsui__taikangzhizhi_opt1",
        "Cancel",
      },
      skill_name = taikangzhizhi_skill.name,
      prompt = "#fengsui__taikangzhizhi-invoke",
    })
    if choice == "fengsui__taikangzhizhi_opt1" then
      H.transformGeneral(room, target, false, true)
    end
  end,
})

taikangzhizhi_skill:addTest(function(room, me)
  local ally, outsider = room.players[2], room.players[3]
  FkTest.runInRoom(function()
    room:setPlayerProperty(me, "kingdom", "wei")
    room:setPlayerProperty(ally, "kingdom", "wei")
    room:setPlayerProperty(outsider, "kingdom", "shu")
    me:throwAllCards("h")
    ally:throwAllCards("h")
    outsider:throwAllCards("h")
    room:useCard{
      from = me,
      card = Fk:cloneCard("fengsui__taikangzhizhi"),
      tos = {},
    }
  end)
  lu.assertEquals(me:getHandcardNum(), me.maxHp)
  lu.assertEquals(ally:getHandcardNum(), ally.maxHp)
  lu.assertEquals(outsider:getHandcardNum(), 0)

  if H.hasGeneral(me, true) then
    local old_main, old_deputy = H.getActualGeneral(me, false), H.getActualGeneral(me, true)
    -- 暗置（kingdom 为 unknown）不触发暗置变更副将
    FkTest.runInRoom(function()
      room:setPlayerProperty(me, "kingdom", "unknown")
      room:setPlayerMark(me, "__heg_kingdom", "jin")
      room:useCard{
        from = me,
        card = Fk:cloneCard("fengsui__taikangzhizhi"),
        tos = {},
      }
    end)
    lu.assertEquals(H.getActualGeneral(me, false), old_main)
    lu.assertEquals(H.getActualGeneral(me, true), old_deputy)

    -- 明置晋势力触发暗置变更副将：副将换成新的晋势力武将并被暗置
    FkTest.setNextReplies(me, {"fengsui__taikangzhizhi_opt1"})
    FkTest.runInRoom(function()
      room:setPlayerProperty(me, "kingdom", "jin")
      room:useCard{
        from = me,
        card = Fk:cloneCard("fengsui__taikangzhizhi"),
        tos = {},
      }
    end)
    lu.assertEquals(H.getActualGeneral(me, false), old_main)
    lu.assertNotEquals(H.getActualGeneral(me, true), old_deputy)
  end
end)

return taikangzhizhi_skill
