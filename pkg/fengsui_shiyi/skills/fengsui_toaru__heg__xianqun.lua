local H = require "packages.fengsui.hegemony_util"

local xianqun = fk.CreateSkill {
  name = "fengsui_toaru__heg__xianqun",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["fengsui_toaru__heg__xianqun"] = "掀裙",
  [":fengsui_toaru__heg__xianqun"] = "锁定技，已明置武将数小于你的角色无法响应你使用的牌。",
}

-- 只在出牌前把不可响应名单写进 use，引擎在 askToUseCard / askForCard
-- 里都会查 isDisresponsive，因此【闪】【无懈可击】一类响应一并被封死。
xianqun:addEffect(fk.PreCardUse, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xianqun.name, true) and
      data.from == player and data.card ~= nil
  end,
  on_trigger = function(self, event, target, player, data)
    local mine = H.getGeneralsRevealedNum(player)
    local list = table.filter(player.room.alive_players, function(p)
      return H.getGeneralsRevealedNum(p) < mine
    end)
    if #list == 0 then return end
    data.disresponsiveList = data.disresponsiveList or {}
    table.insertTableIfNeed(data.disresponsiveList, list)
  end,
})

return xianqun
