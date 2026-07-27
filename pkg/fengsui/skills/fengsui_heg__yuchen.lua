local H = require "packages.hegemony.util"

local yuchen = fk.CreateSkill{
  name = "fengsui_heg__yuchen",
}

yuchen:addEffect("active", {
  anim_type = "support",
  prompt = "#fengsui_heg__yuchen-invoke",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(yuchen.name, Player.HistoryPhase) == 0 and H.getGeneralsRevealedNum(player) > 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and H.compareKingdomWith(to_select, player) and H.hasGeneral(to_select, true)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    
    -- 此处借用 swapDeputy 作为易位表现
    H.swapDeputy(room, player, target)
    
    -- 判断新组合体力
    local g1 = player.general == "anjiang" and player:getMark("__heg_general") or player.general
    local d1 = player.deputyGeneral == "anjiang" and player:getMark("__heg_deputy") or player.deputyGeneral
    local g2 = target.general == "anjiang" and target:getMark("__heg_general") or target.general
    local d2 = target.deputyGeneral == "anjiang" and target:getMark("__heg_deputy") or target.deputyGeneral
    
    local hp1 = Fk.generals[g1].maxHp == Fk.generals[d1].maxHp
    local hp2 = Fk.generals[g2].maxHp == Fk.generals[d2].maxHp
    
    if hp1 and hp2 then
       H.addHegMark(player, "companion")
    else
       H.addHegMark(player, "yinyangfish")
    end
  end,
})

Fk:loadTranslationTable{
  ["fengsui_heg__yuchen"] = "毓尘",
  [":fengsui_heg__yuchen"] = "出牌阶段限一次，你可使用另一张武将牌与一名其他同势力角色的对应武将牌<a href='heg__yiwei'>易位</a>，若在两个新的组合中主副将体力值均相等/不等，你获得一枚珠联璧合/阴阳鱼标记。",
  ["#fengsui_heg__yuchen-invoke"] = "毓尘：选择一名同势力角色与其进行副将易位，并结算新组合获取标记",
}
return yuchen
