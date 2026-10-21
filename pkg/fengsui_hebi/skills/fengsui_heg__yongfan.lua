local yongfan = fk.CreateSkill {
  name = "fengsui_heg__yongfan",
}

local function otherTarget(event, player, data)
  if event == fk.Damage then return data and data.to end
  return data and data.from
end

local function spec(event)
  return {
    anim_type = "support",
    can_trigger = function(self, _, target, player, data)
      local other = otherTarget(event, player, data)
      return target == player and player:hasSkill(yongfan.name) and other and other ~= player and other:isAlive()
    end,
    on_cost = function(self, eventObj, target, player, data)
      local other = otherTarget(event, player, data)
      return player.room:askToSkillInvoke(player, {
        skill_name = yongfan.name,
        prompt = "#fengsui_heg__yongfan-invoke::" .. other.id,
      })
    end,
    on_use = function(self, _, target, player, data)
      local other = otherTarget(event, player, data)
      if not other or other.dead then return end
      player.room:useVirtualCard("await_exhausted", nil, player, { player, other }, yongfan.name, true)
    end,
  }
end

yongfan:addEffect(fk.Damage, spec(fk.Damage))
yongfan:addEffect(fk.Damaged, spec(fk.Damaged))

Fk:loadTranslationTable {
  ["fengsui_heg__yongfan"] = "雍番",
  [":fengsui_heg__yongfan"] = "当你受到或造成伤害后，你可以视为使用一张仅指定你与目标或伤害来源的【以逸待劳】。",
  ["#fengsui_heg__yongfan-invoke"] = "雍番：是否视为使用一张仅指定你与 %dest 的【以逸待劳】？",
}

return yongfan
