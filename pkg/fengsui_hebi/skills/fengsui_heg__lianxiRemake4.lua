-- 连徙原版存档（2026-11-12 改版前）：弃置一个区域并对当前回合角色造成1点伤害／摸两张牌并副将易位。
-- 现役版本见 fengsui_heg__lianxi.lua，此文件未挂载到任何武将，仅作回退备份。
local H = require "packages.fengsui.hegemony_util"
local lianxi = fk.CreateSkill { name = "fengsui_heg__lianxiRemake4", tags = { Skill.Compulsory } }
local function resolve(self, _, target, player)
  local room = player.room
  local choices = { "fengsui_heg__lianxiRemake4_discard" }
  if target ~= player and H.hasGeneral(player, true) and H.hasGeneral(target, true) then
    table.insert(choices, "fengsui_heg__lianxiRemake4_swap")
  end
  local choice = room:askToChoice(target, {choices = choices, skill_name = lianxi.name})
  -- 连徙触发目标为技能拥有者本人时，不允许通过旧客户端/异常回包选择易位。
  if target == player and choice == "fengsui_heg__lianxiRemake4_swap" then
    choice = "fengsui_heg__lianxiRemake4_discard"
  end
  if choice == "fengsui_heg__lianxiRemake4_swap" then
    target:drawCards(2, lianxi.name)
    H.swapDeputy(room, player, target)
    return
  end
  local areas = {}
  for _, area in ipairs({ "h", "e", "j" }) do
    if #target:getCardIds(area) > 0 then
      table.insert(areas, ({h = "fengsui_heg__lianxiRemake4_hand", e = "fengsui_heg__lianxiRemake4_equip", j = "fengsui_heg__lianxiRemake4_judge"})[area])
    end
  end
  if #areas == 0 then return end
  local area = room:askToChoice(target, {choices = areas, skill_name = lianxi.name})
  local actual = ({fengsui_heg__lianxiRemake4_hand = "h", fengsui_heg__lianxiRemake4_equip = "e", fengsui_heg__lianxiRemake4_judge = "j"})[area]
  room:throwCard(target:getCardIds(actual), lianxi.name, target, target)
  if target:isAlive() and room.current and room.current:isAlive() then
    room:damage{from = target, to = room.current, damage = 1, skillName = lianxi.name}
  end
end
for _, timing in ipairs({fk.GeneralRevealed, fk.GeneralHidden}) do
  lianxi:addEffect(timing, {
    global = true,
    can_trigger = function(self, _, target, player)
      return target and target:isAlive() and player:hasSkill(lianxi.name) and H.compareKingdomWith(target, player)
    end,
    on_use = resolve,
  })
end
Fk:loadTranslationTable{
  ["fengsui_heg__lianxiRemake4_discard"] = "弃置一个区域所有牌，对当前回合角色造成1点伤害",
  ["fengsui_heg__lianxiRemake4_swap"] = "摸两张牌并与连徙拥有者副将易位",
  ["fengsui_heg__lianxiRemake4_hand"] = "手牌区",
  ["fengsui_heg__lianxiRemake4_equip"] = "装备区",
  ["fengsui_heg__lianxiRemake4_judge"] = "判定区",
}
return lianxi
