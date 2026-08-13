local extension = Package:new("fengsui_liwu")
extension.extensionName = "fengsui"
extension.game_modes_whitelist = { "new_heg_mode", "fengsui_heg__mode" }

extension:loadSkillSkelsByPath("./packages/fengsui/pkg/fengsui_liwu/skills")
assert(#extension.skill_skels == 24, "fengsui_liwu must load exactly 24 official skill skeletons")

local zhouxuan = General:new(extension, "fengsui_heg__zhouxuan", "wei", 3)
zhouxuan:addSkills { "fengsui_heg__wumei", "fengsui_heg__jiemeng" }

Fk:loadTranslationTable{
  ["fengsui_heg__zhouxuan"] = "周宣",
  ["#fengsui_heg__zhouxuan"] = "醒踌者",
  ["designer:fengsui_heg__zhouxuan"] = "公冶长风",
  ["illustrator:fengsui_heg__zhouxuan"] = "公冶长风",
  ["cv:fengsui_heg__zhouxuan"] = "暂无",
  ["fengsui_heg__wumei"] = "寤寐",
  [":fengsui_heg__wumei"] = "当你明置或暗置此武将牌时，你摸两张牌且可以视为使用一张<a href=':tricky_heist'>【巧取豪夺】</a>，然后若你因此获得奇珍牌，你本回合使用牌无次数限制。",
  ["#fengsui_heg__wumei"] = "寤寐：你可以视为使用【巧取豪夺】",
  ["fengsui_heg__jiemeng"] = "解梦",
  [":fengsui_heg__jiemeng"] = "当你受到伤害后，你可以视为对一名确定势力的角色使用一张<a href=':overbearing'>【咄咄逼人】</a>，若其因此受到伤害且你武将牌均明置，你暗置此武将牌。",
  ["#fengsui_heg__jiemeng"] = "解梦：你可以视为对一名确定势力的角色使用【咄咄逼人】",
    ["$fengsui_heg__wumei1"] = "大梦落雪三千丈，可将暮鸿筑玉京。",
      ["$fengsui_heg__wumei2"] = "雪者水之形也，冰者雪之骨也，其态左而其质右。",
  ["$fengsui_heg__wumei3"] = "梦中所见，皆是心中未平之事。",
  ["$fengsui_heg__wumei4"] = "一枕黄粱未醒，且看风雪换人间。",
          ["$fengsui_heg__jiemeng1"] = "暮雪纷飞，寒气盈野，煨红泥火炉，饮新醅绿蚁。",
      ["$fengsui_heg__jiemeng2"] = "骚客履薄冰，不知梦外落雪、梦中霜寒。",
  ["$fengsui_heg__jiemeng3"] = "梦可解，局难解，唯以此身试之。",
  ["$fengsui_heg__jiemeng4"] = "若问吉凶，且看今夜谁先惊醒。",
  ["~fengsui_heg__zhouxuan"] = "雪漫青山处，不见夜归人。",
}

local chenshou = General:new(extension, "fengsui_heg__chenshou", "shu", 3)
chenshou:addCompanions("fengsui_heg__qiaozhou", "fengsui_heg__limi")
chenshou:addSkills { "fengsui_heg__dianmo", "fengsui_heg__fuzai" }

Fk:loadTranslationTable{
  ["fengsui_heg__chenshou"] = "陈寿",
  ["#fengsui_heg__chenshou"] = "犁山者",
  ["designer:fengsui_heg__chenshou"] = "公冶长风",
  ["illustrator:fengsui_heg__chenshou"] = "公冶长风",
  ["cv:fengsui_heg__chenshou"] = "暂无",
  ["fengsui_heg__dianmo"] = "点墨",
  [":fengsui_heg__dianmo"] = "你可以将一张红色/黑色装备牌当【无懈可击】/<a href=':rob__jink'>【掠闪】</a>使用；当你使用奇珍牌后，你可以与一名装备区牌数量小于你的角色交换装备区的所有牌。",
  ["#fengsui_heg__dianmo-use"] = "点墨：你可以将一张装备牌当【无懈可击】或【掠闪】使用",
  ["#fengsui_heg__dianmo-swap"] = "点墨：你可以与一名装备区牌数较少的角色交换装备区的所有牌",
  ["fengsui_heg__fuzai"] = "覆载",
  ["fengsui_heg__fuzaiRemake"] = "覆载·改",
  [":fengsui_heg__fuzai"] = "锁定技，若你未装备宝物，你视为装备<a href=':nine_tripod_cauldrons'>【九州鼎】</a>。当其他角色装备<a href=':nine_tripod_cauldrons'>【九州鼎】</a>后，你需弃置装备区所有牌并变更副将。",
  [":fengsui_heg__fuzaiRemake"] = "锁定技，若你未装备宝物，你视为装备<a href=':nine_tripod_cauldrons'>【九州鼎】</a>。当其他角色装备<a href=':nine_tripod_cauldrons'>【九州鼎】</a>后，你需选择一项：1.弃置装备区所有牌并变更副将；2.视为使用一张<a href=':part_ways'>【分道扬镳】</a>。",
  ["fengsui_heg__fuzai_discard"] = "弃置装备区所有牌并变更副将",
  ["fengsui_heg__fuzai_partways"] = "视为使用【分道扬镳】",
  ["$fengsui_heg__dianmo1"] = "秉笔直书，善恶自有后世评说。",
  ["$fengsui_heg__dianmo2"] = "一字落简，便存兴亡之实。",
  ["$fengsui_heg__dianmo3"] = "史家之墨，不为尊者讳。",
  ["$fengsui_heg__dianmo4"] = "旧闻互异，当参校而定其真。",
  ["$fengsui_heg__fuzai1"] = "九州之重，当载于信史之中。",
  ["$fengsui_heg__fuzai2"] = "国有兴替，典册不可随之湮没。",
  ["$fengsui_heg__fuzai3"] = "承前人之遗事，启后世之明鉴。",
  ["$fengsui_heg__fuzai4"] = "覆载万象，方成一家之言。",
  ["~fengsui_heg__chenshou"] = "著述未竟，唯愿后人续之……",
}

local sunyuan = General:new(extension, "fengsui_heg__sunyuan", "wu", 4, 4, General.Female)
sunyuan:addCompanions("fengsui_heg__heji")
sunyuan:addSkills { "fengsui_heg__dongxin" }

Fk:loadTranslationTable{
  ["fengsui_heg__sunyuan"] = "孙鸢",
  ["#fengsui_heg__sunyuan"] = "履尘者",
  ["designer:fengsui_heg__sunyuan"] = "公冶长风",
  ["illustrator:fengsui_heg__sunyuan"] = "公冶长风",
  ["cv:fengsui_heg__sunyuan"] = "暂无",
  ["fengsui_heg__dongxin"] = "恫心",
  [":fengsui_heg__dongxin"] = "当你受到或造成伤害后，你可以视为对伤害来源或目标使用一张<a href=':reveal_intention'>【图穷匕见】</a>并与其各摸一张牌，然后你可重铸至多等同于此次伤害值张牌并使用其中的【杀】（不计入次数）。",
  ["#fengsui_heg__dongxin-discard"] = "恫心：你可以重铸至多等同于此次伤害值张牌，并依次使用其中的【杀】",
  ["#fengsui_heg__dongxin-use"] = "恫心：你可以使用弃牌堆中的此【杀】",
    ["$fengsui_heg__dongxin1"] = "三军胆裂非因剑，一念慑魂自威仪！",
  ["$fengsui_heg__dongxin2"] = "战鼓未擂心先乱，何不卸甲拜红妆？",
  ["$fengsui_heg__dongxin3"] = "心胆俱寒，便是千军也自溃。",
  ["$fengsui_heg__dongxin4"] = "恫心夺志，破阵只在一念之间。",
  ["~fengsui_heg__sunyuan"] = "此月曾照闺中……",
}

local liuhui = General:new(extension, "fengsui_heg__liuhui", "qun", 4)
liuhui:addSkills { "fengsui_heg__jieshu" }

Fk:loadTranslationTable{
  ["fengsui_heg__liuhui"] = "刘徽",
  ["#fengsui_heg__liuhui"] = "精算者",
  ["designer:fengsui_heg__liuhui"] = "公冶长风",
  ["illustrator:fengsui_heg__liuhui"] = "公冶长风",
  ["cv:fengsui_heg__liuhui"] = "暂无",
  ["fengsui_heg__jieshu"] = "解术",
  [":fengsui_heg__jieshu"] = "当你于回合内使用牌指定目标后，你可视为使用一张与原牌合法目标相同的普通锦囊牌，然后此技能失效直至你使用奇珍牌或一张与此牌合法目标相同的实体牌。",
  ["#fengsui_heg__jieshu"] = "解术：你可以使用一张与原牌合法目标相同的普通锦囊牌",
  ["@fengsui_heg__jieshu"] = "解术失效",
      ["$fengsui_heg__jieshu1"] = "累乘除以成九数者，可以加减解之。",
    ["$fengsui_heg__jieshu2"] = "数有其理，见筹一可知沙数。",
  ["$fengsui_heg__jieshu3"] = "万法虽繁，皆可归于一算。",
  ["$fengsui_heg__jieshu4"] = "以术破术，方知变化无穷。",
  ["~fengsui_heg__liuhui"] = "算学如海，穷我一生，只得杯水。",
}

local wanghuifeng = General:new(extension, "fengsui_heg__wanghuifeng", "jin", 4, 4, General.Female)
wanghuifeng:addSkills { "fengsui_heg__dilie" }

Fk:loadTranslationTable{
  ["fengsui_heg__wanghuifeng"] = "王惠风",
  ["#fengsui_heg__wanghuifeng"] = "戮时者",
  ["designer:fengsui_heg__wanghuifeng"] = "公冶长风",
  ["illustrator:fengsui_heg__wanghuifeng"] = "公冶长风",
  ["cv:fengsui_heg__wanghuifeng"] = "暂无",
  ["fengsui_heg__dilie"] = "砥烈",
  [":fengsui_heg__dilie"] = "当你造成伤害后，你可以重铸任意张非基本牌；当你受到伤害后，若你的武器栏没有牌，你可以随机将弃牌堆中的一张奇珍牌或伤害来源装备区的一张牌置入你的对应装备栏，若此牌为武器牌，你可以对伤害来源造成1点伤害。",
  ["#fengsui_heg__dilie-recast"] = "砥烈：你可以重铸任意张非基本牌",
  ["#fengsui_heg__dilie-choice"] = "砥烈：选择随机置入对应装备栏的牌的来源",
  ["fengsui_heg__dilie_curio"] = "弃牌堆中的奇珍牌",
  ["fengsui_heg__dilie_source_equip"] = "伤害来源装备区的牌",
  ["#fengsui_heg__dilie-damage"] = "砥烈：是否对 %dest 造成1点伤害？",
  ["$fengsui_heg__dilie1"] = "烈节在心，岂因危迫而改！",
  ["$fengsui_heg__dilie2"] = "宁折此身，不坠家门清望。",
  ["$fengsui_heg__dilie3"] = "刀兵虽厉，难夺我守志之心。",
  ["$fengsui_heg__dilie4"] = "我皇太子妇，司徒公之女，胡羌小丑，敢欲干我乎？",
  ["~fengsui_heg__wanghuifeng"] = "宗族倾覆，妾亦不独生……",
}

Fk:appendKingdomMap("fengsui_neutral", { "wei", "shu", "wu", "qun", "jin" })
Fk:appendKingdomMap("fengsui_neutralall", { "wei", "shu", "wu", "qun", "jin" })
require("packages.fengsui.pkg.fengsui_liwu.liwu_neutral_compat").install()

local jiaxu = General:new(extension, "fengsui_heg__jiaxu", "fengsui_neutralall", 3)
jiaxu:addCompanions("hs__jiaxu")
jiaxu:addSkill("fengsui_heg__qingshi_jx")
jiaxu:addSkill("fengsui_heg__anshi")
jiaxu:addSkill("fengsui_heg__shuge")

local lusu = General:new(extension, "fengsui_heg__lusu", "fengsui_neutralall", 3)
lusu:addCompanions("hs__lusu")
lusu:addSkill("fengsui_heg__xiangkui")
lusu:addSkill("fengsui_heg__yangming")

local xushu = General:new(extension, "fengsui_heg__xushu", "fengsui_neutralall", 4)
xushu.mainMaxHpAdjustedValue = -1
xushu:addCompanions("ld__xushu")
xushu:addSkill("fengsui_heg__jiange")
xushu:addSkill("fengsui_heg__xiawang")
xushu:addSkill("fengsui_heg__yinyu")

local zhaoe = General:new(extension, "fengsui_heg__zhaoe", "fengsui_neutralall", 3)
zhaoe.gender = General.Female
zhaoe:addSkill("fengsui_heg__yanshi")
zhaoe:addSkill("fengsui_heg__xinren")

local xushao = General:new(extension, "fengsui_heg__xushao", "fengsui_neutralall", 3)
xushao:addCompanions("fengsui_heg__xujing")
xushao:addSkill("fengsui_heg__yingmen")
xushao:addSkill("fengsui_heg__pingjian")

Fk:loadTranslationTable{
  ["fengsui_neutral"] = "中立",
  ["fengsui_neutralall"] = "中立者",
  ["heg__zhongliji"] = "中立技：确定势力后失去的技能。<br>",
  ["fengsui_neutral_desc"] = "中立：单独亮明时不显示势力，暂时不能亮明另一张武将牌；受到伤害或下一轮开始后解除限制，亮明另一张武将牌后确定势力。不可与野心家或另一名中立组合。<br>",
  ["fengsui_neutralall_desc"] = "中立者：可与任意正常势力武将牌组合；组合后势力随搭档和选将阶段确定。不可与野心家或另一名中立者组合。<br>",

  ["fengsui_heg__jiaxu"] = "贾诩",
  ["#fengsui_heg__jiaxu"] = "踱步逆世",
  ["~fengsui_heg__jiaxu"] = "肃侯已老，此生谋断，至此皆休……",
  ["designer:fengsui_heg__jiaxu"] = "公冶天纵",
  ["illustrator:fengsui_heg__jiaxu"] = "佚名",
  ["cv:fengsui_heg__jiaxu"] = "暂无",
  ["fengsui_heg__qingshi_jx"] = "清饰",
  [":fengsui_heg__qingshi_jx"] = "每轮限一次，当你成为其他角色黑色锦囊牌或【杀】的目标后，你可弃置一张手牌令此牌对你无效。若你弃置的为黑色牌，你摸一张牌。",
  ["fengsui_heg__anshi"] = "谙世",
  [":fengsui_heg__anshi"] = "出牌阶段限一次，你可以视为使用一张<a href=':known_both'>【知己知彼】</a>。若你选择观看一名未确定势力角色的武将牌后，其势力与你一致，其可选择明置一张武将牌，然后你令其于本回合结束后获得一个额外的回合，否则你令目标将手牌调整至手牌上限。",
  ["fengsui_heg__shuge"] = "束阁",
  [":fengsui_heg__shuge"] = "每局限X次，当你受到伤害后，你可以将一张伤害牌正面朝上交给一名伤害来源外的角色并令其与伤害来源拼点，赢者对败者使用此牌。若拼点中有角色使用你展示的牌拼点，则其受到1点无来源的雷电伤害（X为与你势力相同的角色数）。",
  ["@fengsui_heg__shugeRemake"] = "束阁",
  ["$fengsui_heg__qingshi_jx1"] = "姑臧贾文和，少时唯阎忠识我。",
  ["$fengsui_heg__qingshi_jx2"] = "良、平之奇，何必急显于人前？",
  ["$fengsui_heg__qingshi_jx3"] = "阖门自守，退无私交，可免猜嫌。",
  ["$fengsui_heg__qingshi_jx4"] = "我很同情你的努力，可惜这招对我一点用也没有。",
  ["$fengsui_heg__anshi1"] = "奉国家以征天下，进可成功，退亦未晚。",
  ["$fengsui_heg__anshi2"] = "李傕、郭汜若散，匹夫也；不如返攻长安。",
  ["$fengsui_heg__anshi3"] = "袁本初不能容兄弟，安能容天下国士？",
  ["$fengsui_heg__anshi4"] = "曹公奉天子以令天下，张将军当归之。",
  ["$fengsui_heg__shuge1"] = "袁强曹弱，舍袁从曹，正所以明德。",
  ["$fengsui_heg__shuge2"] = "宛城胜负已定，尚可再借一局。",
  ["$fengsui_heg__shuge3"] = "哼，吾且束之高阁，你们孰生孰死，有好戏看喽。",
  ["$fengsui_heg__shuge4"] = "此策入阁，成败便由二君自决。",


  ["fengsui_heg__lusu"] = "鲁肃",
  ["#fengsui_heg__lusu"] = "善施者",
  ["~fengsui_heg__lusu"] = "江流九曲，终归沧海。",
  ["designer:fengsui_heg__lusu"] = "公冶天纵",
  ["illustrator:fengsui_heg__lusu"] = "佚名",
  ["cv:fengsui_heg__lusu"] = "暂无",
  ["fengsui_heg__xiangkui"] = "飨馈",
  [":fengsui_heg__xiangkui"] = "其他同势力角色的回合开始时，其可指定一种类型，然后你可正面朝上交给其至多同势力角色数张与此类别不同的牌并摸等量张牌。",
  ["fengsui_heg__yangming"] = "扬名",
  [":fengsui_heg__yangming"] = "同势力角色的回合结束时，你可以摸X张牌，若X不小于场上势力数，你需展示所有手牌并依次选择X张牌和X名势力不同的其他角色，这些角色依次获得一张你选择的牌（X为你本回合因使用或弃置而进入弃牌堆的牌的类别数）。",
  ["$fengsui_heg__yangming1"] = "曹强则刘弱，刘弱则吴危，一州之地可购十年太平。",
  ["$fengsui_heg__yangming2"] = "舟中之人不可尽为敌国，吾何惜千万钱以买邻？",
  ["fengsui_heg__yangmingRemake"] = "扬名·旧",
  [":fengsui_heg__yangmingRemake"] = "<a href='heg__zhongliji'>中立技</a>，每个回合结束时，你可以摸X张牌，若X不小于场上势力数，你需展示所有手牌并依次选择X张牌和X名势力不同的其他角色，这些角色依次获得一张你选择的牌。（X为你本回合使用的牌的类别数）",
  ["fengsui_heg__suoli"] = "索立",
  [":fengsui_heg__suoli"] = "中立者确定势力后失去的技能。",
  ["$fengsui_heg__xiangkui1"] = "虎卧高岗，鹿守危崖，天下风云非人力不可造。",
  ["$fengsui_heg__xiangkui2"] = "受命得昌，天势也，跨有荆扬，地势也，待时而动，时势也。",
  ["$fengsui_heg__yangmingRemake1"] = "汉室倾危，江东当鼎足而立。",
  ["$fengsui_heg__yangmingRemake2"] = "先据江东，再剿黄祖，而后进伐刘表。",

  ["fengsui_heg__xushu"] = "徐庶",
  ["#fengsui_heg__xushu"] = "奇侠",
  ["~fengsui_heg__xushu"] = "卧龙已仕，天下已定，吾终得任侠天地。",
  ["designer:fengsui_heg__xushu"] = "公冶天纵",
  ["illustrator:fengsui_heg__xushu"] = "佚名",
  ["cv:fengsui_heg__xushu"] = "暂无",
  ["fengsui_heg__jiange"] = "剑歌",
  [":fengsui_heg__jiange"] = "每回合限一次，你可以将一张锦囊牌或装备牌当作【杀】或【决斗】使用或打出，然后你摸一张牌。",
  ["fengsui_heg__xiawang"] = "侠望",
  [":fengsui_heg__xiawang"] = "每局限X次，当与你距离不大于1的角色受到伤害后，若伤害来源不为你，你可对伤害来源使用一张可用的伤害牌（无距离限制，X为与你势力相同的角色数）。",
  ["@fengsui_heg__xiawangRemake"] = "侠望",
  ["fengsui_heg__yinyu"] = "隐誉",
  [":fengsui_heg__yinyu"] = "主将技，锁定技，你计算体力上限时减少1个单独的阴阳鱼。当你确定势力后，若你为群或蜀势力，你获得“诛恶”或“辅主”；若你的副将为徐庶（蜀），你移除此武将牌，并令另一张武将牌变为主将，其获得该武将牌上的技能并将“荐才”变为主将技。",
  ["fengsui_heg__zhue"] = "诛恶",
  [":fengsui_heg__zhue"] = "群势力技，每轮限一次，当一名同势力角色使用非装备牌时，你可令其摸一张牌且此牌不能被响应。",
  ["fengsui_heg__fuzhu_xs"] = "辅主",
  [":fengsui_heg__fuzhu_xs"] = "蜀势力技，每轮各限一次，当一名同势力角色使用非转化牌或转化牌结算结束后，你可以将一张牌置于牌堆顶或底，然后展示牌堆底或顶的三张牌并获得其中一种类别的牌，并将其余的牌以任意顺序置于原位。",

  ["$fengsui_heg__jiange1"] = "少好任侠击剑，曾为人报仇，为民除害！",
  ["$fengsui_heg__jiange2"] = "中州兵起，我与石韬南客荆州。",
  ["$fengsui_heg__jiange3"] = "新野一见，刘豫州果能器我。",
  ["$fengsui_heg__jiange4"] = "剑可决一人之难，谋可定一军之机。",
  ["$fengsui_heg__xiawang1"] = "白垩突面、被发而走，只为报人之仇。",
  ["$fengsui_heg__xiawang2"] = "大胆奸贼！吃我一剑！",
  ["$fengsui_heg__xiawang3"] = "君曾解我于市，今日吾必替天行道。",
  ["$fengsui_heg__xiawang4"] = "近者有难，元直岂可袖手？",
  ["$fengsui_heg__yinyu1"] = "诸葛孔明，卧龙也，将军岂愿见之？",
  ["$fengsui_heg__yinyu2"] = "此人可就见，不可屈致，宜枉驾顾之。",
  ["$fengsui_heg__yinyu3"] = "天下既定，我既退隐江湖，任侠四方。",
  ["$fengsui_heg__yinyu4"] = "贤才既荐，我之名便可隐去。",
  ["$fengsui_heg__zhue1"] = "明主得士，当使群邪不能间之。",
  ["$fengsui_heg__zhue2"] = "孔明既出隆中，谁敢阻其经略？",
  ["$fengsui_heg__zhue3"] = "同道相扶，方不负新野之遇。",
  ["$fengsui_heg__zhue4"] = "护贤诛恶，此剑尚有可用之处。",
  ["$fengsui_heg__fuzhu_xs1"] = "将军当亲往隆中，不可召孔明来见。",
  ["$fengsui_heg__fuzhu_xs2"] = "以元直之才，尚愿为卧龙先驱。",
  ["$fengsui_heg__fuzhu_xs3"] = "主有求贤之诚，臣自尽荐贤之责。",
  ["$fengsui_heg__fuzhu_xs4"] = "纵身离新野，所荐之才足辅汉业。",

  ["fengsui_heg__zhaoe"] = "赵娥",
  ["#fengsui_heg__zhaoe"] = "覆水之仇",
  ["~fengsui_heg__zhaoe"] = "父仇已报，我也了无心事......",
  ["designer:fengsui_heg__zhaoe"] = "公冶天纵",
  ["illustrator:fengsui_heg__zhaoe"] = "佚名",
  ["cv:fengsui_heg__zhaoe"] = "暂无",
  ["fengsui_heg__yanshi"] = "言誓",
  [":fengsui_heg__yanshi"] = "每回合各限一次：当你即将受到伤害时，若伤害来源体力值不小于你，你可以展示所有手牌并弃置一种伤害牌牌名的所有牌防止之；你可以将一张伤害牌置于牌堆顶，视为使用或打出一张与原牌合法目标数相同的普通锦囊牌或基本牌。",
  ["fengsui_heg__xinren"] = "衅刃",
  [":fengsui_heg__xinren"] = "锁定技，你的伤害类卡牌不计入手牌上限且无法使用；当你首次体力值变为1时，你移除此武将牌并弃置所有手牌，然后依次使用其中的黑色伤害牌。若此流程中没有角色死亡，你失去1点体力。",
  ["#fengsui_heg__xinren-use"] = "衅刃：请使用 %arg",
  ["$fengsui_heg__yanshi1"] = "父为人所杀，此仇十余年未敢忘。",
  ["$fengsui_heg__yanshi2"] = "兄弟俱亡，仇家以为无人能报么？",
  ["$fengsui_heg__yanshi3"] = "常帷车而候，今日终于都亭相遇。",
  ["$fengsui_heg__yanshi4"] = "父仇既报，我自诣县受法。",
  ["$fengsui_heg__xinren1"] = "潜备刀兵，只待仇踪一现。",
  ["$fengsui_heg__xinren2"] = "此刃藏逾十年，今日我必当将你饮恨黄泉，报我父亲血仇！",
  ["$fengsui_heg__xinren3"] = "尹君不必弃印，娥不肯苟生枉法。",
  ["$fengsui_heg__xinren4"] = "今天就是你的忌日，拿命来！",

  ["fengsui_heg__xushao"] = "许劭",
  ["#fengsui_heg__xushao"] = "评天鉴地",
  ["~fengsui_heg__xushao"] = "今小人道长，王室将乱。",
  ["designer:fengsui_heg__xushao"] = "公冶天纵",
  ["illustrator:fengsui_heg__xushao"] = "佚名",
  ["cv:fengsui_heg__xushao"] = "暂无",
  ["fengsui_heg__yingmen"] = "盈门",
  ["@[private]&fengsui_heg__fangke"] = "访客",
  [":fengsui_heg__yingmen"] = "锁定技，当你首次明置此武将牌后，你将X张势力不同的武将牌置于你的武将牌上，称为“访客”。回合开始时或你受到伤害后，若你的“访客”数少于X张，则你将“访客”补至X张（X为场上势力数）。",
  ["fengsui_heg__pingjian"] = "评鉴",
  ["#fengsui_heg__pingjian-remove"] = "评鉴：请选择结算后移去的访客",
  [":fengsui_heg__pingjian"] = "你可以发动“访客”武将牌上的一个非限定技、锁定技或阵法技的技能（合法发动时机且主副将技能需与你位置一致），然后你移去该“访客”并摸一张牌，若“访客”与你势力相同，你摸两张牌。",
  ["$fengsui_heg__yingmen1"] = "德高者，须以礼待之！",
  ["$fengsui_heg__yingmen2"] = "吾好核论乡党，长于明析臧否。",
  ["$fengsui_heg__pingjian1"] = "君清平之奸贼，乱世之英雄。",
  ["$fengsui_heg__pingjian2"] = "议于草野间，评荐俊才多。",

  ["@fengsui_neutral"] = "中立",
  ["@fengsui_neutralall"] = "中立者",
  ["anshi_reveal_main"] = "明置主将",
  ["anshi_reveal_deputy"] = "明置副将",
  ["#fengsui_heg__xiangkui-invoke"] = "飨馈：是否请求 %dest 交给你任意张手牌？",
  ["#fengsui_heg__xiangkui-give"] = "飨馈：你可正面朝上交给 %dest 至多同势力角色数张与其所选类别不同的牌",
  ["#fengsui_heg__yangmingRemake-give"] = "扬名：选择一张手牌和一名与此前目标势力不同的角色",
  ["#fengsui_heg__shuge-give"] = "束阁：选择一张伤害牌交给一名角色，令其与 %dest 拼点",
  ["#HegInitialNotice"] = "提示：模式规则已上线，请在创建房间页面中查看。",
  ["#KingdomFiltered"] = "本局移除 %arg，使用 %arg2 四个势力。",
}

assert(#extension.generals == 10, "fengsui_liwu must register exactly 10 official generals")
require "packages.fengsui.pkg.fengsui_liwu.option_translations"

return extension
