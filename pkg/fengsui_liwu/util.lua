local H = require "packages.fengsui.hegemony_util"

local U = {}

-- 访客技能不允许改变武将牌状态，避免借来的技能留下无法回收的武将牌效果。
function U.isGeneralStateSkill(skill)
  if not skill then return false end
  local skeleton = skill.getSkeleton and skill:getSkeleton() or skill
  local description = Fk:translate(":" .. skeleton.name)
  if not description or description == ":" .. skeleton.name then return false end
  if not description:find("武将牌", 1, true) then return false end
  for _, word in ipairs({ "明置", "暗置", "移除", "变更" }) do
    if description:find(word, 1, true) then return true end
  end
  return false
end

function U.getMajorKingdoms(room)
  local kingdoms = {}
  for _, player in ipairs(room.alive_players) do
    if H.isBigKingdomPlayer(player) then
      table.insertIfNeed(kingdoms, H.getKingdom(player))
    end
  end
  return kingdoms
end

function U.chooseCardsFromList(room, player, cards, min_num, max_num, prompt, skill_name, cancelable)
  if #cards < min_num then return {} end
  local selected, choice = room:askToChooseCardsAndChoice(player, {
    cards = cards,
    choices = {"OK"},
    cancel_choices = cancelable and {"Cancel"} or {},
    min_num = min_num,
    max_num = math.min(max_num, #cards),
    prompt = prompt,
    skill_name = skill_name,
  })
  if choice == "Cancel" then return {} end
  return selected
end

-- Return names backed by physical cards in the currently loaded card pool.
-- This keeps view-as skills from offering derived or non-deck cards.
function U.getNationalCardNames(types)
  local names = {}
  local wanted = {}
  for _, card_type in ipairs(types or {}) do wanted[card_type] = true end
  for _, id in ipairs(Fk:getAllCardIds()) do
    local card = Fk:getCardById(id)
    if card and not card.is_derived and
      ((wanted.basic and card.type == Card.TypeBasic) or
       (wanted.trick and card:isCommonTrick())) then
      table.insertIfNeed(names, card.name)
    end
  end
  return names
end

function U.isMainGeneralSkill(player, skill_name)
  return H.inGeneralSkills(player, skill_name) == "m"
end

function U.inSameQueue(player, target)
  return H.inFormationRelation(player, target)
end

function U.getSkillPlace(player, skill_name)
  for _, is_deputy in ipairs({false, true}) do
    local general_name = H.getActualGeneral(player, is_deputy)
    local general = Fk.generals[general_name]
    if general and table.contains(general:getSkillNameList(true), skill_name) then
      return is_deputy
    end
  end
end

function U.getGeneralPlace(player, general_name)
  for _, is_deputy in ipairs({false, true}) do
    if H.getActualGeneral(player, is_deputy) == general_name then
      return is_deputy
    end
  end
end

function U.hasGeneralName(player, general_name)
  return U.getGeneralPlace(player, general_name) ~= nil
end

-- Keep target-count checks consistent with the 0.5.20 chengxian implementation.
function U.getLegalTargetNum(player, card)
  if player:prohibitUse(card) or not player:canUse(card) then return 0 end
  if card.skill:getMinTargetNum() == 0 and not card.multiple_targets then
    return 1
  end
  local count = 0
  local room = player.room or Fk:currentRoom()
  if not room then return 0 end
  for _, target in ipairs(room.alive_players) do
    if not player:isProhibited(target, card) and
      card.skill:modTargetFilter(player, target, {}, card) then
      count = count + 1
    end
  end
  return count
end

function U.removeGeneralByName(player, general_name)
  local is_deputy = U.getGeneralPlace(player, general_name)
  if is_deputy == nil then return false end
  H.removeGeneral(player, is_deputy)
  return true
end

function U.revealSkillGeneral(player, skill_name)
  local is_deputy = U.getSkillPlace(player, skill_name)
  if is_deputy == nil then return false end
  if (is_deputy and player.deputyGeneral ~= "anjiang") or (not is_deputy and player.general ~= "anjiang") then
    return false
  end
  player:revealGeneral(is_deputy)
  return true
end

function U.hideSkillGeneral(player, skill_name)
  return H.hideBySkillName(player, skill_name)
end

function U.revealOneGeneral(target)
  if target.general == "anjiang" then
    target:revealGeneral(false)
    return true
  end
  if target.deputyGeneral == "anjiang" then
    target:revealGeneral(true)
    return true
  end
  return false
end

function U.swapGenerals(room, player)
  if not player.deputyGeneral or player.deputyGeneral == "" then return false end

  local main = H.getActualGeneral(player, false)
  local deputy = H.getActualGeneral(player, true)
  local main_hidden = player.general == "anjiang"
  local deputy_hidden = player.deputyGeneral == "anjiang"

  room:changeHero(player, deputy, false, false, false, false, false)
  room:changeHero(player, main, false, true, false, false, false)

  if deputy_hidden then player:hideGeneral(false) end
  if main_hidden then player:hideGeneral(true) end
  return true
end

-- 访客技能被评鉴移去后，本回合剩余时机仍要能响应（如裸衣的伤害加成），
-- 因此不立即 loseFakeSkill，而是登记到待回收表，等回合结束统一失效并清标记。
U.VISITOR_EXPIRING_MARK = "fengsui_heg__fangke_expiring-turn"

-- engine 的 addTriggerSkill 只增不减：触发技实例留在 room.logic 里时，
-- global 效果的 can_trigger 会绕过 hasSkill 判断，技能移去后仍对全场生效。
-- 仅当全场没有其他角色正在使用该技能时才注销，避免误伤真实武将的同名技。
local function visitorSkillStillInUse(room, skillName, player)
  for _, p in ipairs(room.players) do
    if p ~= player then
      if p:hasSkill(skillName) and not p:isFakeSkill(skillName) then return true end
      if table.contains(p:getTableMark("fengsui_heg__fangke_skills"), skillName) then
        return true
      end
    end
  end
  return false
end

local function unregisterVisitorTriggers(room, skill)
  local logic = room.logic
  if not logic or not logic.skill_table then return end
  for _, trig in ipairs(skill.related_skills or {}) do
    if trig:isInstanceOf(TriggerSkill) then
      if logic.skills then table.removeOne(logic.skills, trig.name) end
      local tab = logic.skill_table[trig.event]
      if tab then table.removeOne(tab, trig) end
    end
  end
end

function U.expireVisitorSkills(room, player)
  local pending = player:getTableMark(U.VISITOR_EXPIRING_MARK)
  if #pending == 0 then return end
  for _, skillName in ipairs(pending) do
    -- 技能又被新的访客提供时保留，不摘掉仍在使用的技能。
    if not table.contains(player:getTableMark("fengsui_heg__fangke_skills"), skillName) then
      local skill = Fk.skills[skillName]
      if skill and player:isFakeSkill(skill) then
        player:prelightSkill(skill, false)
        player:loseFakeSkill(skill)
        if not visitorSkillStillInUse(room, skillName, player) then
          unregisterVisitorTriggers(room, skill)
        end
      end
      -- 技能留下的本回合／本阶段标记一并清掉，避免技能失效后残留。
      room:setPlayerMark(player, skillName .. "-turn", 0)
      room:setPlayerMark(player, skillName .. "-phase", 0)
    end
  end
  room:setPlayerMark(player, U.VISITOR_EXPIRING_MARK, 0)
end

return U
