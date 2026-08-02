local H = require "packages.hegemony.util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local qingshang = fk.CreateSkill{
  name = "fengsui_heg__qingshang",
  tags = { Skill.Compulsory },
}

qingshang:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qingshang.name) and
      data.from and data.from ~= player and
      U.hasGeneralName(player, "fengsui_heg__caoshi") and
      player:usedSkillTimes(qingshang.name, Player.HistoryGame) == 0 and
      data.damage >= player.hp + player.shield
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    U.removeGeneralByName(player, "fengsui_heg__caoshi")
    data:preventDamage()

    if data.from and data.from:isAlive() and player:isAlive() then
      room:useVirtualCard("ice__slash", nil, data.from, player, qingshang.name, true, {
        bypass_distances = true,
        bypass_times = true,
      })
    end
  end,
})

return qingshang
