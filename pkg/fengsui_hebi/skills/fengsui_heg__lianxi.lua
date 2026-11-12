local H = require "packages.fengsui.hegemony_util"
local lianxi = fk.CreateSkill { name = "fengsui_heg__lianxi", tags = { Skill.Compulsory } }

-- 新版：选项一改为雷电伤害，选项二改为摸两张牌并横置（不再副将易位）。
local function resolve(self, _, target, player)
  local room = player.room
  local choices = { "fengsui_heg__lianxi_discard", "fengsui_heg__lianxi_chain" }
  local choice = room:askToChoice(target, { choices = choices, skill_name = lianxi.name })
  if choice == "fengsui_heg__lianxi_chain" then
    if target:isAlive() then
      target:drawCards(2, lianxi.name)
      if target:isAlive() then target:setChainState(true) end
    end
    return
  end
  local areas = {}
  for _, area in ipairs({ "h", "e", "j" }) do
    if #target:getCardIds(area) > 0 then
      table.insert(areas, ({ h = "fengsui_heg__lianxi_hand", e = "fengsui_heg__lianxi_equip", j = "fengsui_heg__lianxi_judge" })[area])
    end
  end
  if #areas == 0 then return end
  local area = room:askToChoice(target, { choices = areas, skill_name = lianxi.name })
  local actual = ({ fengsui_heg__lianxi_hand = "h", fengsui_heg__lianxi_equip = "e", fengsui_heg__lianxi_judge = "j" })[area]
  room:throwCard(target:getCardIds(actual), lianxi.name, target, target)
  if target:isAlive() and room.current and room.current:isAlive() then
    room:damage{
      from = target,
      to = room.current,
      damage = 1,
      damageType = fk.ThunderDamage,
      skillName = lianxi.name,
    }
  end
end

for _, timing in ipairs({ fk.GeneralRevealed, fk.GeneralHidden }) do
  lianxi:addEffect(timing, {
    global = true,
    can_trigger = function(self, _, target, player)
      return target and target:isAlive() and player:hasSkill(lianxi.name) and
        H.compareKingdomWith(target, player)
    end,
    on_use = resolve,
  })
end

Fk:loadTranslationTable{
  ["fengsui_heg__lianxi_discard"] = "弃置一个区域所有牌，对当前回合角色造成1点雷电伤害",
  ["fengsui_heg__lianxi_chain"] = "摸两张牌并横置",
  ["fengsui_heg__lianxi_hand"] = "手牌区",
  ["fengsui_heg__lianxi_equip"] = "装备区",
  ["fengsui_heg__lianxi_judge"] = "判定区",
}
return lianxi
