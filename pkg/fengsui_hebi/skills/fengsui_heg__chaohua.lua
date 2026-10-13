local H = require "packages.fengsui.hegemony_util"
local Util = require "packages.fengsui.pkg.fengsui_hebi.util"
local chaohua = fk.CreateSkill { name = "fengsui_heg__chaohua" }
chaohua:addEffect("active", { card_num=0,target_num=1,
  can_use=function(self,p) return p:hasShownSkill(self.name) and p:usedSkillTimes(self.name,Player.HistoryPhase)==0 end,
  card_filter=Util.FalseFunc,
  target_filter=function(self,p,to,sel) return #sel==0 and to~=p and H.getGeneralsRevealedNum(to)==2 end,
  on_use=function(self,room,effect)
    local t=effect.tos[1]
    local place = room:askToChoice(effect.from, { choices = { "fengsui_heg__chaohua_main", "fengsui_heg__chaohua_deputy" }, skill_name = self.name })
    local is_deputy = place == "fengsui_heg__chaohua_deputy"
    local gname = is_deputy and t.deputyGeneral or t.general
    local g = Fk.generals[gname]
    local choices={"fengsui_heg__chaohua_double"}
    if effect.from:getMark("fengsui_heg__chaohua_transform-used") == 0 then
      table.insert(choices, "fengsui_heg__chaohua_transform")
    end
    local choice=room:askToChoice(effect.from,{choices=choices,skill_name=self.name})
    if choice=="fengsui_heg__chaohua_double" then
      if g then for _,sk in ipairs(g:getSkillNameList(true)) do if t:usedSkillTimes(sk,Player.HistoryRound)>0 then t:setSkillUseHistory(sk,0,Player.HistoryRound) end end end
      t:hideGeneral(is_deputy)
      Util.prohibitReveal(t, is_deputy, self.name, "turn")
      room:addPlayerMark(t,"fengsui_heg__chaohua_double-turn",1)
    else
      t:hideGeneral(is_deputy)
      Util.prohibitReveal(t, is_deputy, self.name, "turn")
      if not is_deputy and g then for _,sk in ipairs(g:getSkillNameList(true)) do local obj=Fk.skills[sk]; if obj and obj:hasTag(Skill.Limited) then t:setSkillUseHistory(sk,0,Player.HistoryGame) end end end
      H.transformGeneral(room,t,false,false,1,self.name)
      -- “移除此选项”属于朝华发动者的长期记录，不能记在目标角色身上。
      room:setPlayerMark(effect.from,"fengsui_heg__chaohua_transform-used",1)
    end
  end,
})
return chaohua
