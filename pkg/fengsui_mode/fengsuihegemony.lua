local heg_description = [==[
# 晋势力国战模式简介

本模式用于加入晋势力武将(紫气东来、金印紫绶)的多势力国战模式。

**游戏开始时，会随机禁用一个势力，此势力的武将将不会在本局游戏中出现**

其余规则与全扩国战模式规则一致。

]==]

local H = require "packages.fengsui.hegemony_util"
local W = require 'ui_emu.preferences'


local heg

---@class HegLogic: GameLogic
local HegLogic = {}
function HegLogic:assignRoles()
  local room = self.room
  for _, p in ipairs(room.players) do
    room:setPlayerProperty(p, "role_shown", false)
    p.role = "hidden"
    room:broadcastProperty(p, "role")
  end

  -- for adjustSeats
  if room:getSettings("firstdeadnextseat1") then
    local firstdaedid = (room:getSessionData() or {}).firstdeadnextseat1_record
    if firstdaedid and room:getSettings("showseat") == "heg_beforechoosegenerals" then
      local p = table.find(room.players, function (p1)
        return p1.id == firstdaedid
      end)
      if p then
        room:sendLog{
          type = "#firstdeadnextseat1",
          arg = p._splayer:getScreenName(),
          toast = true,
        }
        p.role = "lord"
        return
      end
    end
  end

  room.players[1].role = "lord"
end

--安排座位
function HegLogic:adjustSeats()
  local player_circle = {}
  local players = self.room.players
  local p = 1

  for i = 1, #players do
    if players[i].role == "lord" then
      p = i
      break
    end
  end
  for j = p, #players do
    table.insert(player_circle, players[j])
  end
  for j = 1, p - 1 do
    table.insert(player_circle, players[j])
  end

  --self.room:doBroadcastNotify("ShowToast", Fk:translate("#toast_"..self.room:getSettings("showseat")))

  --self.room.players = player_circle
  self.room:setTag("heg_showseat_record",table.simpleClone(player_circle))
  if self.room:getSettings("showseat") == "heg_beforechoosegenerals" then
    self.room:arrangeSeats(player_circle)
    for _, t in ipairs(players) do
      t:setMark("@seat", "seat#" .. tostring(t.seat))
      t:doNotify("SetPlayerMark", { t.id, "@seat", "seat#" .. tostring(t.seat)})
    end
  else
    --因为直接交换座位会显示真实座位，所以这里把每个人当一号位分别通知
    local playerid_circle = table.map(player_circle, Util.IdMapper)
    for _, t in ipairs(players) do
      local temp, circle = {}, {}
      for _, id in ipairs(playerid_circle) do
        if #circle > 0 then
          table.insert(circle, id)
        else
          if id ~= t.id then
            table.insert(temp, id)
          else
            table.insert(circle, id)
          end
        end
      end
      table.insertTable(circle, temp)
      self.room:doBroadcastNotify("ArrangeSeats", circle, {t})
    end
  end
end

function HegLogic:chooseGenerals()
  local room = self.room
  local num = room:getSettings('generalNum')
  if num > 9 then --强制9框
    num = 9
  end
  local generalNum = math.max(num, 5)
  room:doBroadcastNotify("ShowToast", Fk:translate("#fengsuihegInitialNotices"))

  local lord = room:getLord() --[[@as ServerPlayer]]
  room:setCurrent(lord)
  lord.role = "hidden"

  local trskingdoms={
  ["wei"]="<b><font color='blue'>魏</font>",
  ["shu"]="<b><font color='red'>蜀</font>",
  ["wu"]="<b><font color='green'>吴</font>",
  ["qun"]="<b><font color='grey'>群</font>",
  ["jin"]="<b><font color='purple'>晋</font>",
}

  local allKingdoms = {} ---@type string[]
  table.forEach(room.general_pile, function(name)
    table.insertIfNeed(allKingdoms, Fk.generals[name].kingdom) -- 假设不会有只出现在副势力的势力
  end)
  table.removeOne(allKingdoms, "fengsui_neutral")
  table.removeOne(allKingdoms, "fengsui_neutralall")
  table.removeOne(allKingdoms, "fengsui_sweeping")
  table.removeOne(allKingdoms, "wild")
  if #allKingdoms > 4 and not room:getSettings("notBanToFourKingdoms") then
    local kingdoms = table.random(allKingdoms, 4)
    local unused = table.filter(allKingdoms, function(k)
      return not table.contains(kingdoms, k)
    end)
    local chinese_kingdoms = {}--转换成中文
    for _, kingdom in ipairs(unused) do
      table.insert(chinese_kingdoms, trskingdoms[kingdom])
    end
     for i = #room.general_pile, 1, -1 do
      local g = Fk.generals[room.general_pile[i]]
      if g.kingdom ~= "fengsui_sweeping" and
        (table.contains(unused, g.kingdom) or table.contains(unused, g.subkingdom)) then
        table.remove(room.general_pile, i)
      end
    end
  -- 然后把武将牌堆弄好
    allKingdoms = kingdoms
    --禁势力动画，再公布结果
    room:doSuperLightBox("packages/fengsui/pkg/fengsui_effect/qml/Bankingdoms_" .. unused[1] .. ".qml")
    --空读条挡座位
    room:delay(3600)
    room:sendLog{
      type = "#KingdomFiltered",
      arg = table.concat(chinese_kingdoms, " "),
      toast = true,
    }
    room:setBanner("@heg_bankingdom", chinese_kingdoms)
  end
    table.sort(allKingdoms)

  -- 可选：从常规中立者与野心家中随机保留指定数量，作为本局可用武将。
  local randomNeutral = tonumber(room:getSettings("fengsui_random_neutral")) or 0
  local randomWild = tonumber(room:getSettings("fengsui_random_wild")) or 0
  if randomNeutral > 0 or randomWild > 0 then
    local regularNeutral = {
      fengsui_heg__jiaxu = true, fengsui_heg__lusu = true, fengsui_heg__xushu = true,
      fengsui_heg__zhaoe = true, fengsui_heg__xushao = true,
    }
    -- Hidden flags are resolved while the room builds its initial pile.  Keep
    -- the random pool authoritative even when an older room cache omitted a
    -- visible neutral general.
    for name in pairs(regularNeutral) do
      if Fk.generals[name] and not table.contains(room.general_pile, name) then
        table.insert(room.general_pile, name)
      end
    end
    local candidates = table.filter(room.general_pile, function(name)
      local g = Fk.generals[name]
      return g and ((g.kingdom == "wild" and randomWild > 0) or (regularNeutral[name] and randomNeutral > 0))
    end)
    -- 只从五名常规中立者中抽取，学园都市中立者不纳入本选项。
    local neutralCandidates = table.filter(candidates, function(name) return regularNeutral[name] == true end)
    local wildCandidates = table.filter(candidates, function(name) return Fk.generals[name].kingdom == "wild" end)
    local selectedNeutral = table.random(neutralCandidates, math.min(randomNeutral, #neutralCandidates))
    local selectedWild = table.random(wildCandidates, math.min(randomWild, #wildCandidates))
    local selected = table.connect(selectedNeutral, selectedWild)
    local selectedSet = {}
    for _, name in ipairs(selected) do selectedSet[name] = true end
    for i = #room.general_pile, 1, -1 do
      local generalName = room.general_pile[i]
      local g = Fk.generals[generalName]
      if g and (g.kingdom == "wild" or regularNeutral[generalName]) and not selectedSet[generalName] then
        table.remove(room.general_pile, i)
      end
    end
    if #selectedNeutral > 0 then room:setBanner("@&enable_neutral_generals", selectedNeutral) end
    if #selectedWild > 0 then room:setBanner("@&enable_wildgenerals", selectedWild) end
    room:sendLog{ type = "#fengsui_random_neutral_wild", arg = table.concat(table.map(selected, Util.TranslateMapper), " "), toast = true }
  end


  local players = room.players
  local generals = room:getNGenerals(#players * generalNum)
  table.shuffle(generals)
   local dat, ext = room:askToChooseIniticalGeneral(lord, {
    targets = players,
    num = num,
    generals = generals,
    needDeputy = true,
    isHeg = true,
    skipSetup = true,
    enabledKingdoms = allKingdoms,
  })

  for _, player in ipairs(players) do
    local general, deputy = table.unpack(dat[player])
    room:setPlayerGeneral(player, general, true)
    room:setDeputyGeneral(player, deputy)

    room:setPlayerMark(player, "__heg_general", general)
    room:setPlayerMark(player, "__heg_deputy", deputy)

    if Fk.generals[general].kingdom == "wild" then
      room:setPlayerMark(player, "__heg_wild", 1)
    end
    room:setPlayerGeneral(player, "anjiang", true)
    room:setDeputyGeneral(player, "anjiang")
    local kingdomChosen = ext[player].kingdom
    room:setPlayerMark(player, "__heg_kingdom", kingdomChosen) -- 变野后变为wild
    room:setPlayerMark(player, "__heg_init_kingdom", kingdomChosen) -- 保存初始势力
  end
end

function HegLogic:broadcastGeneral()
  local room = self.room
  local players = room.players

  if self.room:getSettings("showseat") == "heg_afterchoosegenerals" then
    self.room:arrangeSeats(room:getTag("heg_showseat_record"))
  end

  for _, p in ipairs(players) do
    assert(p.general ~= "")
    local general = Fk.generals[p:getMark("__heg_general")]
    local deputy = Fk.generals[p:getMark("__heg_deputy")]
    local dmaxHp = deputy.maxHp + deputy.deputyMaxHpAdjustedValue
    local gmaxHp = general.maxHp + general.mainMaxHpAdjustedValue
    p.maxHp = (dmaxHp + gmaxHp) // 2
    -- p.hp = math.floor((deputy.hp + general.hp) / 2)
    p.hp = p.maxHp
    -- p.shield = math.min(general.shield + deputy.shield, 5)
    p.shield = 0
    -- TODO: setup AI here

    room:broadcastProperty(p, "general")
    room:broadcastProperty(p, "deputyGeneral")
    room:broadcastProperty(p, "maxHp")
    room:broadcastProperty(p, "hp")
    room:broadcastProperty(p, "shield")

    p.role = p:getMark("__heg_wild") == 1 and "wild" or p:getMark("__heg_kingdom") -- general.kingdom -- 为了死亡时log有势力提示

    if (dmaxHp + gmaxHp) % 2 == 1 then
      p:setMark("HalfMaxHpLeft", 1)
      p:doNotify("SetPlayerMark", { p.id, "HalfMaxHpLeft", 1})
    end
    if general:isCompanionWith(deputy) then
      p:setMark("CompanionEffect", 1)
      p:doNotify("SetPlayerMark", { p.id, "CompanionEffect", 1})
    end
  end
end

function HegLogic:prepareDrawPile()
  GameLogic.prepareDrawPile(self)

  local room = self.room
  local allianceCards = table.clone(H.allianceCards)
  local addAllianceMark = function(c)
    for i = #allianceCards, 1, -1 do
      local cc = allianceCards[i]
      if c.name == cc[1] and c.suit == cc[2] and c.number == cc[3] then
        room:setCardMark(c, "@@alliance-public", 1)
        table.remove(allianceCards, i)
        break
      end
    end
  end
  for _, cid in ipairs(room.draw_pile) do
    addAllianceMark(Fk:getCardById(cid))
  end
  for _, cid in ipairs(room.void) do
    addAllianceMark(Fk:getCardById(cid))
  end
end

local function addHegSkill(player, skill, room)
  player:addFakeSkill(skill)
  local toget = {table.unpack(skill.related_skills)}
  table.insert(toget, skill)
  for _, s in ipairs(toget) do
    if s:isInstanceOf(TriggerSkill) then
      room.logic:addTriggerSkill(s)
    end
  end
end

function HegLogic:attachSkillToPlayers()
  local room = self.room
  local players = room.alive_players

  for _, p in ipairs(players) do
    -- UI
    p:setMark("@seat", "seat#" .. tostring(p.seat))
    p:doNotify("SetPlayerMark", { p.id, "@seat", "seat#" .. tostring(p.seat)})

    local general = Fk.generals[p:getMark("__heg_general")]
    local skills = general:getSkillNameList(true)
    local hasRevealSkill = false
    for _, sn in ipairs(skills) do
      local s = Fk.skills[sn]
      if not s:hasTag(Skill.DeputyPlace) then
        addHegSkill(p, s, room)
        if not hasRevealSkill and s:hasTag(Skill.Compulsory) then
          hasRevealSkill = true
        end
      end
    end

    local deputy = Fk.generals[p:getMark("__heg_deputy")]
    if deputy then
      skills = deputy:getSkillNameList(true)
      for _, sn in ipairs(skills) do
        local s = Fk.skills[sn]
        if not s:hasTag(Skill.MainPlace) then
          addHegSkill(p, s, room)
          if not hasRevealSkill and s:hasTag(Skill.Compulsory) then
            hasRevealSkill = true
          end
        end
      end
    end

    if hasRevealSkill then
      p:addFakeSkill("reveal_skill&")
    end
  end

    -- 观看下家副将
  if room:getSettings("heg__watchDeputy") then
    room:sendLog{
      type = "#WatchNextPlayerDeputyLog",
    }
    local req = Request:new(players, "CustomDialog")
    req.focus_text = "watch_nextGeneral"
    local path = "packages/fengsui/pkg/fengsui_effect/qml/KnownBothBox.qml"
    for _, p in ipairs(players) do
      local next = p:getNextAlive()
      local dat = {next.general, next:getMark("__heg_deputy"), tostring(next.seat)}
      req:setData(p, {
        path = path,
        data = dat,
      })
      p:doNotify("GameLog", {
        type = "#Watch_general",
        from = p.id,
        to = {next.id},
        arg = next:getMark("__heg_deputy"),
      })
    end
    req:ask()
  end

  room:doBroadcastNotify("ShowToast", Fk:translate("#fengsuihegInitialNotices"))
end

local heg_getlogic = function()
  local h = GameLogic:subclass("HegLogic")
  for k, v in pairs(HegLogic) do
    h[k] = v
  end
  return h
end

heg = fk.CreateGameMode{
  name = "fengsui_heg__mode",
  minPlayer = 2,
  maxPlayer = 10,
  main_mode = "heg_mode",
  rule = "zeheg_rule",
  logic = heg_getlogic,
  is_counted = function(self, room)
    return #room.players >= 6
  end,
  whitelist = {
    "new_heg_generals",
    "new_heg_zqdl",
    "new_heg_ld",
    "new_heg_jyzs",
    "new_heg_kann",
    "new_heg_zhbh",
    "new_heg_zfxp",
    "new_heg_offline",

    "hegemony_cards",
    "strategic_advantage",
    "nine_variations",
    "lordcards",
    "jyzs_cards",
    "kanncards",

    "fengsui_hebi",
    "fengsui_cards",
    "fengsui_liwu",
    "fengsui_shiyi",
  },
  winner_getter = function(self, victim)
    local room = victim.room
    local alive = table.filter(room.alive_players, function(p)
      return not p.surrendered
    end)
    local kingdom = ""
    if #alive == 1 then
      kingdom = alive[1].role
    end

      local winner -- = alive[1]
      for _, p in ipairs(alive) do
        if p.kingdom ~= "unknown" then
          winner = p
          break
        end
      end
    if not winner then return "" end
      kingdom = H.getKingdom(winner)
      local i = H.getKingdomPlayersNum(room, true)[kingdom]
      for _, p in ipairs(alive) do
        if not H.compareExpectedKingdomWith(p, winner) then
          return ""
        end
        if p.kingdom == "unknown" then
          i = i + 1
        end
      end
       if i > #room.players // 2 and not H.getHegLord(room, winner) then return "" end
      for _, p in ipairs(room.players) do
        if p.general == "anjiang" then
          room:setPlayerProperty(p, "general", p:getMark("__heg_general"))
        end
        if p.deputyGeneral == "anjiang" then
          room:setPlayerProperty(p, "deputyGeneral", p:getMark("__heg_deputy"))
        end
      end
    return kingdom
  end,
  surrender_func = function(self, playedTime)
    local winner
    local kingdomCheck = true
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      -- 场上有未明置的主将时不能投降
      if p.general == "anjiang" then
        kingdomCheck = false
        break
      end
      if p ~= Self then
        if not winner then
          winner = p
        elseif not H.compareKingdomWith(winner, p, nil, true) then
          kingdomCheck = false
          break
        end
      end
    end
    return { { text = "heg: besieged on all sides", passed = kingdomCheck } }
  end,

  build_draw_pile = function(self)
    local draw, void = GameMode.buildDrawPile(self)

    for i = #draw, 1, -1 do
      local card = Fk:getCardById(draw[i])
      if H.convertCards[card.name] then
        local name = H.convertCards[card.name]
        if table.find(draw, function(c)
          return Fk:getCardById(c).name == name
        end) then
          local id = table.remove(draw, i)
          table.insert(void, id)
        end
      end
    end

    return draw, void
  end,
  reward_punish = function (self, victim, killer)
    local room = victim.room
    local reward = {victim = victim, killer = killer, replaced = false}
    local shangmuReward = victim:getMark("fengsui_heg__shangmu_reward")
    if killer and shangmuReward > 0 then
      if not killer.dead then
        killer:drawCards(shangmuReward, "fengsui_heg__shangmu")
        if killer.deputyGeneral ~= "anjiang" then killer:hideGeneral(true) end
        H.transformGeneral(room, killer, false, false, 1, "fengsui_heg__shangmu")
      end
      room:setPlayerMark(victim, "fengsui_heg__shangmu_reward", 0)
      return
    end
    local duoshouReward = victim:getMark("fengsui_toaru__heg__duoshou_reward")
    if killer and duoshouReward > 0 then
      if not killer.dead then killer:drawCards(duoshouReward, "fengsui_toaru__heg__duoshou") end
      room:setPlayerMark(victim, "fengsui_toaru__heg__duoshou_reward", 0)
      return
    end
    if killer and killer:isAlive() and killer.kingdom ~= "unknown" then
      room.logic:trigger(H.KillRewardExecuting, killer, reward)
    end
    if killer and not reward.replaced then
      if killer.kingdom ~= "unknown" and not killer.dead then
        local times = 1
        if room:getBanner("additional_reward") then --贾充
          times = 1 + room:getBanner("additional_reward")
        end
        -- 因为建国，修改奖惩；如果还没建国
        if killer.kingdom == "wild" and killer:getMark("__heg_construct_wild") == 0 and killer:getMark("__heg_join_wild") == 0 then
          killer:drawCards(times * 3, "kill")
        elseif H.compareKingdomWith(killer, victim) then
          if not (room.logic:getCurrentEvent():findParent(GameEvent.Death, true).data.extra_data or {}).ignorePunishment then --朱灵
          killer:throwAllCards("he")
          end
        else
          killer:drawCards(times * (H.getSameKingdomPlayersNum(room, victim) + 1), "kill")
        end
      end
    end
    if string.find(victim.general, "lord") then
      local players = (table.filter(room.players, function(p) return
        (p:getMark("__heg_kingdom") == victim.kingdom or (p.dead and p.kingdom == victim.kingdom)) and p ~= victim and p.kingdom ~= "wild"
      end))
      room:sortByAction(players)
      local function wildChooseKingdom(player, generalName)
        local allKingdoms ={"wei", "shu", "wu", "qun", "jin", "unknown", "hidden"}

        local choice
        local all_choices = table.clone(H.wildKingdoms)
        local choices = table.clone(all_choices)
        for _, p in ipairs(room.players) do
          table.removeOne(choices, p.role)
        end
        if player.general == generalName and H.kingdomMapper[generalName] and H.kingdomMapper[generalName] ~= player.role then -- 野心家钦定
          if table.contains(choices, H.kingdomMapper[generalName]) then
            choice = H.kingdomMapper[generalName]
          else
            choice = room:askToChoice(player, {
              choices = choices,
              skill_name = "fengsuiheg_rule",
              prompt = "#wild-choose",
              cancelable = false,
              all_choices = all_choices,
            })
          end
        elseif table.contains(allKingdoms, player.role) then
          choice = room:askToChoice(player, {
            choices = choices,
            skill_name = "fengsuiheg_rule",
            prompt = "#wild-choose",
            cancelable = false,
            all_choices = all_choices,
          })
        end
        if choice then
          player.role = choice
          room:setPlayerProperty(player, "role_shown", true)
          room:broadcastProperty(player, "role")
          room:sendLog{
            type = "#WildChooseKingdom",
            from = player.id,
            arg = choice,
            arg2 = "wild",
          }
        end
      end
      for _, p in ipairs(players) do
        local oldKingdom = p.kingdom
        room:setPlayerMark(p, "__heg_kingdom", "wild")
        if oldKingdom ~= "unknown" then
          room:setPlayerProperty(p, "kingdom", "wild")
          if not p.dead then
            wildChooseKingdom(p, p.general)
          end
        end
      end
    end
  end,
  friend_enemy_judge = function (self, targetOne, targetTwo)
    return H.compareExpectedKingdomWith(targetOne, targetTwo)
  end,
}

heg.ui_settings = {
  --君主替换
   W.PreferenceGroup {
    title = "hegemony_special_rule",

    W.SwitchRow {
      _settingsKey = "heg__lordconvert",
      title = "heg_settings__lordconvert",
    },

  --公布座次时机
    W.ComboRow {
      _settingsKey = 'showseat',
      title = 'heg__showseat',
      model = {
        'heg_afterchoosegenerals',
        'heg_beforechoosegenerals',
      }
    },
  },

  --查看下家副将
  W.PreferenceGroup {
    title = "hegemony_additional_rule",

    --鏖战版本
    W.SwitchRow {
      _settingsKey = "oldBattleRoyal",
      title = "heg_old_battle_royal",
    },

    W.SwitchRow {
      _settingsKey = "heg__watchDeputy",
      title = "heg_watch_next_deputy",
   },
    --洗牌鏖战
    W.SwitchRow {
      _settingsKey = "enterBattleRoyalOnFirstShuffle",
      title = "heg_enter_battle_royal_on_first_shuffle",
    },

    W.ComboRow {
      _settingsKey = "fengsui_random_neutral",
      title = "fengsui_random_neutral",
      model = { "0", "1", "2", "3", "4", "5" },
    },

    W.ComboRow {
      _settingsKey = "fengsui_random_wild",
      title = "fengsui_random_wild",
      model = { "0", "1", "2", "3", "4", "5" },
    },

    W.SwitchRow {
      _settingsKey = "fengsui_remove_fuli",
      title = "fengsui_remove_fuli",
    },

    --首死下局一号位
    W.SwitchRow {
      _settingsKey = "firstdeadnextseat1",
      title = "heg__firstdeadnextseat1",
    },
  },
 }

local notice = "此模式为<b><font color='red'>烽燧燎原专属扩展国战模式</b><br><b><font color='purple'>开局随机禁用一个势力</font></b>"

Fk:loadTranslationTable{
  ["fengsui_heg__mode"] = "燎原之战",
  [":fengsui_heg__mode"] = heg_description,
  ["zeheg_rule"] = "亮将",
  ["fengsuiheg_rule"] = "国战规则",
  ["revealAll"] = "全部明置",
  ["@heg_bankingdom"] = "禁用势力  ",
  ["#KingdomFiltered"] = "本局禁用势力为: %arg",

  ["hegemony_special_rule"] = "特殊规则",
  ["heg_settings__lordconvert"] = "君主替换",
  ["help: heg_settings__lordconvert"] = "满足条件时可将同名普通武将替换为君主武将",
  ["heg__showseat"] = "公布座次时机",
  ["heg_afterchoosegenerals"] = "选将后公布座次",
  ["heg_beforechoosegenerals"] = "选将前公布座次",
  ["hegemony_additional_rule"] = "国战附加规则",
  ["heg_old_battle_royal"] = "19版鏖战",
  ["help: heg_old_battle_royal"] = "进入鏖战后，牌堆中的【桃】视为【杀】或【闪】",
  ["heg_watch_next_deputy"] = "观看下家副将",
  ["help: heg_watch_next_deputy"] = "游戏开始前观看下家的副将",
  ["fengsui_random_neutral"] = "随机中立者武将数量",
  ["fengsui_random_wild"] = "随机野心家武将数量",
  ["@&enable_neutral_generals"] = "本局中立者",
  ["@&enable_wildgenerals"] = "本局野心家",
  ["#wild-choose"] = "野心家建国：选择你要成为的势力！",
  ["#wild_join-choose"] = "加入建国",
  ["help: fengsui_random_neutral"] = "本局从常规中立者中随机保留指定数量（0至5）。<br><a href='fengsui_neutral_rule_help'>查看中立者机制</a>",
  ["help: fengsui_random_wild"] = "本局从野心家武将中随机保留指定数量（0至5）。",
  ["fengsui_neutral_rule_help"] = "中立者机制：中立者可与魏、蜀、吴、群、晋势力武将组合；单独明置时仍视为未确定势力，亮出另一张武将牌后确定势力；不可与野心家或另一名中立者组合。",
  ["help: fengsui_neutral_rule_help"] = "中立者机制：中立者可与魏、蜀、吴、群、晋势力武将组合；单独明置时仍视为未确定势力，亮出另一张武将牌后确定势力；不可与野心家或另一名中立者组合。",
  ["fengsui_remove_fuli"] = "删除【赋礼】事件",
  ["help: fengsui_remove_fuli"] = "开启后，鏖战事件池不再包含【赋礼】。",
  ["heg_enter_battle_royal_on_first_shuffle"] = "第一次洗牌进入鏖战",
  ["heg__firstdeadnextseat1"] = "首死玩家下局成为一号位",

  ["#fengsuihegInitialNotices"] = notice
}

return heg
