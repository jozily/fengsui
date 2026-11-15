local H = require "packages.fengsui.hegemony_util"

local U = {}

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
  local is_deputy = U.getSkillPlace(player, skill_name)
  if is_deputy == nil then return false end
  if (is_deputy and player.deputyGeneral == "anjiang") or
      (not is_deputy and player.general == "anjiang") then
    return false
  end
  player:hideGeneral(is_deputy)
  return true
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

-- 黜光的可见计数形如「黜光 1/3」：1 是本轮皎宿／曜暝发动次数，3 是失效边界
-- （当前同势力角色数）。失效判定另存一个不可见 mark，可见 mark 变成字符串后
-- invalidity_func 里的数值比较就会报错。
local chuguangCount = "fengsui_heg__chuguang_count-round"
local chuguangVisible = "@fengsui_heg__chuguang_disabled-round"
local chuguangInvalid = "fengsui_heg__chuguang_invalid-round"
U.chuguangInvalidMark = chuguangInvalid

function U.refreshChuguangMark(player)
  local room = player.room
  local n = player:getMark(chuguangCount)
  if n <= 0 then
    room:setPlayerMark(player, chuguangVisible, 0)
    room:setPlayerMark(player, chuguangInvalid, 0)
    return
  end
  local m = #table.filter(room.alive_players, function(p)
    return H.compareKingdomWith(player, p)
  end)
  room:setPlayerMark(player, chuguangVisible, n .. "/" .. m)
  -- 次数一旦达到边界，皎宿／曜暝本轮内持续失效；之后同势力人数变化只更新
  -- 显示的边界 M，不把已经失效的技能重新放开。
  local invalid = player:getMark(chuguangInvalid) > 0 or n >= m
  room:setPlayerMark(player, chuguangInvalid, invalid and 1 or 0)
end

-- 主副将易位走 changeHero，ChangeProperty 会把原武将的技能先 '-' 再 '+'；
-- '-' 触发 SkillSkeleton:onLose，把 derived_piles 里的牌丢进弃牌堆。两张武将牌
-- 都没有离开角色，按「易位不移除武将牌上的牌」应当原样保留，故先备份再放回。
-- 只备份原本明置的武将牌：暗置武将牌上的牌按规则本就不存在。
local function snapshotGeneralPiles(player)
  local saved = {}
  for _, isDeputy in ipairs({false, true}) do
    local hidden = isDeputy and player.deputyGeneral == "anjiang" or
      (not isDeputy and player.general == "anjiang")
    local g = not hidden and Fk.generals[H.getActualGeneral(player, isDeputy)]
    if g then
      for _, sname in ipairs(g:getSkillNameList(true)) do
        local skel = Fk.skill_skels[sname]
        if skel then
          local piles = {}
          local function addPiles(v)
            if type(v) == "string" then v = { v } end
            if v then for _, p in ipairs(v) do table.insertIfNeed(piles, p) end end
          end
          addPiles(skel.derived_piles)
          for _, eff in ipairs(skel.effects or {}) do addPiles(eff.derived_piles) end
          for _, pile in ipairs(piles) do
            local ids = player:getPile(pile)
            if #ids > 0 then
              saved[pile] = saved[pile] or {}
              table.insertTableIfNeed(saved[pile], ids)
            end
          end
        end
      end
    end
  end
  return saved
end

local function restoreGeneralPiles(room, player, saved)
  for pile, ids in pairs(saved) do
    local restorable = table.filter(ids, function(id)
      local area = room:getCardArea(id)
      return area == Card.DiscardPile or area == Card.Processing or area == Card.Void
    end)
    if #restorable > 0 then player:addToPile(pile, restorable, true) end
  end
end

function U.swapGenerals(room, player)
  if not player.deputyGeneral or player.deputyGeneral == "" then return false end
  local savedPiles = snapshotGeneralPiles(player)

  local main = H.getActualGeneral(player, false)
  local deputy = H.getActualGeneral(player, true)
  local main_hidden = player.general == "anjiang"
  local deputy_hidden = player.deputyGeneral == "anjiang"

  room:changeHero(player, deputy, false, false, false, false, false)
  room:changeHero(player, main, false, true, false, false, false)

  if deputy_hidden then player:hideGeneral(false) end
  if main_hidden then player:hideGeneral(true) end
  -- changeHero 的连续调用可能只刷新第一次变更的技能集合；重新按当前明置位置
  -- 构建技能集合。主将牌上的副将技、以及副将牌上的主将技都必须移除。
  local expected = {}
  for _, is_deputy in ipairs({false, true}) do
    local name = H.getActualGeneral(player, is_deputy)
    local g = Fk.generals[name]
    local hidden = is_deputy and player.deputyGeneral == "anjiang" or (not is_deputy and player.general == "anjiang")
    if g and not hidden then
      for _, skill in ipairs(g:getSkillNameList(true)) do
        local skel = Fk.skills[skill]
        local wrong_place = skel and ((is_deputy and skel:hasTag(Skill.MainPlace)) or
          ((not is_deputy) and skel:hasTag(Skill.DeputyPlace)))
        if not wrong_place then expected[skill] = true end
      end
    end
  end
  local known = {}
  for _, name in ipairs({ main, deputy, H.getActualGeneral(player, false), H.getActualGeneral(player, true) }) do
    local g = Fk.generals[name]
    if g then for _, skill in ipairs(g:getSkillNameList(true)) do known[skill] = true end end
  end
  local changes = {}
  for skill in pairs(known) do
    if not expected[skill] and player:hasSkill(skill, true, true) then table.insert(changes, "-" .. skill) end
  end
  for skill in pairs(expected) do
    if not player:hasSkill(skill, true, true) then table.insert(changes, skill) end
  end
  if #changes > 0 then room:handleAddLoseSkills(player, table.concat(changes, "|"), nil, false) end
  restoreGeneralPiles(room, player, savedPiles)
  return true
end

-- Use the engine's reveal prohibition; the visible mark explains which card is locked.
function U.prohibitReveal(player, is_deputy, skill_name, duration, label_override)
  local suffix = "-" .. duration
  local room = player.room
  room:addTableMark(player, MarkEnum.RevealProhibited .. suffix, is_deputy and "d" or "m")
  local label = label_override or (Fk:translate(skill_name) .. " 禁亮" ..
    Fk:translate(H.getActualGeneral(player, is_deputy)))
  room:addTableMark(player, "@fengsui_heg__ban_reveal" .. suffix, label)
end

return U
