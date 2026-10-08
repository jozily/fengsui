local dunmeng = fk.CreateSkill { name = "fengsui_heg__dunmeng" }
local U = require "packages.fengsui.pkg.fengsui_hebi.util"
local function invokeDunmeng(self, player)
  local current = player.room.current; if not current then return end
  local Hcmd = require "packages.hegemony.util"
  local choice, commands = Hcmd.askToStartCommand(player,{skill_name=self.name,no_log=true}); if not choice then return end
  table.removeOne(commands,choice)
  player.room:sendLog{type="#AskCommandTo",from=player.id,to={current.id},arg=self.name,toast=true}
  local executed=Hcmd.Command({tos={current},skillName=self.name,command=choice,from=player,forced=false})
  if not executed then Hcmd.Command({tos={current},skillName=self.name,command=commands[1],from=player,forced=true})
  elseif player.general~="anjiang" and player.deputyGeneral~="anjiang" then local place=U.getSkillPlace(player,self.name); if place~=nil then player:hideGeneral(place) end end
  if not executed then
    player.room:setPlayerMark(current, "fengsui_heg__dunmeng_redirect", player.id)
  end
  local damage_cards=table.filter(player.room.discard_pile,function(id) return Fk:getCardById(id).is_damage_card end)
  if #damage_cards>0 then player.room:obtainCard(player,damage_cards[math.random(#damage_cards)],true,fk.ReasonPrey,player,self.name) end
end
dunmeng:addEffect(fk.GeneralShown, { global = true,
  can_trigger = function(self, _, target, player) return target == player and player:hasSkill(self.name) end,
  on_use = function(self, _, _, player) invokeDunmeng(self, player) end,
})
dunmeng:addEffect(fk.Damaged, { global = true,
  can_trigger = function(self, _, target, player) return target == player and player:hasSkill(self.name) end,
  on_use = function(self, _, _, player) invokeDunmeng(self, player) end,
})
dunmeng:addEffect(fk.DamageCaused, { global = true,
  can_trigger = function(self, _, target, player, data)
    return target == player and data and data.from == target and target:getMark("fengsui_heg__dunmeng_redirect") > 0
  end,
  on_use = function(self, _, target, player, data)
    local owner = target.room:getPlayerById(target:getMark("fengsui_heg__dunmeng_redirect"))
    if owner and owner:isAlive() then data.from = owner end
    target.room:setPlayerMark(target, "fengsui_heg__dunmeng_redirect", 0)
  end,
})
return dunmeng
