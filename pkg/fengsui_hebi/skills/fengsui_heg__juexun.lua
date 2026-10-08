local H = require "packages.fengsui.hegemony_util"
local Util = require "packages.fengsui.pkg.fengsui_hebi.util"
local juexun = fk.CreateSkill { name = "fengsui_heg__juexun" }
juexun:addEffect(fk.AfterCardsMove, { can_trigger = function(self, _, target, player, data) return target == player and player:hasSkill(self.name) and player:getHandcardNum() == 0 and player:getMark("fengsui_heg__juexun_ready") == 0 end,
    on_cost = function(self, _, _, player) return player.room:askToSkillInvoke(player, { skill_name = self.name, prompt = "#fengsui_heg__juexun-invoke" }) end,
    on_use = function(self, _, _, player) player.room:setPlayerMark(player, "fengsui_heg__juexun_ready", 1) end })
  juexun:addEffect(fk.DamageCaused, { can_trigger = function(self, _, target, player, data) return player:hasSkill(self.name) and player:getMark("fengsui_heg__juexun_ready") > 0 and data and data.damage and data.from == player end,
    on_use = function(self, _, _, player, data) data.damageType = fk.FireDamage; player.room:setPlayerMark(player, "fengsui_heg__juexun_ready", 0) end })
  juexun:addEffect(fk.Damaged, { can_trigger = function(self, _, target, player, data) return target == player and player:hasSkill(self.name) and data and data.damageType == fk.FireDamage end,
    on_use = function(self, _, _, player) player.room:drawCards(player, 2, self.name); player:setChainState(true) end })

return juexun
