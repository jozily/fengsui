local tanghou = fk.CreateSkill { name = "fengsui_limited_heg__tanghou" }

if not Fk._fengsuiTanghouWrapped then
  local H = require "packages.hegemony.util"
  local original = H.compareKingdomWith
  H.compareKingdomWith = function(from, to, diff, ignore_gouni)
    local room = Fk:currentRoom()
    local current = room and room.logic and room.logic:getCurrentEvent()
    local settling = current and current:findParent(GameEvent.Death, true)
    if not settling and from and to then
      local fromOwner = from:getMark("@fengsui_limited_heg__tanghou-turn")
      local toOwner = to:getMark("@fengsui_limited_heg__tanghou-turn")
      local linked = (fromOwner ~= 0 and (to.id == fromOwner or toOwner == fromOwner)) or
        (toOwner ~= 0 and (from.id == toOwner or fromOwner == toOwner))
      if linked then return not diff end
    end
    return original(from, to, diff, ignore_gouni)
  end
  Fk._fengsuiTanghouWrapped = true
end

Fk:loadTranslationTable {
  ["fengsui_limited_heg__tanghou"] = "唐吼",
  [":fengsui_limited_heg__tanghou"] = "当有角色于你的回合受到伤害后，你可以令其本回合视为与你势力相同（不计算奖惩及胜负）。",
  ["#fengsui_limited_heg__tanghou-invoke"] = "唐吼：是否令 %dest 本回合视为与你势力相同？",
  ["@fengsui_limited_heg__tanghou-turn"] = "唐吼同势力",
}

tanghou:addEffect(fk.Damaged, {
  can_trigger = function(self, event, target, player, data)
    return player.room.current == player and player:hasSkill(tanghou.name) and target:isAlive() and target ~= player
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, { skill_name = tanghou.name, prompt = "#fengsui_limited_heg__tanghou-invoke::" .. target.id })
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(target, "@fengsui_limited_heg__tanghou-turn", player.id)
  end,
})

return tanghou
