local H = require "packages.fengsui.hegemony_util"
local lianxi = fk.CreateSkill { name = "fengsui_heg__lianxi", tags = { Skill.Compulsory } }

-- 新版：选项一改为雷电伤害，选项二改为摸两张牌并横置（不再副将易位）。
local function resolve(self, _, target, player)
  local room = player.room
  local choices = { "fengsui_heg__lianxi_discard", "fengsui_heg__lianxi_chain" }
  local choice = room:askToChoice(target, { choices = choices, skill_name = lianxi.name })
  if choice == "fengsui_heg__lianxi_chain" then
    if target:isAlive() then
      -- 锁定技自动结算的摸牌：不挂技能名，日志里不出现「连徙」。
      target:drawCards(2)
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
    -- 【连徙】是锁定技：张白本人不做任何选择，选项框是给被指定的角色的。
    -- 整段属自动结算，不该再走一次技能发动流程：mute 关配音与「发动【连徙】」
    -- 播报，no_indicate 关指示线，on_cost 直接返回 true 跳过引擎默认的询问框。
    -- 刻意不加 is_delay_effect：锁定技明置武将是国战规则，需要保留。
    mute = true,
    no_indicate = true,
    can_trigger = function(self, _, target, player)
      return target and target:isAlive() and player:hasSkill(lianxi.name) and
        H.compareKingdomWith(target, player)
    end,
    on_cost = function()
      return true
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
