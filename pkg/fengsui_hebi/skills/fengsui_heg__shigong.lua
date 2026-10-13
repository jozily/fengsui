local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"
local shigong = fk.CreateSkill { name = "fengsui_heg__shigong", tags = { Skill.Limited } }

shigong:addEffect(fk.EnterDying, {
  can_trigger = function(self, _, target, player)
    return target == player and player:hasShownSkill(self.name) and player.room.current ~= player and
      player:getMark("fengsui_heg__shigong_used") == 0 and H.hasGeneral(player, true)
  end,
  on_use = function(self, _, _, player)
    local room = player.room
    room:setPlayerMark(player, "fengsui_heg__shigong_used", 1)
    U.removeGeneralByName(player, H.getActualGeneral(player, true))
    local current = room.current
    if not current then return end
    local choice = room:askToChoice(current, {
      choices = { "fengsui_heg__shigong_gain", "fengsui_heg__shigong_full" },
      skill_name = self.name,
    })
    if choice == "fengsui_heg__shigong_gain" then
      room:handleAddLoseSkills(current, "fengsui_heg__dulu")
      room:drawCards(current, current.maxHp, self.name)
      room:recover { who = player, num = math.max(0, 1 - player.hp), recoverBy = player, skillName = self.name }
    else
      local missing = player.maxHp - player.hp
      if missing > 0 then
        room:recover { who = player, num = missing, recoverBy = player, skillName = self.name }
      end
    end
  end,
})
return shigong
