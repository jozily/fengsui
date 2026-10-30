local hegRule = fk.CreateSkill{
  name = "zeheg_rule",
}

local H = require "packages.fengsui.hegemony_util"

--进入鏖战模式
---@param room Room
local enterBattleRoyalMode = function(room)
  local isold = room:getSettings("oldBattleRoyal")
  if isold then
   room:doBroadcastNotify("ShowToast", Fk:translate("#EnterBattleRoyalMode"))
  else
   room:doBroadcastNotify("ShowToast", Fk:translate("#EnterNewBattleRoyalMode"))
  end
  if isold then
    room:sendLog({
      type = "#EnterBattleRoyalMode",
    })
  else
    room:sendLog({
      type = "#EnterNewBattleRoyalMode",
    })
  end
  room:broadcastPlaySound("./packages/fengsui/pkg/fengsui_effect/audio/BGM/aozhan_start")
  room:doSuperLightBox("packages/fengsui/pkg/fengsui_effect/qml/aozhan.qml")
  room:delay(2400)
  room:setTag("BattleRoyalMode", true)
  if isold then
    room:setBanner("@[:]BattleRoyalDummy", "BattleRoyalMode")
  else
    room:setBanner("@[:]BattleRoyalDummy", "NewBattleRoyalMode")
  end
  -- 与 hegemony 的实际技能名一致；新鏖战技能负责将非转化桃视为酒。
  local name = isold and "battle_royal&" or "new_battle_royal&"
  for _, p in ipairs(room.alive_players) do
    room:handleAddLoseSkills(p, name, nil, false)
  end
  if not isold then
    room:addSkill("#new_battle_royal_event&")
  end
  room.logic:trigger(H.EnterBattleRoyalMode, room.current, nil)
end

--- 野心家选择国家
---@param room Room
---@param player ServerPlayer
---@param generalName string
local function wildChooseKingdom(room, player, generalName)
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
      choice = room:askToChoice(player, {choices = choices, skill_name = hegRule.name, prompt = "#wild-choose", cancelable = false, all_choices = all_choices})
    end
  elseif table.contains({"wei", "shu", "wu", "qun", "jin", "unknown", "hidden", "wild"}, player.role) then
    choice = room:askToChoice(player, {choices = choices, skill_name = hegRule.name, prompt = "#wild-choose", cancelable = false, all_choices = all_choices})
  end
  if choice then
    room:setPlayerProperty(player, "role", choice)
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

--- 询问加入建国
---@param room Room
---@param player ServerPlayer
---@param generalName string
---@param isActive boolean
---@return boolean
local function AskForBuildCountry(room, player, generalName, isActive)
  if not (player.general == generalName and H.kingdomMapper[generalName]) then return false end
  local choices = {"heg_rule_join_country:"..player.id.."::"..player.role, "Cancel"}
  for _, p in ipairs(room:getAlivePlayers()) do
    if p:getMark("__heg_join_wild") == 0 and p.kingdom ~= "wild" and not string.find(p.general, "lord")
      and (not isActive or p.general ~= "anjiang") then
      local choice =  room:askToChoice(p, {choices = choices, skill_name = "heg__lalong", prompt = "#wild_join-choose"})
      if choice ~= "Cancel" then
        p.role = player.role
        room:setPlayerProperty(p, "role_shown", true)
        room:broadcastProperty(p, "role")
        room:sendLog{
          type = "#WildChooseKingdom",
          from = p.id,
          arg = player.role,
          arg2 = "wild",
        }
        room:setPlayerProperty(p, "kingdom", "wild")
        room:setPlayerMark(p, "__heg_join_wild", 1)
        room:setPlayerMark(player, "__heg_construct_wild", 1)
        room:sendLog{
          type = "#SuccessBuildCountry",
          from = player.id,
          arg = player.role,
          arg2 = p.general
        }
        else --如果不加入，则回血摸牌
        if p:isWounded() then
          room:recover({
            who = p,
            num = 1,
            recoverBy = player,
            skillName = hegRule.name,
          })
        end
        if p:getHandcardNum() < 4 then
          p:drawCards(4 - p:getHandcardNum(), hegRule.name)
        end
      end
    end
  end
  return false
end

local can_trigger = function(self, event, target, player, data)
    return target == player
end

hegRule:addEffect(fk.BeforeTurnStart, {
    mute = true,
    priority = 0.001,
    can_trigger = can_trigger,
    on_trigger = function(self, event, target, player, data)
      local room = player.room
      -- 鏖战
      if #room.alive_players < (#room.players > 6 and 5 or 4) and not room:getTag("BattleRoyalMode") then
        local ret = true
        for _, v in pairs(H.getKingdomPlayersNum(room)) do
          if v and v > 1 then
            ret = false
            break
          end
        end
        if ret then
            enterBattleRoyalMode(room)
          end
        end
     end,
    })

hegRule:addEffect(fk.TurnStart, {
      mute = true,
      priority = 100,
      can_trigger = can_trigger,
      on_trigger = function(self, event, target, player, data)
        local room = player.room
        if room:getSettings("heg__lordconvert") then
          H.askToRevealGenerals(player, {
              skill_name = hegRule.name,
              lord_convert = true,})
          else
            H.askToRevealGenerals(player, {
              skill_name = hegRule.name,
              lord_convert = false,})
          end
        end
})

hegRule:addEffect(fk.GameOverJudge, {
    mute = true,
    priority = 0.001,
    can_trigger = can_trigger,
    on_trigger = function(self, event, target, player, data)
      local room = player.room
      if room:getSettings("firstdeadnextseat1") and not room:getTag("firstdeadnextseat1") then
        room:setTag("firstdeadnextseat1", true)
        local sessiondata = player.room:getSessionData()
        sessiondata.firstdeadnextseat1_record = player.id
        room:setSessionData(sessiondata)
      end
      player:revealGeneral(false)
      player:revealGeneral(true)
      if player.kingdom == "wild" and player:getMark("_wild_gained") ~= 1 then
        wildChooseKingdom(room, player, player.general)
      end
    local winner = Fk.game_modes[room:getSettings('gameMode')]:getWinner(player)
    if winner ~= "" then
        for _, ps in ipairs(room.alive_players) do
          -- 先检测并询问主将是不是野人
          if ps.general == "anjiang" then
            -- 是野人则强制亮出来
            if ps:getMark("__heg_wild") == 1 then
              room:setPlayerMark(ps, "_wild_final_end", 1)
              ps:revealGeneral(false)
            end
          end
        end
        -- 强制亮完野人后检测场上有没有野人
        if table.find(room.alive_players, function(p) return p:getMark("__heg_wild") == 1 end) then
            --有野人则依次询问拉拢
              for _, p in ipairs(room.alive_players) do
              if p:getMark("__heg_wild") == 1 and p:getMark("_wild_gained") == 0 then
                room:changeKingdom(p, "wild", true)
                wildChooseKingdom(room, p, p.general)
                local choices = {}
                table.insert(choices, "heg_build_country:::" .. p.role)
                table.insert(choices, "Cancel")
                local choice = room:askToChoice(p, {choices = choices, skill_name = "heg__lalong"})
                if choice ~= "Cancel" then
                    room:broadcastPlaySound("./packages/fengsui/pkg/fengsui_effect/audio/BGM/buildcountry")
                    room:doSuperLightBox("packages/fengsui/pkg/fengsui_effect/qml/BuildCountry.qml")
                    room:delay(1000)
                    AskForBuildCountry(room, p, p.general, false)
                    room:setPlayerMark(p, "_wild_gained", 1)
               end
              end
            end
          end
        -- 然后判断场上所有人势力是否相同
        local _kingdom2 = {}
        for _, p in ipairs(room.alive_players) do
          if not table.contains(_kingdom2, p.kingdom) and p.kingdom ~= "unknown" then
            table.insert(_kingdom2, p.kingdom)
          end
        end
        if #_kingdom2 == 1 then
            -- 若所有人势力相同则全部亮将
            for _, p in ipairs(room.alive_players) do
              if p.general == "anjiang" then p:revealGeneral(false) end
              if p.deputyGeneral == "anjiang" then p:revealGeneral(true) end
              if p:getMark("_wild_gained") > 0 then winner = p.role end
            end
            room:gameOver(winner)
            return true
          end
        end
    end
})

hegRule:addEffect(fk.GeneralRevealed, {
    mute = true,
    priority = 0.001,
    can_trigger = can_trigger,
    on_trigger = function(self, event, target, player, data)
        local room = player.room
        room:setPlayerMark(player, "GeneralRevealed-round", 1)--本轮明置过武将牌
        for _, general_name in pairs(data) do
            if room:getTag("TheFirstToShowRewarded") == player.id and player:getMark("_vanguard_gained") == 0 and not player.dead then
              room:setPlayerMark(player, "_vanguard_gained", 1)
              room:doSuperLightBox("packages/fengsui/pkg/fengsui_effect/qml/Vanguard.qml")
              H.addHegMark(room, player, "vanguard")
            end
            if player:getMark("hasShownMainGeneral") == 1 and Fk.generals[general_name].kingdom == "wild" and player:getMark("_wild_gained") == 0 then
                room:doSuperLightBox("packages/fengsui/pkg/fengsui_effect/qml/WildEffect.qml")
                room:setPlayerMark(player, "_wild_gained", 1)
                H.addHegMark(room, player, "wild")
              end
              if player.general == "anjiang" or player.deputyGeneral == "anjiang" or player:getMark("hasShownAllGeneral") > 0 then return false end
              room:addPlayerMark(player, "hasShownAllGeneral")
              if player:getMark("HalfMaxHpLeft") > 0 then
                room:setPlayerMark(player, "HalfMaxHpLeft", 0)
                H.addHegMark(room, player, "yinyangfish")
              end
              if player:getMark("CompanionEffect") > 0 then
                room:doSuperLightBox("packages/fengsui/pkg/fengsui_effect/qml/Companion.qml")
                room:setPlayerMark(player, "CompanionEffect", 0)
                H.addHegMark(room, player, "companion")
              end
            end
        end
})

-- 出牌阶段主动亮将次数（设置项：fengsui_reveal_count，下拉预设 0/1/3/5/10/无限）
-- 0：本局出牌阶段移除亮将按钮；>0：每名角色每出牌阶段可主动亮将该次数，亮将按钮上显示剩余次数，用尽后按钮不可用
-- 无限(-1)：不限次数，亮将按钮不显示次数
-- 仅统计出牌阶段通过亮将按钮(reveal_skill&)的主动亮将；回合开始时的主动亮将、死亡/同势力等强制亮将不计入
-- 注意：priority 必须为 0。若与其他效果同为 >0 的优先级且同时可触发，引擎会弹"选择发动的技能"框
-- （此技能所有效果实例的显示名都是"亮将"，会弹出多个"亮将"按钮）；priority<=0 走引擎静默自动触发路径，不弹任何框
hegRule:addEffect(fk.EventPhaseStart, {
    mute = true,
    priority = 0,
    can_trigger = function(self, event, target, player, data)
      return target == player and player.phase == Player.Play
    end,
    on_trigger = function(self, event, target, player, data)
      local room = player.room
      local v = room:getSettings("fengsui_reveal_count")
      local n = (v == "无限") and -1 or (tonumber(v) or 0)
      if n == 0 then
        room:setPlayerMark(player, "fengsui_reveal_max", 0)
        room:setPlayerMark(player, "fengsui_reveal_remain", 0)
        return
      end
      room:setPlayerMark(player, "fengsui_reveal_max", n)
      room:setPlayerMark(player, "fengsui_reveal_remain", n > 0 and n or -1)
    end,
  })

hegRule:addEffect(fk.GeneralRevealed, {
    mute = true,
    priority = 0,
    can_trigger = function(self, event, target, player, data)
      return target == player and player.phase == Player.Play
    end,
    on_trigger = function(self, event, target, player, data)
      local room = player.room
      if (player:getMark("fengsui_reveal_max") or 0) <= 0 then return end
      local remain = player:getMark("fengsui_reveal_remain")
      if remain <= 0 then return end
      room:setPlayerMark(player, "fengsui_reveal_remain", remain - 1)
    end,
  })

hegRule:addEffect(fk.EventPhaseStart, {
    mute = true,
    priority = 0.001,
    can_trigger = function(self, event, target, player, data)
      return target == player and player.phase == Player.Play and not player:hasSkill("alliance&")
    end,
    on_trigger = function(self, event, target, player, data)
      player:addFakeSkill("alliance&")
    end
  })

hegRule:addEffect(fk.EventPhaseEnd, {
    mute = true,
    priority = 0.001,
    can_trigger = function(self, event, target, player, data)
      return target == player and player.phase == Player.Play
    end,
    on_trigger = function(self, event, target, player, data)
      player:loseFakeSkill("alliance&")
    end
  })

hegRule:addEffect(fk.GeneralShown, {
    mute = true,
    priority = 0.001,
    can_trigger = can_trigger,
    on_trigger = function(self, event, target, player, data)
      local room = player.room
      if not room:getTag("TheFirstToShowRewarded") then
        room:setTag("TheFirstToShowRewarded", player.id)
      end
      local general_name = data["m"] or data["d"]
      -- 君主拉回野人
      if general_name and string.find(general_name, "lord") then
        local kingdom = player:getMark("__heg_kingdom")
        for _, p in ipairs(room.players) do
          if p:getMark("__heg_kingdom") == kingdom and p.kingdom == "wild" and p:getMark("__heg_wild") == 0 then
            room:setPlayerProperty(p, "kingdom", kingdom)
            room:setPlayerProperty(p, "role_shown", false)
            room:setPlayerProperty(p, "role", kingdom)
          end
        end
      end
      if player.kingdom == "wild" and not player.dead and player:getMark("_wild_gained") == 0 then
         wildChooseKingdom(room, player, general_name)
        -- 野人亮出来的时候询问拉拢
        local choices = {"Cancel"}
        if player:getMark("__heg_wild") == 1 and player:getMark("_wild_final_end") == 0 then
          table.insert(choices, "heg_build_country:::" .. player.role)
        end
        -- if room:askForChoice(player, choices, "#heg_rule") ~= "Cancel" then
        --   AskForBuildCountry(room, player, general_name, true)
        --   room:setPlayerMark(player, "_wild_gained", 1)
        -- end
    elseif player:getMark("__heg_join_wild") == 0 and player:getMark("__heg_construct_wild") == 0 then
       if player:getMark("__heg_wild") == 1 then
        if player.general == "anjiang" then
          room:setPlayerProperty(player, "role",  player:getMark("__heg_kingdom"))
        else
          room:setPlayerProperty(player, "role",  player.role or H.kingdomMapper[player.general] or "wild") -- 修复没国野人
        end
       else
          room:setPlayerProperty(player, "role", player.kingdom)
       end
     end

     for _, v in pairs(H.getKingdomPlayersNum(room)) do
        if v == #room.alive_players then
          local winner = Fk.game_modes[room:getSettings('gameMode')]:getWinner(player)
          for _, p in ipairs(room.alive_players) do
            -- 先检测并询问主将是不是野人
            if p.general == "anjiang" then
              -- 是野人则强制亮出来
              if p:getMark("__heg_wild") == 1 then
                room:setPlayerMark(p, "_wild_final_end", 1)
                p:revealGeneral(false)
              end
            end
          end
            -- 强制亮完野人后检测场上有没有野人
          if table.find(room.alive_players, function(p) return p:getMark("__heg_wild") == 1  end) then
            --有野人则依次询问拉拢
            for _, p in ipairs(room.alive_players) do
              if p:getMark("__heg_wild") == 1 and p:getMark("_wild_gained") == 0 then
                room:changeKingdom(p, "wild", true)
                wildChooseKingdom(room, p, p.general)
                local choices = {}
                table.insert(choices, "heg_build_country:::" .. p.role)
                table.insert(choices, "Cancel")
                --手杀拉拢人心规则
                local choice = room:askToChoice(p, {choices = choices, skill_name = "heg__lalong"})
                if choice ~= "Cancel" then
                    room:broadcastPlaySound("./packages/fengsui/pkg/fengsui_effect/audio/BGM/buildcountry")
                    room:doSuperLightBox("packages/fengsui/pkg/fengsui_effect/qml/BuildCountry.qml")
                    room:delay(1000)
                    AskForBuildCountry(room, p, p.general, false)
                    room:setPlayerMark(p, "_wild_gained", 1)
               end
              end
            end
          end
          -- 然后判断场上所有人势力是否相同
          if table.every(room.alive_players, function(p) return H.compareKingdomWith(p, player) end) then
            -- 若所有人势力相同则全部亮将
            for _, p in ipairs(room.alive_players) do
              if p.general == "anjiang" then p:revealGeneral(false) end
              if p.deputyGeneral == "anjiang" then p:revealGeneral(true) end
              if p:getMark("_wild_gained") > 0 then winner = p.role end
            end
            room:gameOver(winner)
            return true
          end
        else
            break
          end
        end
        if player:getMark("hasShownMainGeneral") == 0 and data["m"] then -- 首次亮主将
            room:setPlayerMark(player, "hasShownMainGeneral", 1)
        end
    end,
    })

-- 出牌阶段主动亮将次数：给核心 reveal_skill& 挂上角标/禁用闸门的服务端兜底补丁
-- （客户端角标由 fengsuihegemony.lua 顶层补丁提供，此处防懒加载时序问题；有 __fengsui_reveal_patched 防重入）
-- priority 同样必须为 0，理由同上
hegRule:addEffect(fk.GameStart, {
    mute = true,
    priority = 0,
    can_trigger = function() return true end,
    on_trigger = function(self, event, target, player, data)
      local revealSkill = Fk.skills["reveal_skill&"]
      if revealSkill and revealSkill.canUse and not revealSkill.__fengsui_reveal_patched then
        local origCanUse = revealSkill.canUse
        revealSkill.canUse = function(self2, p, card, extra_data)
          if (p:getMark("fengsui_reveal_max") or 0) <= 0 then
            return origCanUse(self2, p, card, extra_data)
          end
          if p.phase ~= Player.Play then return false end
          if (p:getMark("fengsui_reveal_remain") or 0) <= 0 then return false end
          return origCanUse(self2, p, card, extra_data)
        end
        revealSkill.times = function(self2, p)
          if (p:getMark("fengsui_reveal_max") or 0) <= 0 then return -1 end
          return p:getMark("fengsui_reveal_remain")
        end
        revealSkill.__fengsui_reveal_patched = true
      end
    end,
  })

hegRule:addEffect(fk.GameStart, {
    mute = true,
    priority = 0.001,
    can_trigger = can_trigger,
    on_trigger = function(self, event, target, player, data)
        local room = player.room
        for _, p in ipairs(room.players) do
          p:setMark("@seat", 0)
          p:doNotify("SetPlayerMark", { p.id, "@seat", 0})
        end
      end,

    can_refresh = can_trigger,
    on_refresh = function(self, event, target, player, data)
        -- 新鏖战由 new_battle_royal& 的 view-as/prohibit 负责桃转酒；旧鏖战才需要旧牌面过滤。
        if player.room:getSettings("oldBattleRoyal") then
          player.room:addSkill("#battle_royal_peach&")
        end
      local sessiondata = player.room:getSessionData()
      sessiondata.firstdeadnextseat1_record = nil
      player.room:setSessionData(sessiondata)
    end,
})

--洗牌鏖战
hegRule:addEffect(fk.AfterDrawPileShuffle, {
  mute = true,
  priority = 0,
  can_trigger = function(self, event, target, player, data)
    return not player.room:getTag("BattleRoyalMode") and player.room:getSettings("enterBattleRoyalOnFirstShuffle")
    and #player.room.players == 10
  end,
  on_trigger = function(self, event, target, player, data)
    enterBattleRoyalMode(player.room)
  end,
})

hegRule:addEffect("filter", {
  card_pic_filter = function (self, card)
    local c = Fk:getCardById(card.id, true)
    if c:hasMark("@@alliance-public", {}) then
      if c.name == "peach" and c.suit ~= Card.NoSuit then
        if (Self and Self:hasSkill("#battle_royal&") and Self:getMark("_heg__battleRoyalVsMode_ignore") == 0) or Fk:currentRoom():getBanner("@[:]BattleRoyalDummy")
        and Fk:currentRoom():getSettings("oldBattleRoyal") then
          return "peach_Royal_alliance"
        end
      end
      return c.name.."_alliance"
    else
      if c.name == "peach" and c.suit ~= Card.NoSuit then
        if (Self and Self:hasSkill("#battle_royal&") and Self:getMark("_heg__battleRoyalVsMode_ignore") == 0) or Fk:currentRoom():getBanner("@[:]BattleRoyalDummy")
        and Fk:currentRoom():getSettings("oldBattleRoyal") then
          return "peach_Royal"
        end
      end
    end
  end,
})

hegRule:addTest(function()
  local customDisabled = Fk.game_mode_disabled["fengsui_heg__mode"] or {}
  for _, packageName in ipairs(Fk._fengsuiModeOfficialPackages or {}) do
    lu.assertFalse(table.contains(customDisabled, packageName), packageName)
  end
  for _, packageName in ipairs(Fk._fengsuiModePackages or {}) do
    lu.assertFalse(table.contains(customDisabled, packageName), packageName)
  end

  local officialDisabled = Fk.game_mode_disabled["new_heg_mode"] or {}
  for _, packageName in ipairs({
    "fengsui_hebi", "fengsui_cards", "fengsui_liwu", "fengsui_shiyi", "fengsui_effect",
  }) do
    lu.assertFalse(table.contains(officialDisabled, packageName), packageName)
  end
end)

return hegRule
