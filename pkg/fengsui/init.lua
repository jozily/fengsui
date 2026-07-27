local extension = Package:new("fengsui")
local H = require "packages.hegemony.util"
extension.extensionName = "hegemony"
extension.game_modes_whitelist = { "zhonger_heg_mode", "warlords_heg_mode", "jin_heg_mode", "tang_heg_mode" }

extension:loadSkillSkelsByPath("./packages/hegemony/pkg/fengsui/skills")

assert(#extension.skill_skels == 89, "fengsui must load exactly 89 skill skeletons")
for _, skel in ipairs(extension.skill_skels) do
  local skill_name = skel.name
  skel:addTest(function(room, me)
    lu.assertNotNil(Fk.skills[skill_name])
    FkTest.runInRoom(function()
      room:handleAddLoseSkills(me, skill_name)
      lu.assertTrue(me:hasSkill(skill_name, true))
      room:handleAddLoseSkills(me, "-" .. skill_name)
      lu.assertFalse(me:hasSkill(skill_name, true))
    end)
  end)
end

-- ==================== 合璧及变更副将联合提示函数 ====================

--- @param room Room @ 游戏房间
--- @param player ServerPlayer @ 触发合璧或者变更的玩家
--- @param skill_name string @ 技能名称
--- @param isHidden boolean @ 变更或者合璧后的武将是否必须保持暗置
function H.askToHebiOrTransform(room, player, skill_name, isHidden)
  if player.dead then return end
  local choices = {"transformDeputy", "Cancel"}
  
  -- 识别该玩家主将是谁，且有没有珠联璧合对象在当前的将池(牌堆)中
  local main_gen = H.getActualGeneral(player, false)
  local mg = Fk.generals[main_gen]
  local comp_gen = nil
  for _, name in ipairs(room.general_pile) do
    if mg:isCompanionWith(name) then
      comp_gen = name
      break
    end
  end
  
  -- 如果满足有珠联璧合，且该技能在本局该角色未用过合璧功能，则提供选项
  if comp_gen and player:getMark("heg_hebi_" .. skill_name) == 0 then
    table.insert(choices, 1, "heg__hebi_choice")
  end
  
  local choice = room:askToChoice(player, {
    choices = choices,
    skill_name = skill_name,
  })
  
  if choice == "transformDeputy" then
    H.transformGeneral(room, player, false, isHidden)
  elseif choice == "heg__hebi_choice" then
    room:setPlayerMark(player, "heg_hebi_" .. skill_name, 1)
    
    -- 从武将牌堆抽出珠联璧合对象
    table.removeOne(room.general_pile, comp_gen)
    -- 原副将塞回武将底
    local orig = player.deputyGeneral == "anjiang" and player:getMark("__heg_deputy") or player.deputyGeneral
    table.insert(room.general_pile, orig)
    
    -- 更换为指定的副将
    room:changeHero(player, comp_gen, false, true, not isHidden, false, false)
    if isHidden then
      player:hideGeneral(true)
      room:sendLog{
        type = "#ChangeHiddenGeneral",
        from = player.id,
        arg = "deputyGeneral",
        toast = true,
      }
    end
    -- 处理底层标记，确保判定系统运转正常
    room:setPlayerMark(player, "__heg_deputy", comp_gen)
    
    -- 获得一枚珠联璧合标记
    H.addHegMark(player, "companion")
  end
end

Fk:loadTranslationTable{
  ["heg__hebi_choice"] = "进行合璧",
}

local zhanghua = General:new(extension, "fengsui_heg__zhanghua", "jin", 4)
zhanghua.deputyMaxHpAdjustedValue = -1
zhanghua.subkingdom = "wei"
zhanghua:addCompanions("fengsui_heg__lujii")
zhanghua:addSkills { "fengsui_heg__juanzhi", "fengsui_heg__yinbing" }

Fk:loadTranslationTable{
  ["fengsui_heg__zhanghua"] = "张华",
  ["#fengsui_heg__zhanghua"] = "豪志匡朝",
  ["designer:fengsui_heg__zhanghua"] = "公冶天纵",
  ["illustrator:fengsui_heg__zhanghua"] = "公冶天纵",
  ["cv:fengsui_heg__zhanghua"] = "暂无",
  ["fengsui_heg__juanzhi"] = "卷帙",
  [":fengsui_heg__juanzhi"] = "同势力角色的准备阶段，你可以重铸一张牌，若如此做，本回合当你成为与此牌类别相同的牌的目标后，你可以额外指定至多X名角色为目标（X为与你势力相同的角色数）。",
  ["#fengsui_heg__juanzhi-recast"] = "卷帙：请选择一张牌重铸",
  ["#fengsui_heg__juanzhi-targets"] = "卷帙：你可以为此牌额外指定至多 %arg 名角色为目标",
  ["#fengsui_heg__juanzhi-use"] = "卷帙：你可以使用一张牌名字数为 %arg 的基本牌或普通锦囊牌",
  ["fengsui_heg__yinbing"] = "饮冰",
  [":fengsui_heg__yinbing"] = "副将技，锁定技，你计算体力上限时减少一个单独的阴阳鱼。当你每轮首次受到或造成伤害后，受伤角色视为对伤害来源使用一张无距离限制的冰【杀】，结算后若没有角色因此受到伤害，使用者摸两张牌并失去一点体力。",
  ["$fengsui_heg__juanzhi1"] = "此剑光芒艳发，非凡物也，当以华阴赤土拭之。",
  ["$fengsui_heg__juanzhi2"] = "斗牛间常有紫气，其兆如何，还请阁下解之。",
  ["$fengsui_heg__yinbing1"] = "情势危急，故为此举以脱一时之困。",
  ["$fengsui_heg__yinbing2"] = "若当下之围不解，何以图千秋之惠？",
  ["~fengsui_heg__zhanghua"] = "式乾之议，臣谏事具存，非不谏也……",
}

local shantao = General:new(extension, "fengsui_heg__shantao", "jin", 3)
shantao.subkingdom = "wei"
shantao:addCompanions("fengsui_heg__peixiu")
shantao:addSkills { "fengsui_heg__linzhe", "fengsui_heg__yamai" }

Fk:loadTranslationTable{
  ["fengsui_heg__shantao"] = "山涛",
  ["#fengsui_heg__shantao"] = "山叟知材",
  ["designer:fengsui_heg__shantao"] = "公冶天纵",
  ["illustrator:fengsui_heg__shantao"] = "公冶天纵",
  ["cv:fengsui_heg__shantao"] = "暂无",
  ["fengsui_heg__linzhe"] = "遴哲",
  [":fengsui_heg__linzhe"] = "限定技，出牌阶段，你可以令所有与你势力相同的角色选择一项：1.使用一张锦囊牌，然后变更副将；2.获得一个阴阳鱼标记，若其此时手牌数等于体力上限则改为珠联璧合标记。回合结束阶段，若你所在势力为唯一大势力，该技能视为未发动过。",
  ["#fengsui_heg__linzhe"] = "遴哲：令所有同势力角色依次选择一项",
  ["#fengsui_heg__linzhe-choice"] = "遴哲：请选择一项",
  ["fengsui_heg__linzhe_trick_transform"] = "使用一张锦囊牌，然后变更副将",
  ["fengsui_heg__linzhe_mark"] = "获得一个阴阳鱼标记（若手牌数等于体力上限则改为珠联璧合标记）",
  ["#fengsui_heg__linzhe-trick"] = "遴哲：请使用一张锦囊牌",
  ["fengsui_heg__yamai"] = "雅迈",
  [":fengsui_heg__yamai"] = "阵法技，与你处于同一队列角色的回合结束时，若你本回合获得或使用过牌，你可以使用这些牌中位于手牌区或弃牌堆中的其中一张。",
  ["#fengsui_heg__yamai-invoke"] = "雅迈：是否发动，对 %dest 回合结束时使用一张牌？",
  ["#fengsui_heg__yamai-use"] = "雅迈：请选择一张手牌使用",
  ["$fengsui_heg__linzhe1"] = "此位当属汝南袁氏遗才！",
  ["$fengsui_heg__linzhe2"] = "宇内既统，当招揽天下英才！",
  ["$fengsui_heg__yamai1"] = "汝既不才，何以忝居高位？",
  ["$fengsui_heg__yamai2"] = "冀州三十士，当耀于朝。",
  ["~fengsui_heg__shantao"] = "臣垂没之人，岂可污朝堂乎？",
}

-- 蜀-晋
local qiaozhou = General:new(extension, "fengsui_heg__qiaozhou", "jin", 3)
qiaozhou.subkingdom = "shu"
qiaozhou:addCompanions("hs__liushan")
qiaozhou:addSkills { "fengsui_heg__baoguo", "fengsui_heg__yuandao", "fengsui_heg__yunxing" }

Fk:loadTranslationTable{
  ["fengsui_heg__qiaozhou"] = "谯周",
  ["#fengsui_heg__qiaozhou"] = "星途难卜",
  ["designer:fengsui_heg__qiaozhou"] = "公冶天纵",
  ["illustrator:fengsui_heg__qiaozhou"] = "公冶天纵",
  ["cv:fengsui_heg__qiaozhou"] = "暂无",
  ["fengsui_heg__baoguo"] = "保国",
  [":fengsui_heg__baoguo"] = "限定技，当有同势力角色进入濒死状态时，若你为小势力角色，你可以依次令同势力角色选择一项：1.移除副将或将X张牌交给任意一名大势力角色，然后恢复一点体力值；2.摸X张牌。（X为当前大势力角色数）",
  ["#fengsui_heg__baoguo-invoke"] = "保国：是否对 %dest 发动？",
  ["#fengsui_heg__baoguo-choice"] = "保国：请选择一项",
  ["fengsui_heg__baoguo_opt1"] = "移除副将或将X张牌交给一名大势力角色，然后恢复1点体力",
  ["fengsui_heg__baoguo_opt2"] = "摸X张牌",
  ["fengsui_heg__baoguo_remove"] = "移除副将",
  ["fengsui_heg__baoguo_give"] = "交给大势力角色X张牌",
  ["#fengsui_heg__baoguo-subchoice"] = "保国：移除副将，或交给大势力角色 %arg 张牌",
  ["#fengsui_heg__baoguo-cards"] = "保国：请选择 %arg 张牌",
  ["#fengsui_heg__baoguo-major"] = "保国：选择一名大势力角色获得这 %arg 张牌",
  ["fengsui_heg__yuandao"] = "渊道",
  [":fengsui_heg__yuandao"] = "主将技，阵法技，与你处于同一队列的角色于其回合内使用锦囊牌后，其下一张牌不计入次数。",
  ["fengsui_heg__yunxing"] = "陨星",
  [":fengsui_heg__yunxing"] = "副将技，锁定技，回合开始或回合结束时，你摸一张牌，并将一张牌置于牌堆顶。当你进行判定时，若此判定牌的点数不小于与你势力相同角色的体力值之和，则其视为♥，否则视为♠。",
  ["#fengsui_heg__yunxing-top"] = "陨星：请选择一张牌置于牌堆顶",
  ["$fengsui_heg__baoguo1"] = "自古以来，无寄他国而为天子者也。",
  ["$fengsui_heg__baoguo2"] = "周知天命之年，今冒天下不韪而劝降。",
  ["$fengsui_heg__baoguo3"] = "陛下降，若魏不裂土以封，臣必以古义争之。",
  ["$fengsui_heg__yuandao1"] = "高祖斩蛇而定北极，星河斗转，其位移也。",
  ["$fengsui_heg__yuandao2"] = "周慕孔子遗风，可与刘、扬同轨。",
  ["$fengsui_heg__yuandao3"] = "诸葛公天纵之才而堪堪弼国，况我等凡夫乎？",
  ["$fengsui_heg__yunxing1"] = "老夫古稀之年，恐寿数将尽，不复相见矣。",
  ["$fengsui_heg__yunxing2"] = "今老而难死，唯抽白发作毫锋，挑灯写降笺。",
  ["$fengsui_heg__yunxing3"] = "天象有数，今至于此，非陛下、群臣之过。",
  ["~fengsui_heg__qiaozhou"] = "俯首而视仇，非居正道也。",
}

local huoyi = General:new(extension, "fengsui_heg__huoyi", "jin", 4)
huoyi.subkingdom = "shu"
huoyi:addSkills { "fengsui_heg__liefa" }

Fk:loadTranslationTable{
  ["fengsui_heg__huoyi"] = "霍弋",
  ["#fengsui_heg__huoyi"] = "望壑忠志",
  ["designer:fengsui_heg__huoyi"] = "公冶天纵",
  ["illustrator:fengsui_heg__huoyi"] = "公冶天纵",
  ["cv:fengsui_heg__huoyi"] = "暂无",
  ["fengsui_heg__liefa"] = "烈伐",
  [":fengsui_heg__liefa"] = "每回合每种牌名限一次，当你需要使用任意一种目标不包含/包含你的基本牌时，你可以视为使用之，结算后你失去一点体力/弃两张牌。若当前回合角色与你势力相同，其摸一张牌。",
  ["#fengsui_heg__liefa-invoke"] = "烈伐：是否发动？",
  ["#fengsui_heg__liefa-discard"] = "烈伐：请弃置 %arg 张牌",
  ["$fengsui_heg__liefa1"] = "此击必断敌归路！",
  ["$fengsui_heg__liefa2"] = "焚掠浚遒，敌必乱而自伐！",
  ["~fengsui_heg__huoyi"] = "南中初定，蛮河已靖；风雨未晏，归顺新朝。百姓得安，吾无憾矣。",
}

-- 吴-晋
local lujii = General:new(extension, "fengsui_heg__lujii", "jin", 3)
lujii.subkingdom = "wu"
lujii:addCompanions("fengsui_heg__zhanghua")
lujii:addCompanions("ld__lukang")
lujii:addSkills { "fengsui_heg__lingzhi", "fengsui_heg__ruluo" }

Fk:loadTranslationTable{
  ["fengsui_heg__lujii"] = "陆机",
  ["#fengsui_heg__lujii"] = "豪志匡朝",
  ["designer:fengsui_heg__lujii"] = "公冶天纵",
  ["illustrator:fengsui_heg__lujii"] = "公冶天纵",
  ["cv:fengsui_heg__lujii"] = "暂无",
  ["fengsui_heg__lingzhi"] = "凌志",
  [":fengsui_heg__lingzhi"] = "每回合限一次，当你受到或造成伤害后，你可以展示区域内的一张牌并令来源或目标选择一项：1.交给你一张类别不同的牌；2.获得此牌，然后你对其造成一点伤害。",
  ["#fengsui_heg__lingzhi"] = "凌志：你可以展示区域内的一张牌",
  ["fengsui_heg__lingzhi_give"] = "交给其一张类别不同的牌",
  ["fengsui_heg__lingzhi_damage"] = "获得展示牌，然后受到1点伤害",
  ["#fengsui_heg__lingzhi-give"] = "凌志：请选择要交出的牌",
  ["fengsui_heg__ruluo"] = "入洛",
  [":fengsui_heg__ruluo"] = "出牌阶段开始时，你可以展示所有手牌，根据基本牌与锦囊牌数量的差值X：大于0，你于本回合使用的前X张牌不计入次数；等于0，你摸场上势力数张牌；小于0，你可以将-X张牌当作一张目标为任一势力所有角色（不大于-X）的普通锦囊牌使用。",
  ["#fengsui_heg__ruluo-invoke"] = "入洛：是否发动？",
  ["@fengsui_heg__ruluo_free-turn"] = "入洛",
  ["#fengsui_heg__ruluo-kingdom"] = "入洛：选择角色数不大于 %arg 的一个势力",
  ["#fengsui_heg__ruluo-cards"] = "入洛：选择 %arg 张牌作为转化牌",
  ["#fengsui_heg__ruluo-trick"] = "入洛：选择要视为使用的普通锦囊牌",
  ["fengsui_heg__ruluo_opt1"] = "非基本牌可当同字数且未以此法用过的锦囊牌使用",
  ["fengsui_heg__ruluo_opt2"] = "基本牌本回合无次数距离限制",
  ["fengsui_heg__ruluo_opt3"] = "体力值小于展示牌类别数的角色本回合非锁定技失效",
  ["$fengsui_heg__lingzhi1"] = "司马齐王怙恶不悛，吾必以文伐之！",
  ["$fengsui_heg__lingzhi2"] = "天下动荡，正是我辈名士展露凌云之志之际！",
  ["$fengsui_heg__lingzhi3"] = "既然身负才望，岂能因逢乱世而避居江东？",
  ["$fengsui_heg__lingzhi4"] = "中原易变，吾当以区区微躯，匡正世艰！",
  ["$fengsui_heg__ruluo1"] = "洛下文风，今日起，当由吾辈引领！",
  ["$fengsui_heg__ruluo2"] = "早闻天下智者盛，今朝入京识时贤！",
  ["$fengsui_heg__ruluo3"] = "辞别故土，跨越江汉，只为一展胸中锦绣！",
  ["$fengsui_heg__ruluo4"] = "平吴之役，唯获二俊，正指吾与二弟！",
  ["~fengsui_heg__lujii"] = "华亭鹤唳，可复闻乎？",
}

local zhouchu = General:new(extension, "fengsui_heg__zhouchu", "jin", 4)
zhouchu.mainMaxHpAdjustedValue = -1
zhouchu.subkingdom = "wu"
zhouchu:addCompanions("fengsui_heg__zhanghua")
zhouchu:addSkills { "fengsui_heg__tuanfeng", "fengsui_heg__xuanhe" }

Fk:loadTranslationTable{
  ["fengsui_heg__zhouchu"] = "周处",
  ["#fengsui_heg__zhouchu"] = "踏风寻古",
  ["designer:fengsui_heg__zhouchu"] = "公冶天纵",
  ["illustrator:fengsui_heg__zhouchu"] = "公冶天纵",
  ["cv:fengsui_heg__zhouchu"] = "暂无",
  ["fengsui_heg__tuanfeng"] = "抟风",
  [":fengsui_heg__tuanfeng"] = "准备阶段开始时，你可以重铸一张牌，本轮同势力角色于其出牌阶段使用第一张与此牌类别相同的牌时，你可以令此牌不计入次数且无距离限制。",
  ["#fengsui_heg__tuanfeng-recast"] = "抟风：请选择一张牌重铸",
  ["#fengsui_heg__tuanfeng-double"] = "抟风：是否令 %dest 使用的此牌额外结算一次？",
  ["fengsui_heg__xuanhe"] = "悬河",
  [":fengsui_heg__xuanhe"] = "主将技，锁定技，你计算体力上限时减少1个单独的阴阳鱼。当你于回合内首次使用牌指定目标后，所有目标本回合下一张牌无法使用或打出与此牌类别相同的牌。同势力其他角色每回合每种类别的首张牌无法指定你为目标。",
  ["$fengsui_heg__tuanfeng1"] = "抟风九万里，纵览九州岁时节令。",
  ["$fengsui_heg__tuanfeng2"] = "十里不同风，百里不同俗，且容我一一记下。",
  ["$fengsui_heg__tuanfeng3"] = "端阳悬艾，重九登高，皆录于此卷《风土》之中。",
  ["$fengsui_heg__tuanfeng4"] = "朔风惊节换，笔墨写岁华。",
  ["$fengsui_heg__xuanhe1"] = "昨日种种，譬如昨日死；今日种种，当如大河清！",
  ["$fengsui_heg__xuanhe2"] = "人生分水，自此而别；悬崖勒马，再不复返！",
  ["$fengsui_heg__xuanhe3"] = "匹夫之勇，祸害乡里；君子之道，我又该向何处去求？",
  ["$fengsui_heg__xuanhe4"] = "欲改过，恐年岁已迟；欲前行，又恐重蹈覆辙……我之前路，大雾弥漫。",
  ["~fengsui_heg__zhouchu"] = "忠长河水尽，风土长存……我的路，就走到这了。",
}

-- 群-晋
local peixiu = General:new(extension, "fengsui_heg__peixiu", "jin", 3)
peixiu.subkingdom = "qun"
peixiu:addCompanions("fengsui_heg__shantao")
peixiu:addSkills { "fengsui_heg__juezhi", "fengsui_heg__yunie" }

Fk:loadTranslationTable{
  ["fengsui_heg__peixiu"] = "裴秀",
  ["#fengsui_heg__peixiu"] = "亲勘勋德",
  ["designer:fengsui_heg__peixiu"] = "公冶天纵",
  ["illustrator:fengsui_heg__peixiu"] = "公冶天纵",
  ["cv:fengsui_heg__peixiu"] = "暂无",
  ["fengsui_heg__juezhi"] = "爵制",
  [":fengsui_heg__juezhi"] = "出牌阶段限一次，你可以进行X次判定，然后获得其中点数和花色均不相同的任意张牌。（X为场上势力数）",
  ["#fengsui_heg__juezhi"] = "爵制：进行X次判定并获得点数和花色均不相同的牌",
  ["#fengsui_heg__juezhi-choose"] = "爵制：选择一张点数和花色均未与已选牌重复的判定牌获得，或取消结束",
  ["fengsui_heg__yunie"] = "舆臬",
  [":fengsui_heg__yunie"] = "当一张判定牌即将生效时，若你的武将牌均明置，你可以暗置此武将牌并移动场上一张牌，若如此做，你将此次判定牌的花色与点数改为与移动牌一致。当你失去任意区域的最后一张牌后，你可以明置此武将牌。",
  ["#fengsui_heg__yunie-invoke"] = "舆臬：是否暗置并改判 %dest 的判定牌？",
  ["#fengsui_heg__yunie-move"] = "舆臬：选择一张场上牌作为改判依据",
  ["#fengsui_heg__yunie-reveal"] = "舆臬：你可以明置此武将牌",
  ["$fengsui_heg__juezhi1"] = "公虽次于王，然亦有禄奉礼秩。",
  ["$fengsui_heg__juezhi2"] = "乡公、亭伯之属，小而杂，难彰国朝任人唯功之明。",
  ["$fengsui_heg__yunie1"] = "制图当因地而宜，所以校夷险之异。",
  ["$fengsui_heg__yunie2"] = "无迂直之校，则必失准望之正。",
  ["~fengsui_heg__peixiu"] = "服罢寒食散，蹉跎又一年。",
}

local zhugejing = General:new(extension, "fengsui_heg__zhugejing", "jin", 4)
zhugejing.mainMaxHpAdjustedValue = -1
zhugejing.subkingdom = "qun"
zhugejing:addCompanions("fengsui_heg__shantao")
zhugejing:addSkills { "fengsui_heg__yanzuo", "fengsui_heg__pijian", "fengsui_heg__zeyu" }

Fk:loadTranslationTable{
  ["fengsui_heg__zhugejing"] = "诸葛京",
  ["#fengsui_heg__zhugejing"] = "荫泉毓世",
  ["designer:fengsui_heg__zhugejing"] = "公冶天纵",
  ["illustrator:fengsui_heg__zhugejing"] = "公冶天纵",
  ["cv:fengsui_heg__zhugejing"] = "暂无",
  ["fengsui_heg__yanzuo"] = "研作",
  [":fengsui_heg__yanzuo"] = "出牌阶段限一次，你可以重铸任意张类别相同的牌，若不为装备牌，你视为使用一张所重铸类别的基本牌或普通锦囊牌（目标数需和重铸牌数相等）。",
  ["#fengsui_heg__yanzuo"] = "研作：重铸至少两张同类别牌，视为使用对应类别的一张非装备牌",
  ["#fengsui_heg__yanzuo-name"] = "研作：请选择要视为使用的牌，并指定恰好%arg名目标",
  ["fengsui_heg__pijian"] = "辟剑",
  [":fengsui_heg__pijian"] = "主将技，你计算体力上限时减少1个单独的阴阳鱼。其他角色的回合结束阶段，若你拥有本回合进入弃牌堆所包含的所有类别的牌，你可弃置之并对其造成一点雷属性伤害。",
  ["#fengsui_heg__pijian-invoke"] = "辟剑：是否对 %dest 发动？",
  ["#fengsui_heg__pijian-card"] = "辟剑：选择一张%arg牌弃置，以对%dest造成1点雷电伤害",
  ["fengsui_heg__zeyu"] = "泽誉",
  [":fengsui_heg__zeyu"] = "副将技，当与你势力相同的角色杀死一名势力不同的角色时，你可令其摸两张牌并选择一项：1.主副将易位；2.变更副将。",
  ["#fengsui_heg__zeyu-invoke"] = "泽誉：是否对 %dest 发动？",
  ["#fengsui_heg__zeyu-choice"] = "泽誉：请选择一项",
  ["fengsui_heg__zeyu_swap"] = "主副将易位",
  ["fengsui_heg__zeyu_transform"] = "变更副将",
  ["$fengsui_heg__yanzuo1"] = "雪落墨砚，毛峰绽寒梅，书留亘古香。",
  ["$fengsui_heg__yanzuo2"] = "隆中言在耳，出师表在目，篱门待三顾之人。",
  ["$fengsui_heg__pijian1"] = "紫电斩霜絮，目辞千山暮雪，红泥落归鸿。",
  ["$fengsui_heg__pijian2"] = "剑锋入手寒，难凉热血，丹心照碧空。",
  ["$fengsui_heg__zeyu1"] = "熟读情势，憾无沙场纵横。",
  ["$fengsui_heg__zeyu2"] = "泛舟沧海，风动云帆，送我步青云。",
  ["~fengsui_heg__zhugejing"] = "夜梦惊寒，啼血杜鹃失故园。",
}


local yangjun = General:new(extension, "fengsui_heg__yangjun", "wild", 4)
yangjun:addCompanions("fengsui_heg__yangzhi", "fengsui_heg__yangyan")
yangjun:addSkills { "fengsui_heg__guishang", "fengsui_heg__aobi" }

Fk:loadTranslationTable{
  ["fengsui_heg__yangjun"] = "杨骏",
  ["#fengsui_heg__yangjun"] = "权倾朝野",
  ["designer:fengsui_heg__yangjun"] = "公冶天纵",
  ["illustrator:fengsui_heg__yangjun"] = "公冶天纵",
  ["cv:fengsui_heg__yangjun"] = "暂无",
  ["fengsui_heg__guishang"] = "诡赏",
  [":fengsui_heg__guishang"] = "出牌阶段，你可以展示至少一张牌并选择一名本回合未以此法选择过的角色，令其选择一项：1.获得这些牌并执行一个军令；2.弃置至少一张与展示牌不同花色的牌，然后其视为使用仅指定其与你的【以逸待劳】。出牌阶段结束时，本回合获得牌唯一最多的角色对唯一最少的角色造成一点伤害。",
  ["#fengsui_heg__guishang"] = "诡赏：展示至少一张牌并选择一名本回合未以此法选择过的角色",
  ["#fengsui_heg__guishang-show"] = "诡赏：展示至少一张手牌并令 %dest 选择",
  ["#fengsui_heg__guishang-choice"] = "诡赏：请选择一项",
  ["fengsui_heg__guishang_gain"] = "获得这些牌并执行一个军令",
  ["fengsui_heg__guishang_discard_use"] = "弃置牌，然后视为使用【以逸待劳】",
  ["#fengsui_heg__guishang-discard"] = "诡赏：弃置至少一张与展示牌花色均不同的牌",
  ["fengsui_heg__aobi"] = "拗愎",
  [":fengsui_heg__aobi"] = "锁定技，回合开始时，你选择一项：1.本回合仅能对自己使用牌，用一张牌后，摸一张牌；2.本回合仅能对其他角色使用牌，首次使用一种花色的牌额外结算一次。回合结束时，若你本回合未造成过伤害，你失去一点体力值。",
  ["#fengsui_heg__aobi-choice"] = "拗愎：请选择一项",
  ["fengsui_heg__aobi_self"] = "本回合仅能对自己使用牌，用一张牌后摸一张牌",
  ["fengsui_heg__aobi_others"] = "本回合仅能对其他角色使用牌，首次使用一种花色的牌额外结算一次",
  ["$fengsui_heg__guishang1"] = "这是赏给你的！",
  ["$fengsui_heg__guishang2"] = "别争斗，见者有份！",
  ["$fengsui_heg__aobi1"] = "吾权倾朝野，终有一日夺得这天下！",
  ["$fengsui_heg__aobi2"] = "汝等屡番劝谏与吾志相悖，吾唯从吾心！",
  ["~fengsui_heg__yangjun"] = "唉，终是难逃灭门之祸。",
}
-- 魏
local xuncan = General:new(extension, "fengsui_heg__xuncan", "wei", 3)
xuncan:addCompanions("hs__xunyu")
xuncan:addSkills { "fengsui_heg__fenchai", "fengsui_heg__youming" }
Fk:loadTranslationTable{
  ["fengsui_heg__xuncan"] = "荀粲",
  ["#fengsui_heg__xuncan"] = "哀其易逝",
  ["designer:fengsui_heg__xuncan"] = "公冶天纵",
  ["illustrator:fengsui_heg__xuncan"] = "公冶天纵",
  ["cv:fengsui_heg__xuncan"] = "暂无",
  ["fengsui_heg__fenchai"] = "分钗",
  [":fengsui_heg__fenchai"] = "出牌阶段限一次，你可以选择一名异性其他角色，你与其依次视为对彼此使用一张无视距离的冰【杀】；当你使用或成为冰【杀】的目标后，若此牌造成伤害，你可令受到伤害的角色<a href='heg__hebi'>合璧</a>或变更副将；若此牌未造成伤害，你可以与其各获得一枚阴阳鱼。",
  ["fengsui_heg__youming"] = "幽明",
  [":fengsui_heg__youming"] = "当你成为其他角色牌的目标后，若你的武将牌均明置，你可以暗置此武将牌，观看来源手牌并将其中一张置于牌堆顶；当你进入濒死状态时，若你的武将牌均明置，你可以暗置此武将牌并亮出牌堆顶的牌和一张伤害来源的手牌，若颜色相同，你恢复一点体力值。",
  ["#fengsui_heg__youming-top"] = "幽明：观看 %dest 的手牌，并选择一张置于牌堆顶",
  ["$fengsui_heg__fenchai1"] = "此卿遗我于人间之相思物乎？",
  ["$fengsui_heg__fenchai2"] = "与卿为好之心，似冬风抚面而不寒。",
  ["$fengsui_heg__fenchai3"] = "此心哀，如涸泽之鲋，无沫相融。",
  ["$fengsui_heg__fenchai4"] = "此心痛，如刀俎犁腹，欲哭无声。",
  ["$fengsui_heg__youming1"] = "我所蹈之节，可以此生践之。",
  ["$fengsui_heg__youming2"] = "衷其情而恪其节，此荀门之教也。",
  ["$fengsui_heg__youming3"] = "春芽不砺冬寒，其必难引暖风归还。",
  ["$fengsui_heg__youming4"] = "我心慕鸳，从一而终。",
  ["~fengsui_heg__xuncan"] = "此钗凝凝，吾妻死之年折之，今可原也。",
}

local caoshi = General:new(extension, "fengsui_heg__caoshi", "wei", 3)
caoshi:addCompanions("fengsui_heg__xuncan")
caoshi:addCompanions("ld__caohong")
caoshi.gender = General.Female
caoshi:addSkill("fengsui_heg__duanjin")
caoshi:addSkill("fengsui_heg__qingshang")

Fk:loadTranslationTable{
  ["fengsui_heg__caoshi"] = "曹氏",
  ["#fengsui_heg__caoshi"] = "清梦还郎",
  ["~fengsui_heg__caoshi"] = "莫为我伤神，荀郎.......",
  ["designer:fengsui_heg__caoshi"] = "公冶天纵",
  ["illustrator:fengsui_heg__caoshi"] = "佚名",
  ["cv:fengsui_heg__caoshi"] = "暂无",
  ["fengsui_heg__duanjin"] = "断衿",
  [":fengsui_heg__duanjin"] = "当此武将牌被移除后，你可以用此武将牌与一名同势力其他角色对应武将牌<a href='heg__yiwei'>易位</a>并各获得一枚珠联璧合标记。",
  ["fengsui_heg__qingshang"] = "清殇",
  [":fengsui_heg__qingshang"] = "锁定技，当你首次因受到致命伤害而进入濒死状态时，你移除此武将牌并防止此伤害，然后伤害来源视为对你使用一张冰【杀】。",
  ["$fengsui_heg__duanjin1"] = "莲枝分断之时，便知此生无悔矣。",
  ["$fengsui_heg__duanjin2"] = "衣带分钗，唯愿君心永记。",
    ["$fengsui_heg__duanjin3"] = "景初之冬，汝为我暖身；如今我以此物作永诀。",
  ["$fengsui_heg__duanjin4"] = "一枝随吾永长生，一枝伴吾散红尘。",
  ["$fengsui_heg__qingshang1"] = "此伤未足令我败，因吾已为汝而生。",
  ["$fengsui_heg__qingshang2"] = "卧冰之身本脆弱，今日受刃更是难免之事。",
    ["$fengsui_heg__qingshang3"] = "孤梦已逝，清殇之痛不过寻常。",
  ["$fengsui_heg__qingshang4"] = "吾即随风而去，愿君一切安好。",
}

local sunsuo = General:new(extension, "fengsui_heg__sunsuo", "wei", 3, 3, General.Female)
sunsuo:addSkills { "fengsui_heg__fenshuang", "fengsui_heg__yingmian" }

Fk:loadTranslationTable{
  ["fengsui_heg__sunsuo"] = "孙琐",
  ["#fengsui_heg__sunsuo"] = "秉‌烛未明",
  ["designer:fengsui_heg__sunsuo"] = "公冶天纵",
  ["illustrator:fengsui_heg__sunsuo"] = "佚名",
  ["cv:fengsui_heg__sunsuo"] = "暂无",
  ["fengsui_heg__fenshuang"] = "纷霜",
  [":fengsui_heg__fenshuang"] = "出牌阶段限一次，你可以令一名攻击范围内含有你的角色对你造成一点伤害，然后本轮下一次作用于你的军令改为由其执行。",
  ["fengsui_heg__yingmian"] = "盈面",
  [":fengsui_heg__yingmian"] = "当你受到伤害后，若你的武将牌均明置，你可以暗置一张武将牌并为一名角色选择一个军令，若其执行，其明置所有武将牌并摸2X张牌（X为其依法明置的武将牌数量）。",
  ["$fengsui_heg__fenshuang1"] = "清商裂云，诸君，可曾闻此仙乐？",
  ["$fengsui_heg__fenshuang2"] = "此身作琴轸，愿奏九霄声。",
    ["$fengsui_heg__fenshuang3"] = "北园宴未歇，妾骨续冰弦。",
  ["$fengsui_heg__fenshuang4"] = "魏宫烛绽情，舞我离鸾劫。",
  ["$fengsui_heg__yingmian1"] = "此泪犹温，可映九重天阙。",
  ["$fengsui_heg__yingmian2"] = "我熄玉台烛，换君照山河。",
  ["$fengsui_heg__yingmian3"] = "灵梦付江海，涌作霸业潮！",
  ["$fengsui_heg__yingmian4"] = "云袖隐山河，千军甲冑明！",
  ["~fengsui_heg__sunsuo"] = "广袖裂云散，残梦归江东。",
}

local renwan = General:new(extension, "fengsui_heg__renwan", "wei", 3, 3, General.Female)
renwan:addCompanions("hs__zhenji")
renwan:addSkills { "fengsui_heg__lixi", "fengsui_heg__juansui" }

Fk:loadTranslationTable{
  ["fengsui_heg__renwan"] = "任婉",
  ["#fengsui_heg__renwan"] = "孤贞不徙",
  ["designer:fengsui_heg__renwan"] = "公冶天纵",
  ["illustrator:fengsui_heg__renwan"] = "公冶天纵",
  ["cv:fengsui_heg__renwan"] = "暂无",
  ["fengsui_heg__lixi"] = "离徙",
  [":fengsui_heg__lixi"] = "锁定技，当你进入濒死状态时，你令所有角色的非锁定技失效直至本回合结束。",
  ["#fengsui_heg__lixi-invalid"] = "离徙：所有角色的非锁定技失效直至本回合结束",
  ["fengsui_heg__juansui"] = "狷谇",
  [":fengsui_heg__juansui"] = "锁定技，当你的体力值变为1时，你摸两张牌并复原你的武将牌，然后你视为使用一张本局未以此法使用过且仅可指定当前回合角色同势力角色为目标的普通锦囊牌。",
  ["#fengsui_heg__juansui-use"] = "狷谇：请使用一张本局未以此法使用过的普通锦囊牌",
  ["$fengsui_heg__lixi1"] = "青砖浸透红颜泪，朱墙难困腊梅香。",
  ["$fengsui_heg__lixi2"] = "素衣何惧霜雪重？俯仰无愧，不须低眉！",
  ["$fengsui_heg__juansui1"] = "莫说七步，便是七百步、七万步，妾也煮不出豆羹。",
  ["$fengsui_heg__juansui2"] = "众妹妹的枕边风，可比祛火汤更合圣意？",
  ["~fengsui_heg__renwan"] = "深情自古总被负，魏宫尽是薄情人。",
}

local liuxun = General:new(extension, "fengsui_heg__liuxun", "wei", 3,3, General.Female)
liuxun:addSkill("fengsui_heg__neixi")
liuxun:addSkill("fengsui_heg__wuli")

Fk:loadTranslationTable{
  ["fengsui_heg__liuxun"] = "刘勋",
  ["#fengsui_heg__liuxun"] = "女保林",
  ["~fengsui_heg__liuxun"] = "识得天下事，奈何身在局中……",
  ["designer:fengsui_heg__liuxun"] = "公冶天纵",
  ["illustrator:fengsui_heg__liuxun"] = "佚名",
  ["cv:fengsui_heg__liuxun"] = "暂无",
  ["fengsui_heg__neixi"] = "内嬉",
  [":fengsui_heg__neixi"] = "出牌阶段限一次，你可以令任意名同势力角色依次展示一张手牌，若颜色或类别均相等，其可摸X张牌并使用此牌（X为其明置武将牌数）。",
  ["fengsui_heg__wuli"] = "忤礼",
  [":fengsui_heg__wuli"] = "锁定技，当你受到伤害后，若你的武将牌均明置，你暗置另一张武将牌且本轮你不能响应同伤害来源势力角色的牌。",
  ["$fengsui_heg__neixi1"] = "广望观风暖，诸君共戏否？",
  ["$fengsui_heg__neixi2"] = "朱履踢鞠起，诸君...接稳了！",
    ["$fengsui_heg__neixi3"] = "陵云台月高，此时不戏更待何时！",
  ["$fengsui_heg__neixi4"] = "彩绳缚玉腕，锦帕覆明眸，猜我掌中物？",
  ["$fengsui_heg__wuli1"] = "陛下倡优声犹响，尔敢斥我？！",
  ["$fengsui_heg__wuli2"] = "吾虽背身去，自有豺犬噬君喉！",
  ["$fengsui_heg__wuli3"] = "哈哈哈！九重天上...原来容不得半声笑！",
  ["$fengsui_heg__wuli4"] = "清商令的唾沫，可比御酒还烈！",
      ["~fengsui_heg__liuxun"] = "陛下怎舍...斩断...石榴枝...",
}

local yanrou = General:new(extension, "fengsui_heg__yanrou", "wei", 4)
yanrou:addCompanions("hs__caocao")
yanrou:addSkills { "fengsui_heg__choutao", "fengsui_heg__yongfan" }

Fk:loadTranslationTable{
  ["fengsui_heg__yanrou"] = "阎柔",
  ["#fengsui_heg__yanrou"] = "缚身孤北",
  ["~fengsui_heg__yanrou"] = "明公之仇，柔无能为之。",
  ["designer:fengsui_heg__yanrou"] = "公冶天纵",
  ["illustrator:fengsui_heg__yanrou"] = "公冶天纵",
  ["cv:fengsui_heg__yanrou"] = "暂无",
  ["fengsui_heg__choutao"] = "仇讨",
  [":fengsui_heg__choutao"] = "其他角色的回合结束阶段，若你本回合获得过牌且手牌数大于其，你可对其使用一张无距离限制的【杀】。",
  ["#fengsui_heg__choutao-invoke"] = "仇讨：你可以对 %dest 使用一张无距离限制的【杀】",
  ["#fengsui_heg__choutao-use"] = "仇讨：请对 %dest 使用一张无距离限制的【杀】",
  ["fengsui_heg__yongfan"] = "雍番",
  [":fengsui_heg__yongfan"] = "当你受到伤害后，若伤害来源与你不为同一势力，你可视为对其使用一张【远交近攻】。",
  ["$fengsui_heg__choutao1"] = "公孙瓒，还我明公刘伯安命来！",
  ["$fengsui_heg__choutao2"] = "幽辽暗无天日，且以我剑涤破障云。",
  ["$fengsui_heg__yongfan1"] = "北风袭玉门，拂我剑而化春风。",
  ["$fengsui_heg__yongfan2"] = "昔始皇筑城以御北，今我身为城。",
}

-- 蜀
local xiahoushi = General:new(extension, "fengsui_heg__xiahoushi", "shu", 3, 3, General.Female)
xiahoushi:addCompanions("hs__zhangfei")
xiahoushi:addSkills { "fengsui_heg__qiaoshi", "fengsui_heg__xinmai" }

Fk:loadTranslationTable{
  ["fengsui_heg__xiahoushi"] = "夏侯涓",
  ["#fengsui_heg__xiahoushi"] = "柴结缘起",
  ["designer:fengsui_heg__xiahoushi"] = "公冶天纵",
  ["illustrator:fengsui_heg__xiahoushi"] = "公冶天纵",
  ["cv:fengsui_heg__xiahoushi"] = "暂无",
  ["fengsui_heg__qiaoshi"] = "樵拾",
  [":fengsui_heg__qiaoshi"] = "当有角色受到属性伤害后，你可以与其各摸一张牌，若其为同势力角色，你可令其<a href='heg__hebi'>合璧</a>或变更副将。",
  ["fengsui_heg__xinmai"] = "薪脉",
  [":fengsui_heg__xinmai"] = "出牌阶段限一次，你可以令一名角色获得本回合进入弃牌堆的所有【杀】，然后令其选择一项：1.受到来自你的一点雷属性伤害；2.暗置一张武将牌。",
  ["$fengsui_heg__qiaoshi1"] = "采樵南山下，拾君一片心。",
  ["$fengsui_heg__qiaoshi2"] = "山有木兮木成樵，心悦君兮君可知。",
  ["$fengsui_heg__xinmai1"] = "夏燕不羡黄金屋，只栖君家檐下巢。",
  ["$fengsui_heg__xinmai2"] = "红袖不解相思意，凭燕传语慰君心。",
  ["~fengsui_heg__xiahoushi"] = "可怜城头白发妪，至死不见征夫还。",
}

local wuxian = General:new(extension, "fengsui_heg__wuxian", "shu", 3, 3, General.Female)
wuxian:addCompanions("hs__liubei")
wuxian:addCompanions("ol_heg__wuyi")
wuxian:addSkills { "fengsui_heg__guixiang", "fengsui_heg__fumian" }

Fk:loadTranslationTable{
  ["fengsui_heg__wuxian"] = "吴苋",
  ["#fengsui_heg__wuxian"] = "锦运长流",
  ["designer:fengsui_heg__wuxian"] = "公冶天纵",
  ["illustrator:fengsui_heg__wuxian"] = "公冶天纵",
  ["cv:fengsui_heg__wuxian"] = "暂无",
  ["fengsui_heg__guixiang"] = "贵相",
  [":fengsui_heg__guixiang"] = "限定技，同势力角色于其回合内除准备和结束外的第X个阶段开始前，你可以将此阶段改为任意一个合法阶段。（X为与你同势力的角色数）",
  ["#fengsui_heg__guixiang-invoke"] = "贵相：是否改变 %dest 当前将要执行的阶段？",
  ["#fengsui_heg__guixiang-choice"] = "贵相：选择要改为的阶段",
  ["fengsui_heg__guixiang_judge"] = "判定阶段",
  ["fengsui_heg__guixiang_draw"] = "摸牌阶段",
  ["fengsui_heg__guixiang_play"] = "出牌阶段",
  ["fengsui_heg__guixiang_discard"] = "弃牌阶段",
  ["#fengsui_heg__guixiang-change"] = "%from 将 %to 的阶段改为了 %arg",
  ["fengsui_heg__fumian"] = "福绵",
  [":fengsui_heg__fumian"] = "出牌阶段开始时，你可以展示一张牌，当此牌：正面朝上离开你的手牌区时，回合结束时你视为使用之；背面朝上离开你的手牌区时，你摸X张牌（X为与你势力相同的角色数）。",
  ["#fengsui_heg__fumian-invoke"] = "福绵：是否展示一张手牌？",
  ["#fengsui_heg__fumian-show"] = "福绵：请选择要展示的手牌",
  ["#fengsui_heg__fumian-use"] = "福绵：请使用此前正面朝上离开手牌区的牌",
  ["$fengsui_heg__guixiang1"] = "繁花似锦，福泽满园，岁岁年年，皆如今日欢颜。",
  ["$fengsui_heg__guixiang2"] = "金鲤跃波，泽福耀广厦，愿君鸿运如东海。",
  ["$fengsui_heg__fumian1"] = "天长地久有时尽，福佑绵绵无绝期。",
  ["$fengsui_heg__fumian2"] = "愿以三尺微命，祈大汉福气长存。",
  ["~fengsui_heg__wuxian"] = "太平本是玄德创，不见我夫享太平。",
}

local zhugezhan = General:new(extension, "fengsui_heg__zhugezhan", "shu", 4)
zhugezhan.deputyMaxHpAdjustedValue = -1
zhugezhan:addCompanions("hs__zhugeliang")
zhugezhan:addSkills { "fengsui_heg__dishang", "fengsui_heg__fuyin" }

Fk:loadTranslationTable{
  ["fengsui_heg__zhugezhan"] = "诸葛瞻",
  ["#fengsui_heg__zhugezhan"] = "背群终焉",
  ["designer:fengsui_heg__zhugezhan"] = "公冶天纵",
  ["illustrator:fengsui_heg__zhugezhan"] = "佚名",
  ["cv:fengsui_heg__zhugezhan"] = "暂无",
  ["fengsui_heg__dishang"] = "抵殇",
  [":fengsui_heg__dishang"] = "主将技，阵法技，你计算体力上限时减少1个单独的阴阳鱼。当围攻角色使用伤害牌指定被围攻角色为目标后，若与你同势力的角色是此围攻关系中的围攻角色，其可以弃置其与被围攻角色任意相同装备栏的各一张牌，令此牌无法被响应。",
  ["#fengsui_heg__dishang-invoke"] = "抵殇：是否弃置你与 %dest 相同装备栏的各一张牌，令此牌无法被响应？",
  ["#fengsui_heg__dishang-slot"] = "抵殇：选择你与 %dest 要各弃置一张牌的装备栏",
  ["fengsui_heg__dishang_equip1"] = "武器栏",
  ["fengsui_heg__dishang_equip2"] = "防具栏",
  ["fengsui_heg__dishang_equip3"] = "防御坐骑栏",
  ["fengsui_heg__dishang_equip4"] = "进攻坐骑栏",
  ["fengsui_heg__dishang_equip5"] = "宝物栏",
  ["fengsui_heg__fuyin"] = "负胤",
  [":fengsui_heg__fuyin"] = "准备阶段，所有其他同势力角色可选择用一张牌替换牌堆顶/底的牌。回合结束时，若你于本回合造成的伤害数大于/小于弃置的牌数，所有选择牌堆顶/牌堆底的角色摸两张牌，选择另一项的角色失去一点体力。",
  ["$fengsui_heg__dishang1"] = "此番须拼死一战，以赎戴罪之身。",
  ["$fengsui_heg__dishang2"] = "攻须凭计，守则尽胆。",
  ["$fengsui_heg__dishang3"] = "疑兵之法，可保此地无虞。",
  ["$fengsui_heg__dishang4"] = "定使魏军虚实难辨，真假不分！",
  ["$fengsui_heg__dishang5"] = "先父所谋天衣无缝，必能救一时之急！",
  ["$fengsui_heg__dishang6"] = "先父昔日所遗，竟使瞻今日得生。",
  ["$fengsui_heg__fuyin1"] = "瞻世受国恩，却未能以才弼国，是罪也。",
  ["$fengsui_heg__fuyin2"] = "美声溢誉，而力不能及，瞻有罪于国。",
  ["$fengsui_heg__fuyin3"] = "宦官弄权掌君，实乃臣下之过也。",
  ["$fengsui_heg__fuyin4"] = "犹豫不决，以致丧师辱国，其罪无可赦也。",
  ["$fengsui_heg__fuyin5"] = "瞻内不能摒除奸宦，外不能守土御敌，愧对陛下。",
  ["$fengsui_heg__fuyin6"] = "绵竹之地今于我，恰如武帝悔轮台。",
  ["~fengsui_heg__zhugezhan"] = "蜀汉衰败，岂是我一人可挡。",
}

local lifuren = General:new(extension, "fengsui_heg__lifuren", "shu", 3, 3, General.Female)
lifuren:addSkills { "fengsui_heg__xunyun", "fengsui_heg__zhengchi" }

Fk:loadTranslationTable{
  ["fengsui_heg__lifuren"] = "李夫人",
  ["#fengsui_heg__lifuren"] = "义烈妇人",
  ["designer:fengsui_heg__lifuren"] = "公冶天纵",
  ["illustrator:fengsui_heg__lifuren"] = "佚名",
  ["cv:fengsui_heg__lifuren"] = "暂无",
  ["fengsui_heg__xunyun"] = "勋殒",
  [":fengsui_heg__xunyun"] = "锁定技，当你首次进入濒死状态时，你令伤害来源选择一项：1.移除副将；2.暗置所有武将牌且本轮无法明置；然后若你脱离濒死，你令一名同势力角色摸X张牌（X为伤害来源势力暗置武将牌数的两倍）。",
  ["fengsui_heg__zhengchi"] = "正斥",
  [":fengsui_heg__zhengchi"] = "每轮限一次，当同势力角色使用一张牌指定目标后，你可与另一名非此牌目标角色拼点，输者额外成为此牌目标，若胜者拼点牌点数小于6，其成为此牌使用者。",
  ["#fengsui_heg__zhengchi-invoke"] = "正斥：你可以与一名非此牌目标角色拼点",
  ["#fengsui_heg__zhengchi-target"] = "正斥：%to 成为了 %arg 的额外目标",
  ["#fengsui_heg__zhengchi-user"] = "正斥：%from 成为了 %arg 的使用者",
  ["$fengsui_heg__xunyun1"] = "此身可碎，炎汉不可辱！",
  ["$fengsui_heg__xunyun2"] = "蜀中男儿皆死绝乎？！竟至此绝境！",
    ["$fengsui_heg__xunyun3"] = "汝辈贪生...必遭天谴！",
  ["$fengsui_heg__xunyun4"] = "江油城破非天意？恨尔等碌碌似豚犊！",
  ["$fengsui_heg__zhengchi1"] = "将军不战则降，可曾问过身后百姓？！",
  ["$fengsui_heg__zhengchi2"] = "虽然如此，将军所守城池，不为不重。",
  ["$fengsui_heg__zhengchi3"] = "屡闻边情甚急，将军全无忧色，何也？",
  ["$fengsui_heg__zhengchi4"] = "汝为男子，先怀不忠不义之心，枉受国家爵禄，吾有何面目与汝相见耶？",
  ["~fengsui_heg__lifuren"] = "可怜巴蜀多名将，不及江油李氏贤.......",
}

local fengsui_heg__xujing = General:new(extension, "fengsui_heg__xujing", "shu", 3)
fengsui_heg__xujing:addCompanions("ld__fazheng")
fengsui_heg__xujing:addSkill("fengsui_heg__yuanyi")
fengsui_heg__xujing:addSkill("fengsui_heg__caixia")

Fk:loadTranslationTable{
  ["fengsui_heg__xujing"] = "许靖",
  ["#fengsui_heg__xujing"] = "清浊自辨",
  ["~fengsui_heg__xujing"] = "誉满天下，才瑕难掩……",
  ["designer:fengsui_heg__xujing"] = "公冶天纵",
  ["illustrator:fengsui_heg__xujing"] = "佚名",
  ["cv:fengsui_heg__xujing"] = "暂无",
  ["fengsui_heg__yuanyi"] = "远鹢",
  [":fengsui_heg__yuanyi"] = "锁定技，当你即将造成或受到伤害时，若目标或伤害来源与你的明置武将牌状态一致，此伤害+1。",
  ["fengsui_heg__caixia"] = "才瑕",
  [":fengsui_heg__caixia"] = "当你造成或受到伤害后，若你的武将牌均明置，你可以摸同势力角色数张牌然后暗置另一张武将牌。",
  ["$fengsui_heg__yuanyi1"] = "靖奔走南北、见才无数，称贤者唯君一人。",
  ["$fengsui_heg__yuanyi2"] = "千里之骥，既遇伯乐，不需积跬步。",
  ["$fengsui_heg__caixia1"] = "君子有德，不图砖瓦之得失，唯效春秋之大义。",
  ["$fengsui_heg__caixia2"] = "至清之水无鱼，既为英才伟士，当彰仁义于众。",
    ["~fengsui_heg__xujing"] = "一生流离，奈何归乡无途。",
}

local fengsui_heg__limi = General:new(extension, "fengsui_heg__limi", "shu", 3)
fengsui_heg__limi:addCompanions("fengsui_heg__qiaozhou")
fengsui_heg__limi:addSkill("fengsui_heg__ciying")
fengsui_heg__limi:addSkill("fengsui_heg__chendu")

Fk:loadTranslationTable{
  ["fengsui_heg__limi"] = "李密",
  ["#fengsui_heg__limi"] = "飞鸟谆谆",
  ["~fengsui_heg__limi"] = "陈情一表，肝肠寸断……",
  ["designer:fengsui_heg__limi"] = "公冶天纵",
  ["illustrator:fengsui_heg__limi"] = "佚名",
  ["cv:fengsui_heg__limi"] = "暂无",
  ["fengsui_heg__ciying"] = "辞应",
  [":fengsui_heg__ciying"] = "当你于回合外需要使用或打出一张基本牌或普通锦囊牌时，若当前回合角色为未确定势力或大势力，你可以视为使用或打出之并选择一项：1.交给其X张牌；2.摸X张牌，然后移除此武将牌（X为本技能本局发动次数）。",
  ["#fengsui_heg__ciying-active"] = "辞应：你可以视为使用或打出需要的基本牌或普通锦囊牌",
  ["#fengsui_heg__ciying-choice"] = "辞应：请选择一项（本局第 %arg 次发动）",
  ["#fengsui_heg__ciying-give"] = "辞应：请交给当前回合角色 %arg 张牌",
  ["fengsui_heg__ciying_give"] = "交给当前回合角色X张牌",
  ["fengsui_heg__ciying_draw"] = "摸X张牌，然后移除此武将牌",
  ["fengsui_heg__chendu"] = "陈笃",
  [":fengsui_heg__chendu"] = "限定技，当场上有角色移除武将牌时，你可以令其依次执行三项：1.主副将<a href='heg__yiwei'>易位</a>；2.与同一名势力角色主将或副将<a href='heg__yiwei'>易位</a>；3.变更副将。",
  ["$fengsui_heg__ciying1"] = "今蒙恩诏，寸心难表，然念祖母，诚难上道。",
  ["$fengsui_heg__ciying2"] = "是臣尽节于陛下之日长，报养刘之日短也。",
    ["$fengsui_heg__ciying3"] = "臣亡国贱虏，蒙陛下累征不弃，敢不陨首以报。",
  ["$fengsui_heg__chendu1"] = "臣无祖母，无以至今日；祖母无臣，无以终余年。",
  ["$fengsui_heg__chendu2"] = "愿陛下矜悯愚诚，听臣微志，庶刘侥幸，保卒余年。",
    ["~fengsui_heg__limi"] = "人亦有言，有因有缘，官无中人，不如归田。",
}

-- 吴
local wangfuren = General:new(extension, "fengsui_heg__wangfuren", "wu", 3, 3, General.Female)
wangfuren:addCompanions("hs__sunquan")
wangfuren:addSkills { "fengsui_heg__qiangong", "fengsui_heg__bizun" }

Fk:loadTranslationTable{
  ["fengsui_heg__wangfuren"] = "王夫人",
  ["#fengsui_heg__wangfuren"] = "无冕之后",
  ["designer:fengsui_heg__wangfuren"] = "公冶天纵",
  ["illustrator:fengsui_heg__wangfuren"] = "公冶天纵",
  ["cv:fengsui_heg__wangfuren"] = "暂无",
  ["fengsui_heg__qiangong"] = "迁宫",
  [":fengsui_heg__qiangong"] = "出牌阶段限一次，你可以令两名角色依次获得彼此相同区域的一张牌，若如此做，你可以令其中的小势力角色摸一张牌。",
  ["#fengsui_heg__qiangong-invoke"] = "迁宫：选择两名角色，令其各获得对方同一区域的一张牌",
  ["#fengsui_heg__qiangong-area"] = "迁宫：选择双方互取牌的区域",
  ["#fengsui_heg__qiangong-take"] = "迁宫：选择要从 %dest 处获得的牌",
  ["#fengsui_heg__qiangong-draw"] = "迁宫：你可以令其中一名小势力角色摸一张牌",
  ["fengsui_heg__qiangong_hand"] = "手牌区",
  ["fengsui_heg__qiangong_equip"] = "装备区",
  ["fengsui_heg__bizun"] = "避尊",
  [":fengsui_heg__bizun"] = "当同势力角色失去某一区域的最后一张牌后，你可以令其摸一张牌。",
  ["$fengsui_heg__qiangong1"] = "东宫既定，妾当迁居公安，以全内廷之序。",
  ["$fengsui_heg__qiangong2"] = "一室之让，可息宫闱之争，亦可安江东之望。",
  ["$fengsui_heg__qiangong3"] = "宫阙虽远，母子之念，岂因江水而绝？",
  ["$fengsui_heg__qiangong4"] = "迁居非逐，退身非怨，惟愿吴宫无隙。",
  ["$fengsui_heg__qiangong5"] = "此身可离建业，此心仍系江东。",
  ["$fengsui_heg__bizun1"] = "尊位非我所求，休儿平安，便胜万千恩宠。",
  ["$fengsui_heg__bizun2"] = "花开太盛易招风雨，不若敛华守静。",
  ["$fengsui_heg__bizun3"] = "退居人后，非为自轻，实为避祸全身。",
  ["$fengsui_heg__bizun4"] = "朝露之宠不足恃，母子之情不可移。",
  ["~fengsui_heg__wangfuren"] = "公安一别，竟无缘亲见休儿践祚……",
}

local heji = General:new(extension, "fengsui_heg__heji", "wu", 3, 3, General.Female)
heji:addSkills { "fengsui_heg__guru", "fengsui_heg__weihou" }

Fk:loadTranslationTable{
  ["fengsui_heg__heji"] = "何姬",
  ["#fengsui_heg__heji"] = "昭献皇后",
  ["designer:fengsui_heg__heji"] = "公冶天纵",
  ["illustrator:fengsui_heg__heji"] = "公冶天纵",
  ["cv:fengsui_heg__heji"] = "暂无",
  ["fengsui_heg__guru"] = "孤茹",
  [":fengsui_heg__guru"] = "锁定技，当你仅明置此武将牌时，你摸牌阶段摸牌数+X；当你武将牌均明置且X小于场上势力数时，你与其他角色的距离+X（X为同势力角色数）。",
  ["fengsui_heg__weihou"] = "维后",
  [":fengsui_heg__weihou"] = "当同势力角色的判定牌即将生效时，若你的武将牌均明置，你可以暗置此武将牌并用装备区的一张牌替代之。然后若这两张牌颜色相同，你可以令其<a href='heg__hebi'>合璧</a>或变更副将。",
  ["#fengsui_heg__weihou-invoke"] = "维后：你可以暗置此武将牌，用一张装备牌修改 %dest 的判定",
  ["$fengsui_heg__guru1"] = "机杼声寒，惟抚此孤成继。",
  ["$fengsui_heg__guru2"] = "丹墀九阶，岂容宵小近御？",
    ["$fengsui_heg__guru3"] = "中庭独守，惟愿皇嗣延祚。",
  ["$fengsui_heg__guru4"] = "若皆从死，谁当养孤？",
  ["$fengsui_heg__weihou1"] = "更易副贰乃大忌，正位中宫以安民心。",
  ["$fengsui_heg__weihou2"] = "双璧联辉，共固吴祚万年！",
  ["$fengsui_heg__weihou3"] = "后若更易，秣陵必生妖氛！",
  ["$fengsui_heg__weihou4"] = "褪我钗钿补金瓯，但求中宫无虞。",
  ["~fengsui_heg__heji"] = "阿皓...降幡已悬...莫再执拗。",
}

local xushi = General:new(extension, "fengsui_heg__xushi", "wu", 3, 3, General.Female)

xushi:addSkill("fengsui_heg__fuzhu")
xushi:addSkill("fengsui_heg__chenmeng")

Fk:loadTranslationTable{
  ["fengsui_heg__xushi"] = "徐美人",
  ["#fengsui_heg__xushi"] = "血瑰",
  ["~fengsui_heg__xushi"] = "残叶落不尽，秋池冷霜寒。",
  ["designer:fengsui_heg__xushi"] = "公冶天纵",
  ["illustrator:fengsui_heg__xushi"] = "佚名",
  ["cv:fengsui_heg__xushi"] = "暂无",
  ["fengsui_heg__fuzhu"] = "伏诛",
  [":fengsui_heg__fuzhu"] = "当你使用伤害牌指定目标后，若你的武将牌均明置，你可以暗置此武将牌，然后令此牌不计入次数且对其中一个目标无效，并令其选择两项：1.你摸已有标记数张牌；2.你弃置其一张牌；3.回合结束后视为对其使用之。",
  ["#fengsui_heg__fuzhu-invoke"] = "伏诛：选择令此牌无效的一名目标",
  ["#fengsui_heg__fuzhu-choice"] = "伏诛：请选择令 %dest 执行的两项",
  ["fengsui_heg__fuzhu_draw"] = "其摸已有国战标记数张牌",
  ["fengsui_heg__fuzhu_discard"] = "其弃置你一张牌",
  ["fengsui_heg__fuzhu_use"] = "回合结束后其视为对你使用此牌",
  ["#fengsui_heg__fuzhu-discard"] = "伏诛：请选择弃置 %dest 的一张牌",
  ["fengsui_heg__chenmeng"] = "谶梦",
  [":fengsui_heg__chenmeng"] = "同势力角色于其出牌阶段可以弃置一枚标记替换牌堆顶的牌。回合结束后，若其没有标记，其获得一枚阴阳鱼标记。",
  ["$fengsui_heg__fuzhu1"] = "这把匕首，就是为你准备的！",
  ["$fengsui_heg__fuzhu2"] = "忍耐已至极限，今日就要终结你！",
  ["$fengsui_heg__chenmeng1"] = "此卦凶险，望夫君慎之。",
  ["$fengsui_heg__chenmeng2"] = "卦象可算，人事难算。",
}

local zhanghuai = General:new(extension, "fengsui_heg__zhanghuai", "wu", 3)
zhanghuai:addCompanions("ld__lukang")
zhanghuai:addSkills { "fengsui_heg__laoyan", "fengsui_heg__jueyan" }

Fk:loadTranslationTable{
  ["fengsui_heg__zhanghuai"] = "张怀",
  ["#fengsui_heg__zhanghuai"] = "连理分枝",
  ["designer:fengsui_heg__zhanghuai"] = "公冶天纵",
  ["illustrator:fengsui_heg__zhanghuai"] = "公冶天纵",
  ["cv:fengsui_heg__zhanghuai"] = "暂无",
  ["fengsui_heg__laoyan"] = "劳燕",
  [":fengsui_heg__laoyan"] = "锁定技，当其他角色使用一张牌指定目标后，若此牌目标数大于1且你为目标之一，你令此牌对其他同势力角色无效，若你未受到伤害且使用者与你势力不同，你摸两张牌。",
  ["fengsui_heg__jueyan"] = "诀言",
  [":fengsui_heg__jueyan"] = "当你使用单体牌指定其他角色后，若你的武将牌均明置，你可以暗置此武将牌并摸一张牌或与目标拼点，赢的角色对没赢的角色造成1点伤害。",
  ["#fengsui_heg__jueyan-invoke"] = "诀言：是否暗置此武将牌，对 %dest 发动？",
  ["#fengsui_heg__jueyan-choice"] = "诀言：选择摸一张牌，或与 %dest 拼点",
  ["fengsui_heg__jueyan_draw"] = "摸一张牌",
  ["fengsui_heg__jueyan_pindian"] = "与目标拼点",
  ["$fengsui_heg__laoyan1"] = "林惊何还巢，有情难相守。",
  ["$fengsui_heg__laoyan2"] = "手捧千重锦，泪染万重山。",
  ["$fengsui_heg__jueyan1"] = "此去山高水远，望君珍重。",
  ["$fengsui_heg__jueyan2"] = "今生不得同室，愿来生葬同穴。",
  ["~fengsui_heg__zhanghuai"] = "得情，忘情，难忘情。。",
}

local fengsui_heg__zhangbai = General:new(extension, "fengsui_heg__zhangbai", "wu", 3)
fengsui_heg__zhangbai:addCompanions("ty_heg__luyusheng")
fengsui_heg__zhangbai:addSkill("fengsui_heg__jincai")
fengsui_heg__zhangbai:addSkill("fengsui_heg__lianxi")

Fk:loadTranslationTable{
  ["fengsui_heg__zhangbai"] = "张白",
  ["#fengsui_heg__zhangbai"] = "儒情之才",
  ["~fengsui_heg__zhangbai"] = "扬州的才子，最终还是败给了时代...",
  ["designer:fengsui_heg__zhangbai"] = "公冶天纵",
  ["illustrator:fengsui_heg__zhangbai"] = "佚名",
  ["cv:fengsui_heg__zhangbai"] = "暂无",
  ["fengsui_heg__jincai"] = "矜才",
  [":fengsui_heg__jincai"] = "每轮限一次，当你使用红色基本牌或普通锦囊牌后，你可以令一名角色选择一项：1.摸两张牌暗置一张武将牌，其本轮对你下一次造成的伤害-1；2.本回合不能使用红色牌。",
  ["#fengsui_heg__jincai-choose"] = "矜才：选择一名角色令其选择一项",
  ["#fengsui_heg__jincai-choice"] = "矜才：请选择一项（技能发动者为 %dest）",
  ["fengsui_heg__jincai_draw"] = "摸两张牌并暗置一张武将牌，本轮对技能发动者的下一次伤害-1",
  ["fengsui_heg__jincai_red"] = "本回合不能使用红色牌",
  ["fengsui_heg__lianxi"] = "连徙",
  [":fengsui_heg__lianxi"] = "当与你势力相同的角色暗置武将牌后，你可以弃置其一个区域所有牌并对当前回合角色造成一点伤害，然后你与一名同势力其他角色副将<a href='heg__yiwei'>易位</a>。",
  ["$fengsui_heg__jincai1"] = "笔墨本为诤言劝主，今日只能书写无奈之志。",
  ["$fengsui_heg__jincai2"] = "权贵之心如秋草，昨日喜哀今朝弃之。",
    ["$fengsui_heg__jincai3"] = "才学满腹却无处可施，此乃吾之恨也。",
  ["$fengsui_heg__jincai4"] = "宁可守节如石，也绝不随波逐流。",
  ["$fengsui_heg__lianxi1"] = "吴郡江水啊，可曾将吾之志向带往远方？",
  ["$fengsui_heg__lianxi2"] = "扬州才子终败于时代洪流，此非悔恨乃宿命使然。",
  ["$fengsui_heg__lianxi3"] = "温兄昔日权倾，今朝家毁；我张白不过此悲歌中一音符。",
  ["$fengsui_heg__lianxi4"] = "温兄触怒孙权，我遂沦为弃子，再无出仕之机。",
}

local heqi = General:new(extension, "fengsui_heg__heqi", "wu", 4)
heqi:addSkills { "fengsui_heg__junwei" }

Fk:loadTranslationTable{
  ["fengsui_heg__heqi"] = "贺齐",
  ["#fengsui_heg__heqi"] = "群马越峦",
  ["~fengsui_heg__heqi"] = "你的刀，比我还快……",
  ["designer:fengsui_heg__heqi"] = "公冶天纵",
  ["illustrator:fengsui_heg__heqi"] = "夺帅",
  ["cv:fengsui_heg__heqi"] = "暂无",
  ["fengsui_heg__junwei"] = "军威",
  [":fengsui_heg__junwei"] = "准备阶段开始时，你可以选择一个军令并令至多X名势力不同的角色依次选择一项（不能选重复项）：1.执行一个军令并移动场上一张牌；2.弃置区域内的一张牌并摸两张牌；3.暗置一张武将牌且本回合无法明置；4.弃置所有手牌并摸等量的牌（X为同势力角色数）。",
  ["#fengsui_heg__junwei-targets"] = "军威：选择至多 %arg 名与你势力不同的角色",
  ["#fengsui_heg__junwei-choice"] = "军威：请选择一项，已被选择的选项不能重复",
  ["#fengsui_heg__junwei-move"] = "军威：你可以移动场上的一张牌",
  ["#fengsui_heg__junwei-discard"] = "军威：请选择区域内的一张牌弃置，然后摸两张牌",
  ["fengsui_heg__junwei_opt1"] = "执行军令并移动场上的一张牌",
  ["fengsui_heg__junwei_opt2"] = "弃置区域内的一张牌并摸两张牌",
  ["fengsui_heg__junwei_opt3"] = "暗置一张武将牌且本回合无法明置",
  ["fengsui_heg__junwei_opt4"] = "弃置所有手牌并摸等量的牌",
  ["@@fengsui_heg__junwei-turn"] = "军威 禁止明置",
  ["$fengsui_heg__junwei1"] = "这一身装备，叫你们开开眼界！",
  ["$fengsui_heg__junwei2"] = "和我来一场华丽的战斗吧！",
  ["$fengsui_heg__junwei3"] = "看看你的身后吧，蠢货！",
  ["$fengsui_heg__junwei4"] = "拔剑断水，起波澜而涤大吴之江。",
}

-- 群
local mazhi = General:new(extension, "fengsui_heg__mazhi", "qun", 3, 3, General.Female)
mazhi:addCompanions("fengsui_heg__malun")
mazhi:addSkills { "fengsui_heg__shenqing", "fengsui_heg__juangu" }

Fk:loadTranslationTable{
  ["fengsui_heg__mazhi"] = "马芝",
  ["#fengsui_heg__mazhi"] = "恋恋吾乡",
  ["designer:fengsui_heg__mazhi"] = "公冶天纵",
  ["illustrator:fengsui_heg__mazhi"] = "公冶天纵",
  ["cv:fengsui_heg__mazhi"] = "暂无",
  ["fengsui_heg__shenqing"] = "申情",
  [":fengsui_heg__shenqing"] = "限定技，出牌阶段，你可以选择场上两张武将牌，若其中有满足【珠联璧合】的武将牌，则其所属角色各获得一枚【珠联璧合】标记；若均不满足，你可以令其中一位所属角色<a href='heg__hebi'>合璧</a> 或变更副将。",
  ["fengsui_heg__juangu"] = "眷故",
  [":fengsui_heg__juangu"] = "当一名拥有珠联璧合武将牌的角色于其回合内首次使用的牌指定另一名拥有与其配对之珠联璧合武将牌的角色为目标后，若此两张武将牌：不属于同一名角色，你可以令其各摸一张牌；属于同一名角色，你可以令此牌额外执行一次。",
  ["$fengsui_heg__shenqing1"] = "字字啼血成赋，句句唤故人归...",
  ["$fengsui_heg__shenqing2"] = "昔年同窗烛今燃，可照前路？",
    ["$fengsui_heg__shenqing3"] = "父亲，阿姊，若在泉下闻此诵，应展颜...",
  ["$fengsui_heg__shenqing4"] = "纵使金瓯碎，也为玉胶缀残璋！",
  ["$fengsui_heg__juangu1"] = "罗衣飘扬惊幡时，故人泪落谱新声。",
  ["$fengsui_heg__juangu2"] = "绛帐遗风拂过处，枯树再著经年花。",
  ["$fengsui_heg__juangu3"] = "此情若散白绫，虽遥天际但永世不断。",
  ["$fengsui_heg__juangu4"] = "此心似连理根，虽隔天地但犹感同脉。",
  ["~fengsui_heg__mazhi"] = "寂夜理残卷，忽闻阿姊唤...",
}
local fengsui_heg__malun = General:new(extension, "fengsui_heg__malun", "qun", 3,3, General.Female)
fengsui_heg__malun:addCompanions("fengsui_heg__mazhi")
fengsui_heg__malun:addSkill("fengsui_heg__dexiang")
fengsui_heg__malun:addSkill("fengsui_heg__heci")

Fk:loadTranslationTable{
  ["fengsui_heg__malun"] = "马伦",
  ["#fengsui_heg__malun"] = "营克婉变",
  ["~fengsui_heg__malun"] = "趋炎附势，终成笑谈……",
  ["designer:fengsui_heg__malun"] = "公冶天纵",
  ["illustrator:fengsui_heg__malun"] = "佚名",
  ["cv:fengsui_heg__malun"] = "暂无",
  ["fengsui_heg__dexiang"] = "德象",
  [":fengsui_heg__dexiang"] = "与任意同势力角色距离不大于1的角色使用单体基本牌或普通锦囊牌指定目标后，若其不为目标且武将牌均明置，其可以暗置一张武将牌成为此牌的额外目标。",
  ["fengsui_heg__heci"] = "赫辞",
  [":fengsui_heg__heci"] = "每回合限一次，你可以将X张牌当作一张本轮未进入过弃牌堆的普通锦囊牌使用（X为同势力角色已明置武将牌数）。",
  ["#fengsui_heg__heci-active"] = "赫辞：请选择 %arg 张牌，并选择要视为使用的普通锦囊牌",
  ["$fengsui_heg__dexiang1"] = "袁门风雨骤，妾身化君屏。",
  ["$fengsui_heg__dexiang2"] = "且效先贤举案德，代承此劫！",
    ["$fengsui_heg__dexiang3"] = "绛帐家风在，岂容君子独危？",
  ["$fengsui_heg__dexiang4"] = "承父书万卷，当承此刀。",
  ["$fengsui_heg__heci1"] = "君若欲慕鲍宣、梁鸿之高者，妾亦请从少君、孟光之事矣。",
  ["$fengsui_heg__heci2"] = "慈亲垂爱，不敢逆命。",
  ["$fengsui_heg__heci3"] = "妾姊高行殊邈，未遭良匹，不似鄙薄，苟然而已。",
  ["$fengsui_heg__heci4"] = "孔子大圣，不免武叔之毁；子路至贤，犹有伯寮之愬。",
    ["~fengsui_heg__malun"] = "董贼！青史必书尔戕害忠良罪！",
}

local gongsunxiu = General:new(extension, "fengsui_heg__gongsunxiu", "qun", 4)
gongsunxiu:addCompanions("ld__gongsunyuan")
gongsunxiu:addSkills { "fengsui_heg__kuizhen", "fengsui_heg__niejiang" }

Fk:loadTranslationTable{
  ["fengsui_heg__gongsunxiu"] = "公孙修",
  ["#fengsui_heg__gongsunxiu"] = "逆战辽河",
  ["designer:fengsui_heg__gongsunxiu"] = "公冶天纵",
  ["illustrator:fengsui_heg__gongsunxiu"] = "公冶天纵",
  ["cv:fengsui_heg__gongsunxiu"] = "暂无",
  ["fengsui_heg__kuizhen"] = "溃阵",
  [":fengsui_heg__kuizhen"] = "出牌阶段限一次，你可以弃置一张黑色【杀】，令一名与你势力不同的角色视为对你使用一张【决斗】，若你因此受到伤害，你观看其手牌并获得其中的【杀】，若没有【杀】，其失去1点体力。",
  ["fengsui_heg__niejiang"] = "蹑江",
  [":fengsui_heg__niejiang"] = "锁定技，每名角色每轮限一次，当一名角色的体力值变化后，若为全场最低，你摸一张牌，若此牌为【杀】，你展示并使用之。你与全场体力值最低的其他所有角色的距离始终为1。",
  ["#fengsui_heg__niejiang-use"] = "蹑江：请使用摸到的【杀】",
  ["$fengsui_heg__kuizhen1"] = "贼尚惧孔明一州之地，今敢来攻我邪！",
  ["$fengsui_heg__kuizhen2"] = "尔等忘北地之风乎？尔等忘北地之寒乎？",
  ["$fengsui_heg__niejiang1"] = "周武继文王之志而开国百年，今吾亦可为之。",
  ["$fengsui_heg__niejiang2"] = "父起于微末而定海内，今承王爵，当以死效之。",
  ["~fengsui_heg__gongsunxiu"] = "司马懿老谋深算，非常人可敌。",
}

local tianchou = General:new(extension, "fengsui_heg__tianchou", "qun", 4)
tianchou:addSkills { "fengsui_heg__shoujie" }

Fk:loadTranslationTable{
  ["fengsui_heg__tianchou"] = "田畴",
  ["#fengsui_heg__tianchou"] = "乱世遁节",
  ["designer:fengsui_heg__tianchou"] = "公冶天纵",
  ["illustrator:fengsui_heg__tianchou"] = "公冶天纵",
  ["cv:fengsui_heg__tianchou"] = "暂无",
  ["fengsui_heg__shoujie"] = "守节",
  [":fengsui_heg__shoujie"] = "与你势力相同的角色成为多目标锦囊牌的目标后，你可以弃置手牌区或装备区的所有牌，取消其中至多等量名角色的目标。当你成为同势力角色牌的目标后，若你任意一个区域的牌大于其，取消之。",
  ["$fengsui_heg__shoujie1"] = "岂可以卢龙之径，换一己之爵禄哉？",
  ["$fengsui_heg__shoujie2"] = "畴乃负义逃窜之人，蒙恩苟活已是万幸，",
  ["$fengsui_heg__shoujie3"] = "功非本意，爵不敢受；此行，只为报旧主之恩，雪昔日之恨！",
  ["$fengsui_heg__shoujie4"] = "若再相逼，畴唯有颈血溅地，以明本心！",
  ["~fengsui_heg__tianchou"] = "吾罪大矣，何堪封侯之荣？",
}

local yuantan = General:new(extension, "fengsui_heg__yuantan", "qun", 4)
yuantan:addCompanions("hs__yuanshao")
yuantan:addSkills { "fengsui_heg__qiaosi", "fengsui_heg__baizu" }

Fk:loadTranslationTable{
  ["fengsui_heg__yuantan"] = "袁谭",
  ["#fengsui_heg__yuantan"] = "袁门孑嗣",
  ["designer:fengsui_heg__yuantan"] = "公冶天纵",
  ["illustrator:fengsui_heg__yuantan"] = "公冶天纵",
  ["cv:fengsui_heg__yuantan"] = "暂无",
  ["fengsui_heg__qiaosi"] = "峭嗣",
  [":fengsui_heg__qiaosi"] = "结束阶段，你可以获得本回合进入弃牌堆一种类别的牌，若你以此法获得牌的数量不等于你的当前体力值，你失去1点体力。",
  ["#fengsui_heg__qiaosi-choice"] = "峭嗣：你可以获得本回合进入弃牌堆的一种类别的所有牌",
  ["fengsui_heg__qiaosi_basic"] = "基本牌",
  ["fengsui_heg__qiaosi_trick"] = "锦囊牌",
  ["fengsui_heg__qiaosi_equip"] = "装备牌",
  ["fengsui_heg__baizu"] = "败族",
  [":fengsui_heg__baizu"] = "锁定技，结束阶段，若你已受伤且有手牌，你须选择所有势力各一名其他角色同时弃置一张牌，弃置牌类别相同的角色失去一点体力，若因此有角色死亡，若其与你势力相同/不同，你移除副将/摸其势力数张牌。",
  ["$fengsui_heg__qiaosi1"] = "身居长位，犹处峭崖之巅。",
  ["$fengsui_heg__qiaosi2"] = "为长而不得承嗣，岂有善终乎？",
  ["$fengsui_heg__baizu1"] = "今袁氏之势，岂独因我？",
  ["$fengsui_heg__baizu2"] = "长幼之序不明，何惜操戈以正！",
  ["~fengsui_heg__yuantan"] = "咄，儿过我，必使富贵……呃啊！",
}


local fengsui_heg__fuhuanghou = General:new(extension, "fengsui_heg__fuhuanghou", "qun", 3)
fengsui_heg__fuhuanghou.gender = General.Female
fengsui_heg__fuhuanghou:addSkill("fengsui_heg__qujian")
fengsui_heg__fuhuanghou:addSkill("fengsui_heg__weiluan")

Fk:loadTranslationTable{
  ["fengsui_heg__fuhuanghou"] = "伏寿",
  ["#fengsui_heg__fuhuanghou"] = "高鸾一撇",
  ["~fengsui_heg__fuhuanghou"] = "深宫岁月，终成枯骨……",
  ["designer:fengsui_heg__fuhuanghou"] = "公冶天纵",
  ["illustrator:fengsui_heg__fuhuanghou"] = "佚名",
  ["cv:fengsui_heg__fuhuanghou"] = "暂无",
  ["fengsui_heg__qujian"] = "祛僭",
[":fengsui_heg__qujian"] = "准备阶段，你可以令至多同势力角色数名角色各摸一张牌，其中手牌数唯一最少的角色视为对唯一最多的角色使用一张雷【杀】，然后你可以与一名以此法摸牌的角色拼点，败者进入连环状态。",
  ["#fengsui_heg__qujian-choose"] = "祛僭：选择至多 %arg 名角色各摸一张牌",
  ["#fengsui_heg__qujian-pindian"] = "祛僭：你可以选择一名以此法摸牌的角色拼点",
  ["fengsui_heg__weiluan"] = "危鸾",
  [":fengsui_heg__weiluan"] = "当同势力角色成为一张伤害牌的目标后，若你武将牌均明置，你可以暗置此武将牌并令其摸一张牌并将一张牌置于牌堆顶。",
  ["#fengsui_heg__weiluan-invoke"] = "危鸾：是否暗置此武将牌，令 %dest 摸一张牌并将一张手牌置于牌堆顶？",
  ["#fengsui_heg__weiluan-top"] = "危鸾：请选择一张手牌置于牌堆顶",
  ["$fengsui_heg__qujian1"] = "踽踽独行，何人援之？",
  ["$fengsui_heg__qujian2"] = "惴惴不安，谁又在暗处窥看？",
  ["$fengsui_heg__weiluan1"] = "大汉四百年基业，岂可毁于曹贼之手？",
  ["$fengsui_heg__weiluan2"] = "这天下，还有道理吗？",
      ["~fengsui_heg__fuhuanghou"] = "父亲大人，你竟如此优柔寡断……",
}

-- 晋
-- 晋（纯晋势力）
local hulie = General:new(extension, "fengsui_heg__hulie", "jin", 4)
hulie:addSkills { "fengsui_heg__kunshi", "fengsui_heg__fudao" }

Fk:loadTranslationTable{
  ["fengsui_heg__hulie"] = "胡烈",
  ["#fengsui_heg__hulie"] = "塞上逆锋",
  ["designer:fengsui_heg__hulie"] = "公冶天纵",
  ["illustrator:fengsui_heg__hulie"] = "公冶天纵",
  ["cv:fengsui_heg__hulie"] = "暂无",
  ["fengsui_heg__kunshi"] = "困势",
  [":fengsui_heg__kunshi"] = "阵法技，锁定技，当你对被围攻角色造成伤害后，若你是此围攻关系中的围攻角色，此伤害+1；当你受到伤害后，若你是此围攻关系中的被围攻角色，此伤害+1；你的围攻关系内，未确定势力角色视为形成围攻关系的一方。",
  ["fengsui_heg__fudao"] = "覆倒",
  [":fengsui_heg__fudao"] = "限定技，当你即将造成伤害时，你可以弃置所有手牌令此次伤害+X，此伤害结算后，目标视为对你依次使用本回合进入弃牌堆不同牌名的伤害牌。（X为本回合你使用过的伤害牌牌名数）",
  ["$fengsui_heg__kunshi1"] = "万斛黄沙，漫天尘土……",
  ["$fengsui_heg__kunshi2"] = "敌众我寡，势已危急，速退！速退啊！",
  ["$fengsui_heg__kunshi3"] = "援军何在？扶风王按兵不动，是要陷我于死地吗？",
  ["$fengsui_heg__kunshi4"] = "纵使身陷绝境，亦当奋力一搏！随我冲！",
  ["$fengsui_heg__fudao1"] = "顽抗之徒，唯有铁腕镇之！给我踏平此地！",
  ["$fengsui_heg__fudao2"] = "根基已破，大势已去，你们的好日子到头了！",
  ["$fengsui_heg__fudao3"] = "大厦将倾，岂容一木独存？",
  ["$fengsui_heg__fudao4"] = "我命休矣……尔等，也休想活！",
  ["~fengsui_heg__hulie"] = "不曾想，竟死在蛮夷刀下！",
}

local zuti = General:new(extension, "fengsui_heg__zuti", "jin", 4)
zuti:addSkills { "fengsui_heg__kangying", "fengsui_heg__jietu" }

Fk:loadTranslationTable{
  ["fengsui_heg__zuti"] = "祖逖",
  ["#fengsui_heg__zuti"] = "晋室擎天",
  ["designer:fengsui_heg__zuti"] = "公冶天纵",
  ["illustrator:fengsui_heg__zuti"] = "公冶天纵",
  ["cv:fengsui_heg__zuti"] = "暂无",
  ["fengsui_heg__kangying"] = "亢膺",
  [":fengsui_heg__kangying"] = "与你势力相同的其他角色造成伤害后，其可与你副将<a href='heg__yiwei'>易位</a> ，然后控制此武将的角色本回合攻击范围和下次造成的伤害+1。",
  ["#fengsui_heg__kangying-invoke"] = "亢膺：是否与 %dest 的副将易位，并令控制祖逖者获得增益？",
  ["fengsui_heg__jietu"] = "捷途",
  [":fengsui_heg__jietu"] = "阵法技，出牌阶段限一次，你可以重铸与你同一队列所有角色的各一张牌。与你同一队列的角色重铸牌后，若为装备牌，则其摸一张牌且本轮于出牌阶段内使用【杀】次数+1。",
  ["$fengsui_heg__kangying1"] = "中原父老，翘首以盼！我等若不北伐，何面目见天下苍生！",
  ["$fengsui_heg__kangying2"] = "家国之恨，百姓之苦，日夜煎熬我心！",
  ["$fengsui_heg__kangying3"] = "星星之火，可成燎原之势；百家部曲，亦能光复神州！",
  ["$fengsui_heg__kangying4"] = "胸中义气，已如烈火！不烧尽胡虏，绝不罢休！",
  ["$fengsui_heg__jietu1"] = "桓宣单骑入城，可抵十万之师！",
  ["$fengsui_heg__jietu2"] = "一鼓作气，乘胜追击！莫教胡虏有喘息之机！",
  ["$fengsui_heg__jietu3"] = "捷报频传，士气如虹！",
  ["$fengsui_heg__jietu4"] = "敌势已衰，其心已乱！此正是我军席卷中原，再造乾坤之时！",
  ["~fengsui_heg__zuti"] = "中流击楫，誓言犹在耳畔……奈何，大业未成……身先死……",
}

local hejiao = General:new(extension, "fengsui_heg__hejiao", "jin", 3)
hejiao:addSkills { "fengsui_heg__jiezhi", "fengsui_heg__qingsong" }

Fk:loadTranslationTable{
  ["fengsui_heg__hejiao"] = "和峤",
  ["#fengsui_heg__hejiao"] = "清廉守节",
  ["designer:fengsui_heg__hejiao"] = "公冶天纵",
  ["illustrator:fengsui_heg__hejiao"] = "公冶天纵",
  ["cv:fengsui_heg__hejiao"] = "暂无",
  ["fengsui_heg__jiezhi"] = "节枝",
  [":fengsui_heg__jiezhi"] = "当其他角色获得你的牌后，若本回合有与之类别不同的牌进入弃牌堆，你可以获得其中最后进入弃牌堆的一张。若这两张牌颜色：相同，其本回合无法使用牌指定你为目标；不同，你本回合使用牌无法指定其为目标。",
  ["#fengsui_heg__jiezhi-invoke"] = "节枝：是否获得最后进入弃牌堆的不同类别牌，并与 %dest 比较颜色？",
  ["fengsui_heg__qingsong"] = "青松",
  [":fengsui_heg__qingsong"] = "当你成为一张牌的目标后，若你的武将牌均明置，你可以暗置此武将牌并将一张类别不同的牌正面朝上交给一名其他角色，若其与你势力不同，你于本回合结束后视为使用此牌。",
  ["$fengsui_heg__jiezhi1"] = "元裒如北夏门，拉攞自欲坏，非一木所能支。",
  ["$fengsui_heg__jiezhi2"] = "君问此枝比李何如？",
  ["$fengsui_heg__jiezhi3"] = "礼不可废，身亦不可毁。",
  ["$fengsui_heg__jiezhi4"] = "去其繁枝，方能存其根本。",
  ["$fengsui_heg__qingsong1"] = "身如青松，根植于社稷，岂为宵小之辈所能撼动？",
  ["$fengsui_heg__qingsong2"] = "为臣者，当如松柏之性，岁寒时，方显其不凋之节。",
  ["$fengsui_heg__qingsong3"] = "枝节或可伤，松根不可移。",
  ["$fengsui_heg__qingsong4"] = "清浊异流，泾渭自明。",
  ["~fengsui_heg__hejiao"] = "松倾国殇……臣节……尽于此矣……",
}

local yangzhi = General:new(extension, "fengsui_heg__yangzhi", "jin", 3, 3, General.Female)
yangzhi:addCompanions("fengsui_heg__yangyan")
yangzhi:addCompanions("fengsui_heg__yangjun") 
yangzhi:addCompanions("jy_heg__yangjun")
yangzhi:addSkills { "fengsui_heg__yisang", "fengsui_heg__jiubo" }

Fk:loadTranslationTable{
  ["fengsui_heg__yangzhi"] = "杨芷",
  ["#fengsui_heg__yangzhi"] = "妍丽自治",
  ["designer:fengsui_heg__yangzhi"] = "公冶天纵",
  ["illustrator:fengsui_heg__yangzhi"] = "公冶天纵",
  ["cv:fengsui_heg__yangzhi"] = "暂无",
  ["fengsui_heg__yisang"] = "诒桑",
  [":fengsui_heg__yisang"] = "当一名同势力角色成为一张牌的目标后，若此牌与当前回合角色使用的上一张牌颜色相同，你可展示牌堆顶的牌并令其选择一项：获得此牌，或选择一张牌替换此牌。",
  ["#fengsui_heg__yisang-invoke"] = "诒桑：是否对 %dest 发动？",
  ["#fengsui_heg__yisang-choice"] = "诒桑：请选择一项",
  ["fengsui_heg__yisang_get"] = "获得此牌",
  ["fengsui_heg__yisang_replace"] = "选择一张牌替换此牌",
  ["#fengsui_heg__yisang-replace"] = "诒桑：请选择一张牌置于牌堆顶以替换",
  ["fengsui_heg__jiubo"] = "救帛",
  [":fengsui_heg__jiubo"] = "当一名同势力角色于回合内首次成为一张单体伤害牌的目标时，若你的武将牌均明置，你可以弃置一张非基本牌并暗置此武将牌取消此目标。若此牌为来源本回合使用的第一张牌，你代替其成为此牌目标。",
  ["#fengsui_heg__jiubo-invoke"] = "救帛：是否保护 %dest ？",
  ["$fengsui_heg__yisang1"] = "今日躬桑于西郊，请为大王衣。",
  ["$fengsui_heg__yisang2"] = "清风胧月香怡，请君暂驻小憩。",
  ["$fengsui_heg__jiubo1"] = "陛下任人不明，所托绝非良人。",
  ["$fengsui_heg__jiubo2"] = "吾与太傅同气连枝，一损则俱损。",
  ["~fengsui_heg__yangzhi"] = "姊妹继宠，福极灾生。。",
}

local yangyan = General:new(extension, "fengsui_heg__yangyan", "jin", 3, 3, General.Female)
yangyan:addCompanions("fengsui_heg__yangzhi")
yangyan:addSkills { "fengsui_heg__xianwan", "fengsui_heg__jiyuan" }

Fk:loadTranslationTable{
  ["fengsui_heg__yangyan"] = "杨艳",
  ["#fengsui_heg__yangyan"] = "雍容天下",
  ["designer:fengsui_heg__yangyan"] = "公冶天纵",
  ["illustrator:fengsui_heg__yangyan"] = "公冶天纵",
  ["cv:fengsui_heg__yangyan"] = "暂无",
  ["fengsui_heg__xianwan"] = "娴婉",
  [":fengsui_heg__xianwan"] = "当你需要使用【杀】或【闪】时，若你的武将牌均明置，你可以暗置此武将牌视为使用之。",
  ["#fengsui_heg__xianwan-slash"] = "娴婉：你可以暗置此武将牌，视为使用【杀】",
  ["#fengsui_heg__xianwan-jink"] = "娴婉：你可以暗置此武将牌，视为使用【闪】",
  ["fengsui_heg__jiyuan"] = "霁愿",
  [":fengsui_heg__jiyuan"] = "限定技，当你进入濒死状态时，你可以选择一名与你势力相同的角色，其将体力值和手牌数调整至上限，并暗置变更副将。然后若你未死亡，你移除此武将牌。",
  ["#fengsui_heg__jiyuan-choose"] = "霁愿：选择一名同势力角色",
  ["#fengsui_heg__jiyuan-discard"] = "霁愿：请弃置 %arg 张手牌，将手牌数调整至体力上限",
  ["$fengsui_heg__xianwan1"] = "姿容娴婉，服饰华光。",
  ["$fengsui_heg__xianwan2"] = "有美一人，清扬婉兮。",
  ["$fengsui_heg__jiyuan1"] = "男胤有德色，愿陛下以备六宫。",
  ["$fengsui_heg__jiyuan2"] = "广集良家，召充选者使吾拣择。",
  ["~fengsui_heg__yangyan"] = "后承前训，奉述遗芳。",
}


local jiananfeng = General:new(extension, "fengsui_heg__jiananfeng", "jin", 3, 3, General.Female)
jiananfeng:addCompanions("zq_heg__jiachong")
jiananfeng:addSkills { "fengsui_heg__xugu", "fengsui_heg__xionglie" }

Fk:loadTranslationTable{
  ["fengsui_heg__jiananfeng"] = "贾南风",
  ["#fengsui_heg__jiananfeng"] = "凤啸峻峕",
  ["designer:fengsui_heg__jiananfeng"] = "公冶天纵",
  ["illustrator:fengsui_heg__jiananfeng"] = "小罗没想好",
  ["cv:fengsui_heg__jiananfeng"] = "暂无",
  ["fengsui_heg__xugu"] = "虚淈",
  [":fengsui_heg__xugu"] = "出牌阶段限一次，你可以选择一个军令并令任意名势力不同的角色同时选择一项：1.展示一张手牌并暗置所有武将牌；2.执行该军令；若选择1的角色不大于/大于选择2的角色，你使用一张展示牌（不计入次数）/选择2的角色依次对距离最近选择1的角色造成一点伤害。",
  ["xugu_show_hide"] = "展示一张手牌并暗置所有武将牌",
  ["xugu_do_command"] = "执行该军令",
  ["#fengsui_heg__xugu-choice"] = "虚淈：请选择一项",
  ["#fengsui_heg__xugu"] = "虚淈：选择参与的角色",
  ["#fengsui_heg__xugu-show"] = "虚淈：请选择要展示的手牌",
  ["#fengsui_heg__xugu-use"] = "虚淈：请使用一张仍在手牌区的展示牌",
  ["#fengsui_heg__xugu-damage"] = "虚淈：选择一名距离最近的角色造成1点伤害",
  ["fengsui_heg__xionglie"] = "凶烈",
  [":fengsui_heg__xionglie"] = "锁定技，当你每轮首次使用牌指定其他角色时，若其有暗置武将牌，此牌无法被响应；当你每轮首次即将造成伤害时，若其为女性角色，此伤害+1。",
  ["$fengsui_heg__xionglie1"] = "不论汝用何法，本后只要死的。",
  ["$fengsui_heg__xionglie2"] = "好个贱婢，看来留不得你。",
  ["$fengsui_heg__xugu1"] = "诏命皆从我出，诸君当知谁为这一国之主。",
  ["$fengsui_heg__xugu2"] = "尔等罪证，可俱在本宫手中。",
  ["~fengsui_heg__jiananfeng"] = "只恨未早下杀手，致有今日险境。",
}
local xuwen = General:new(extension, "fengsui_heg__xuwen", "jin", 3, 3, General.Female)
xuwen:addCompanions("zq_heg__wangjun")
xuwen:addSkills { "fengsui_heg__fuhui", "fengsui_heg__mohua" }

Fk:loadTranslationTable{
  ["fengsui_heg__xuwen"] = "徐妏",
  ["#fengsui_heg__xuwen"] = "丹青入墨",
  ["designer:fengsui_heg__xuwen"] = "公冶天纵",
  ["illustrator:fengsui_heg__xuwen"] = "公冶天纵",
  ["cv:fengsui_heg__xuwen"] = "暂无",
  ["fengsui_heg__fuhui"] = "赋绘",
  [":fengsui_heg__fuhui"] = "若你的武将牌均明置，你可暗置此武将牌并将两张牌当作任意一张牌名字数等于转化牌点数差值的基本牌或普通锦囊牌使用或打出。",
  ["#fengsui_heg__fuhui-invoke"] = "赋绘：是否发动？",
  ["#fengsui_heg__fuhui-name"] = "赋绘：请选择一张牌名字数为 %arg 的基本牌或普通锦囊牌",
  ["fengsui_heg__mohua"] = "摹画",
  [":fengsui_heg__mohua"] = "同势力角色的回合结束时，你可以使用一张其于本回合使用过的牌名的牌。",
  ["#fengsui_heg__mohua-choice"] = "摹画：请选择一张 %dest 本回合使用过的牌名",
  ["$fengsui_heg__fuhui1"] = "画入我眸寻兰黛，千度回首，唯有香如故。",
  ["$fengsui_heg__fuhui2"] = "我入画中访青笺，一笔流年，繁花犹香艳。",
  ["$fengsui_heg__mohua1"] = "画中月照百世人，画外人识百花香。",
  ["$fengsui_heg__mohua2"] = "三分墨染七分意，层峦似有清泉来。",
  ["~fengsui_heg__xuwen"] = "丹青从不败，白头总佳人。",
}

local jiawu = General:new(extension, "fengsui_heg__jiawu", "jin", 3, 3, General.Female)
jiawu:addCompanions("zq_heg__guohuaij", "fengsui_heg__hanshou")
jiawu:addSkills { "fengsui_heg__huaixiang", "fengsui_heg__liusu" }

Fk:loadTranslationTable{
  ["fengsui_heg__jiawu"] = "贾午",
  ["#fengsui_heg__jiawu"] = "情梦归尘",
  ["designer:fengsui_heg__jiawu"] = "公冶天纵",
  ["illustrator:fengsui_heg__jiawu"] = "公冶天纵",
  ["cv:fengsui_heg__jiawu"] = "暂无",
  ["fengsui_heg__huaixiang"] = "怀香",
  [":fengsui_heg__huaixiang"] = "出牌阶段，你可以重铸一张本回合未进入弃牌堆类别的牌并选择一名确定势力的角色，其本回合视为未确定势力。",
  ["#fengsui_heg__huaixiang"] = "怀香：弃置一张本回合未进入弃牌堆类别的牌，令一名角色本回合视为未确定势力",
  ["fengsui_heg__liusu"] = "流愫",
  [":fengsui_heg__liusu"] = "出牌阶段限一次，你可以弃置一张牌并获得弃牌堆第一张与此牌合法目标数相同的非同名基本牌或普通锦囊牌。若其合法目标中包含任意名未确定势力角色，回合结束后你可以令等量名角色将手牌摸至体力上限。",
  ["#fengsui_heg__liusu"] = "流愫：弃置一张牌并从弃牌堆中检索一张合法目标数相同的其他牌",
  ["#fengsui_heg__liusu-choose"] = "流愫：请选择一张弃牌堆中的牌使用",
  ["#fengsui_heg__liusu-fill"] = "流愫：选择至多 %arg 名角色将手牌摸至体力上限",
  ["$fengsui_heg__huaixiang1"] = "此乃西域奇香，特为君留，望君珍重。",
  ["$fengsui_heg__huaixiang2"] = "窃此御赐之物，只为赠予意中人。",
  ["$fengsui_heg__huaixiang3"] = "香为信，君可解我意？",
  ["$fengsui_heg__huaixiang4"] = "愿此香，如我常伴君侧，须臾不离。",
  ["$fengsui_heg__liusu1"] = "夜已深，不知韩郎……今宵来否？",
  ["$fengsui_heg__liusu2"] = "情之所至，岂是礼法能拘？我意已决！",
  ["$fengsui_heg__liusu3"] = "一念起，万水千山；一念定，不计后果。",
  ["$fengsui_heg__liusu4"] = "世间情爱，本就无迹可寻，亦无墙可挡。",
  ["~fengsui_heg__jiawu"] = "此生得一知己...纵使情深不寿...亦无悔也......",
}

local hanshou = General(extension, "fengsui_heg__hanshou", "jin", 3)
hanshou:addCompanions("fengsui_heg__jiawu")
hanshou:addSkills { "fengsui_heg__yuyuan", "fengsui_heg__ruxiang" }

Fk:loadTranslationTable{
  ["fengsui_heg__hanshou"] = "韩寿",
  ["#fengsui_heg__hanshou"] = "窃香郎",
  ["designer:fengsui_heg__hanshou"] = "公冶天纵",
  ["illustrator:fengsui_heg__hanshou"] = "公冶天纵",
  ["cv:fengsui_heg__hanshou"] = "暂无",
  ["fengsui_heg__yuyuan"] = "逾垣",
  [":fengsui_heg__yuyuan"] = "你于每回合使用的首张单体基本牌或普通锦囊牌可以额外指定任意名未确定势力角色为目标，若其中没有角色受到伤害且你的武将牌均明置，你暗置此武将牌。",
  ["#fengsui_heg__yuyuan-extra"] = "逾垣：额外指定未确定势力角色为目标",
  ["fengsui_heg__ruxiang"] = "擩香",
  [":fengsui_heg__ruxiang"] = "当你明置此武将牌时，你可以使用一张牌（不计入次数）；当你受到或造成伤害后，你可以重铸至多等同于此伤害值张牌。",
  ["#fengsui_heg__ruxiang-use"] = "擩香：你可以使用一张牌（不计入次数）",
  ["#fengsui_heg__ruxiang-recast"] = "擩香：你可以重铸至多%arg张牌",
  ["$fengsui_heg__yuyuan1"] = "高墙虽险，难阻此心向卿。",
  ["$fengsui_heg__yuyuan2"] = "嘘……莫要惊动了巡夜之人。",
  ["$fengsui_heg__yuyuan3"] = "贾公面前，还需……多加收敛。",
  ["$fengsui_heg__yuyuan4"] = "墙内有佳人，区区垣墙，何足道哉？",
  ["$fengsui_heg__ruxiang1"] = "香虽怡人，然身已入局，此事……恐难隐瞒。",
  ["$fengsui_heg__ruxiang2"] = "金玉有价，此香无量；赠我以香，亦赠我以险。",
  ["$fengsui_heg__ruxiang3"] = "欲洗此香，却已入骨，情之一字，避无可避。",
  ["$fengsui_heg__ruxiang4"] = "有此香在身，虽处庙堂，亦如与卿同席。",
  ["~fengsui_heg__hanshou"] = "香消...玉殒...此情...来生再续.....",
}

local kuaishi = General:new(extension, "fengsui_heg__kuaishi", "jin", 3, 3, General.Female)
kuaishi:addCompanions("jy_heg__sunxiuj")
kuaishi:addSkills { "fengsui_heg__hejue", "fengsui_heg__hexi" }

Fk:loadTranslationTable{
  ["fengsui_heg__kuaishi"] = "蒯氏",
  ["#fengsui_heg__kuaishi"] = "一貉之丘",
  ["designer:fengsui_heg__kuaishi"] = "公冶天纵",
  ["illustrator:fengsui_heg__kuaishi"] = "公冶天纵",
  ["cv:fengsui_heg__kuaishi"] = "暂无",
  ["fengsui_heg__hejue"] = "合珏",
  [":fengsui_heg__hejue"] = "当你受到伤害后或结束阶段，你可以选择至多两张武将牌并选择一项：若为两张珠联璧合的武将牌，则其对应角色各摸一张牌；若对应角色数为1，你可以令其<a href='heg__hebi'>合璧</a>或变更副将然后移除此选项。",
  ["#fengsui_heg__hejue-invoke1"] = "合珏：是否发动？",
  ["#fengsui_heg__hejue-invoke2"] = "合珏：结束阶段是否发动？",
  ["#fengsui_heg__hejue-choose"] = "合珏：选择一张或两张武将牌对应的角色",
  ["#fengsui_heg__hejue-choice"] = "合珏：请选择一项",
  ["fengsui_heg__hejue_hebi"] = "令其合璧",
  ["fengsui_heg__hejue_transform"] = "令其变更副将",
  ["fengsui_heg__hexi"] = "貉隙",
  [":fengsui_heg__hexi"] = "当你于摸牌阶段外获得牌后，你可以将装备区的一张牌移动至一名有明置武将牌的其他角色的对应区域，然后你令其选择一项：1.暗置一张武将牌并对当前回合角色造成一点伤害；2.明置一张武将牌并摸两张牌。",
  ["#fengsui_heg__hexi-choose"] = "貉隙：选择一名其他角色",
  ["#fengsui_heg__hexi-move"] = "貉隙：移动你与其区域内的一张牌",
  ["#fengsui_heg__hexi-choice"] = "貉隙：请选择一项",
  ["fengsui_heg__hexi_hide_damage"] = "暗置一张武将牌并对当前回合角色造成1点伤害",
  ["fengsui_heg__hexi_reveal_draw"] = "明置一张武将牌并摸两张牌",
  ["$fengsui_heg__hexi1"] = "哼，不过一南来貉子罢了！",
  ["$fengsui_heg__hexi2"] = "名门之仪，岂容尔等蛮夫沾染！",
  ["$fengsui_heg__hexi3"] = "一言为界，你我殊途。",
  ["$fengsui_heg__hejue1"] = "经此一事，方知情重。",
  ["$fengsui_heg__hejue2"] = "夫君，昔日之言，休要再提。",
  ["$fengsui_heg__hejue3"] = "破镜重圆，完璧合一。",
  ["~fengsui_heg__kuaishi"] = "玉已碎，人已亡……勿复相思……",
}

local fengsui_heg__wangrong = General:new(extension, "fengsui_heg__wangrong", "jin", 3)
fengsui_heg__wangrong:addCompanions("fengsui_heg__shantao")
fengsui_heg__wangrong:addCompanions("fengsui_heg__hejiao")
fengsui_heg__wangrong:addSkill("fengsui_heg__fumiao")
fengsui_heg__wangrong:addSkill("fengsui_heg__ruwu")

Fk:loadTranslationTable{
  ["fengsui_heg__wangrong"] = "王戎",
  ["#fengsui_heg__wangrong"] = "离宦独自流",
  ["~fengsui_heg__wangrong"] = "浮沉人生几十载，竟在此处落幕......",
  ["designer:fengsui_heg__wangrong"] = "公冶天纵",
  ["illustrator:fengsui_heg__wangrong"] = "佚名",
  ["cv:fengsui_heg__wangrong"] = "暂无",
  ["fengsui_heg__fumiao"] = "浮邈",
  [":fengsui_heg__fumiao"] = "每回合限一次，当你需要使用一张本回合所有角色未使用过的基本牌时，若你的武将牌均明置，你可以与牌堆底的牌拼点，若你赢，你视为使用之；若你没赢，你暗置此武将牌并将一张拼点牌置于牌堆顶。",
  ["#fengsui_heg__fumiao-invoke"] = "浮邈：选择一种本回合未被使用过的基本牌",
  ["#fengsui_heg__fumiao-pindian"] = "浮邈：选择一张手牌与牌堆底的牌比较点数",
  ["#fengsui_heg__fumiao-top"] = "浮邈：选择一张拼点牌置于牌堆顶",
  ["fengsui_heg__ruwu"] = "如晤",
  [":fengsui_heg__ruwu"] = "副将技，锁定技，每当有角色获得或使用标记后，你摸一张牌；若为珠联璧合标记，你摸两张牌；若其势力与你不同，你弃置X张牌获得一枚阴阳鱼标记或变更副将。（X为场上拥有标记的角色数）",
  ["$fengsui_heg__fumiao1"] = "浮生若梦，梦中有山水，梦中有知音，梦中亦有宦争。",
  ["$fengsui_heg__fumiao2"] = "离宦独行数十年，到得暮年终方悟。",
    ["$fengsui_heg__fumiao3"] = "于竹林中悟得物外之趣，于遁世处探得天地之理。",
  ["$fengsui_heg__fumiao4"] = "吾已罢仕几余载，不必找我。",
  ["$fengsui_heg__ruwu1"] = "同道者虽有珠联之期，独行者终也找得如晤之人。",
  ["$fengsui_heg__ruwu2"] = "相知贵于相识，山涛、和峤皆为我一生所遇之知音。",
  ["$fengsui_heg__ruwu3"] = "吾于暮年与君结得至深之交，甚好、甚好！",
  ["$fengsui_heg__ruwu4"] = "岁月流转，得一二知音足矣；其余权名如烟消散也罢。",
}

local fengsui_heg__xiejiu = General:new(extension, "fengsui_heg__xiejiu", "jin", 3)
fengsui_heg__xiejiu.gender = General.Female
fengsui_heg__xiejiu:addSkill("fengsui_heg__yuchen")
fengsui_heg__xiejiu:addSkill("fengsui_heg__guitu")

Fk:loadTranslationTable{
  ["fengsui_heg__xiejiu"] = "谢玖",
  ["#fengsui_heg__xiejiu"] = "闺阁囹圄",
  ["~fengsui_heg__xiejiu"] = "贾南风！下世我不再入宫闱，也不再与你有瓜葛！",
  ["designer:fengsui_heg__xiejiu"] = "公冶天纵",
  ["illustrator:fengsui_heg__xiejiu"] = "佚名",
  ["cv:fengsui_heg__xiejiu"] = "暂无",
  ["fengsui_heg__yuchen"] = "毓尘",
  [":fengsui_heg__yuchen"] = "出牌阶段限一次，你可使用另一张武将牌与一名其他同势力角色的对应武将牌<a href='heg__yiwei'>易位</a>，若在两个新的组合中主副将体力值均相等/不等，你获得一枚珠联璧合/阴阳鱼标记。",
  ["fengsui_heg__guitu"] = "归土",
  [":fengsui_heg__guitu"] = "当你即将受到伤害时，若此伤害超过一点，你可以移除副将并防止此伤害，然后伤害来源本回合手牌上限为0。",
  ["#fengsui_heg__guitu-invoke"] = "归土：是否移除副将并防止此伤害，令伤害来源本回合手牌上限为0？",
  ["@fengsui_heg__guitu-turn"] = "归土",
  ["$fengsui_heg__yuchen1"] = "我看遍红尘，一生所履尽是此路。",
  ["$fengsui_heg__yuchen2"] = "屠家女蒙武帝选，命我教郎君承欢之事。",
    ["$fengsui_heg__yuchen3"] = "冷宫独抚吾儿，然恨意无尽连绵。",
  ["$fengsui_heg__yuchen4"] = "毓养之心犹在，母子之缘已断，唯梦中反复教之。",
  ["$fengsui_heg__guitu1"] = "屠家之身历尽苦楚，何惧多此一痛。",
  ["$fengsui_heg__guitu2"] = "失子之母，活已无意，如尘归土。",
  ["$fengsui_heg__guitu3"] = "贾南风之戟曾刺我腹，今日更甘代人受此刃。",
  ["$fengsui_heg__guitu4"] = "吾儿司马遹为贾氏所害，吾既已失挚爱，苟生不如摹树归根。",
}

Fk:loadTranslationTable{
  ["fengsui_heg"] = "烽燧燎原",
  ["fengsui"] = "烽燧燎原",
  ["heg__hebi"] = "合璧：变更副将的子集。玩家主将需有对应珠联璧合武将牌方可进行合璧；玩家选择合璧后将副将变更为主将对应的珠联璧合武将牌，然后获得一枚珠联璧合标记。每个技能每局限一次。<br>",
}

Fk:loadTranslationTable{
  ["#fengsui_heg__chenmeng"] = "谶梦：弃置一枚国战标记，用一张手牌替换牌堆顶的牌",
  ["#fengsui_heg__chenmeng-mark"] = "谶梦：请选择要弃置的国战标记",
  ["#fengsui_heg__chenmeng-exchange"] = "谶梦：请选择一张手牌置于牌堆顶，然后获得原牌堆顶的牌",
  ["#fengsui_heg__fenshuang-invoke"] = "纷霜：选择一名攻击范围内含有你的角色，令其对你造成1点伤害",
  ["#FenshuangTransfer"] = "受【%arg】影响，下一道作用于 %from 的军令改为由 %to 执行",
  ["#fengsui_heg__fudao-invoke"] = "覆倒：是否弃置所有手牌，令对 %dest 造成的伤害增加 %arg 点？",
  ["#fengsui_heg__juangu-invoke"] = "眷故：是否发动技能结算珠联璧合武将牌的效果？",
  ["#fengsui_heg__bizun-invoke"] = "避尊：选择一名失去某个区域最后一张牌的同势力角色，令其摸一张牌",
  ["#fengsui_heg__qingsong-give"] = "青松：请选择一张与当前牌类别不同的手牌",
  ["#fengsui_heg__qingsong-to"] = "青松：选择一名其他角色，将所选手牌正面朝上交给其",
  ["#fengsui_heg__qingsong-use"] = "青松：请使用此前交出的牌",
  ["#fengsui_heg__yingmian-ask"] = "盈面：选择一名角色并为其选择一道军令",
  ["#fengsui_heg__caixia-invoke"] = "才瑕：你可以摸同势力角色数张牌，然后暗置一张武将牌",
  ["#fengsui_heg__qiaoshi-invoke"] = "樵拾：你可以与 %dest 各摸一张牌",
  ["#fengsui_heg__qiaoshi-change"] = "樵拾：你可以令 %dest 合璧或变更副将",
  ["#fengsui_heg__duanjin-choose"] = "断衿：选择一名同势力角色与你易位，并各获得一枚珠联璧合标记",
  ["#fengsui_heg__ruwu-drop"] = "如晤：请弃置 %arg 张牌",
  ["#fengsui_heg__ruwu-choice"] = "如晤：请选择获得阴阳鱼标记或变更副将",
  ["fengsui_heg__ruwu_yinyang"] = "获得一枚阴阳鱼标记",
  ["fengsui_heg__ruwu_transform"] = "变更副将",
  ["#fengsui_heg__youming-invoke"] = "幽明：你可以暗置此武将牌，观看 %dest 的手牌并将其中一张置于牌堆顶",
  ["#fengsui_heg__youming-dying"] = "幽明：你可以暗置此武将牌，亮出牌堆顶与 %dest 的一张手牌",
  ["#fengsui_heg__youming-show"] = "幽明：请选择 %dest 的一张手牌亮出",
  ["#fengsui_heg__baizu-choose"] = "败族：请选择势力为【%dest】的一名角色",
  ["#fengsui_heg__baizu-discard"] = "败族：请弃置一张牌进行类别比对",
  ["#fengsui_heg__fenchai-active"] = "分钗：选择一名异性角色，你与其依次对彼此使用无距离限制的冰【杀】",
  ["#fengsui_heg__fenchai-change"] = "分钗：你可以令 %dest 合璧或变更副将",
  ["#fengsui_heg__fenchai-fish"] = "分钗：你可以令此冰【杀】的使用者与目标各获得一枚阴阳鱼标记",
  ["#fengsui_heg__xinmai-active"] = "薪脉：令一名角色获得本回合进入弃牌堆的所有【杀】",
  ["#fengsui_heg__xinmai-choice"] = "薪脉：请选择受到1点雷电伤害或暗置一张武将牌",
  ["fengsui_heg__xinmai_damage"] = "受到1点雷电伤害",
  ["fengsui_heg__xinmai_hide"] = "暗置一张武将牌",
}

return extension
