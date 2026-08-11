local H = require "packages.fengsui.hegemony_util"

local taikangzhizhi_skill = fk.CreateSkill{
  name = "fengsui__taikangzhizhi_skill",
}

local function swapMainAndDeputy(room, player)
  if not player.deputyGeneral or player.deputyGeneral == "" then return false end
  local main = H.getActualGeneral(player, false)
  local deputy = H.getActualGeneral(player, true)
  local main_hidden = player.general == "anjiang"
  local deputy_hidden = player.deputyGeneral == "anjiang"

  room:changeHero(player, deputy, false, false, false, false, false)
  room:changeHero(player, main, false, true, false, false, false)
  if deputy_hidden then player:hideGeneral(false) end
  if main_hidden then player:hideGeneral(true) end
  return true
end

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
    if target.dead or H.getKingdom(target) ~= "jin" then return end

    local choice = room:askToChoice(target, {
      choices = {
        "fengsui__taikangzhizhi_opt1",
        "fengsui__taikangzhizhi_opt2",
        "Cancel",
      },
      skill_name = taikangzhizhi_skill.name,
      prompt = "#fengsui__taikangzhizhi-invoke",
    })
    if choice == "fengsui__taikangzhizhi_opt1" then
      H.transformGeneral(room, target, false, true)
    elseif choice == "fengsui__taikangzhizhi_opt2" then
      swapMainAndDeputy(room, target)
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

    FkTest.setNextReplies(me, {"fengsui__taikangzhizhi_opt2"})
    FkTest.runInRoom(function()
      room:setPlayerProperty(me, "kingdom", "jin")
      room:useCard{
        from = me,
        card = Fk:cloneCard("fengsui__taikangzhizhi"),
        tos = {},
      }
    end)
    lu.assertEquals(H.getActualGeneral(me, false), old_deputy)
    lu.assertEquals(H.getActualGeneral(me, true), old_main)
  end
end)

return taikangzhizhi_skill
