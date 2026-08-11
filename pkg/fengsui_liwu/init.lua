local extension = Package:new("fengsui_liwu")
extension.extensionName = "fengsui"
extension.game_modes_whitelist = { "new_heg_mode", "fengsui_heg__mode" }

extension:loadSkillSkelsByPath("./packages/fengsui/pkg/fengsui_liwu/skills")

local zhouxuan = General:new(extension, "fengsui_heg__zhouxuan", "wei", 3)
zhouxuan:addSkills { "fengsui_heg__wumei", "fengsui_heg__jiemeng" }

Fk:loadTranslationTable{
  ["fengsui_heg__zhouxuan"] = "周宣",
  ["#fengsui_heg__zhouxuan"] = "醒踌者",
  ["designer:fengsui_heg__zhouxuan"] = "公冶长风",
  ["illustrator:fengsui_heg__zhouxuan"] = "公冶长风",
  ["cv:fengsui_heg__zhouxuan"] = "暂无",
  ["fengsui_heg__wumei"] = "寤寐",
  [":fengsui_heg__wumei"] = "当你明置此武将牌时，你可以视为使用一张【巧取豪夺】，然后若你因此获得奇珍牌，你本回合使用牌无次数限制。",
  ["#fengsui_heg__wumei"] = "寤寐：你可以视为使用【巧取豪夺】",
  ["fengsui_heg__jiemeng"] = "解梦",
  [":fengsui_heg__jiemeng"] = "当你受到伤害后，你可以视为对一名确定势力的角色使用一张【咄咄逼人】，若其因此受到伤害且你武将牌均明置，你暗置此武将牌。",
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
chenshou:addSkills { "fengsui_heg__dianmo", "fengsui_heg__fuzai" }

Fk:loadTranslationTable{
  ["fengsui_heg__chenshou"] = "陈寿",
  ["#fengsui_heg__chenshou"] = "犁山者",
  ["designer:fengsui_heg__chenshou"] = "公冶长风",
  ["illustrator:fengsui_heg__chenshou"] = "公冶长风",
  ["cv:fengsui_heg__chenshou"] = "暂无",
  ["fengsui_heg__dianmo"] = "点墨",
  [":fengsui_heg__dianmo"] = "每轮限一次，你可以将一张红色/黑色装备牌当【无懈可击】/【掠闪】使用；当你使用奇珍牌后，你可以与一名装备区牌数量小于你的角色交换装备区的所有牌。",
  ["#fengsui_heg__dianmo-use"] = "点墨：你可以将一张装备牌当【无懈可击】或【掠闪】使用",
  ["#fengsui_heg__dianmo-swap"] = "点墨：你可以与一名装备区牌数较少的角色交换装备区的所有牌",
  ["fengsui_heg__fuzai"] = "覆载",
  [":fengsui_heg__fuzai"] = "锁定技，若你未装备宝物，你视为装备【九州鼎】。当其他角色装备【九州鼎】后，你需选择一项：1.弃置装备区所有牌并变更副将；2.视为使用一张【分道扬镳】。",
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
sunyuan:addSkills { "fengsui_heg__dongxin" }

Fk:loadTranslationTable{
  ["fengsui_heg__sunyuan"] = "孙鸢",
  ["#fengsui_heg__sunyuan"] = "履尘者",
  ["designer:fengsui_heg__sunyuan"] = "公冶长风",
  ["illustrator:fengsui_heg__sunyuan"] = "公冶长风",
  ["cv:fengsui_heg__sunyuan"] = "暂无",
  ["fengsui_heg__dongxin"] = "恫心",
  [":fengsui_heg__dongxin"] = "当你受到或造成伤害后，你可以视为对伤害来源或目标使用一张【图穷匕见】并与其各摸一张牌，然后你可弃置任意张牌并使用其中的【杀】（不计入次数）。",
  ["#fengsui_heg__dongxin-discard"] = "恫心：你可以弃置任意张牌，并依次使用其中的【杀】",
  ["#fengsui_heg__dongxin-use"] = "恫心：你可以使用弃牌堆中的此【杀】",
    ["$fengsui_heg__dongxin1"] = "三军胆裂非因剑，一念慑魂自威仪！",
  ["$fengsui_heg__dongxin2"] = "战鼓未擂心先乱，何不卸甲拜红妆？",
  ["$fengsui_heg__dongxin3"] = "心胆俱寒，便是千军也自溃。",
  ["$fengsui_heg__dongxin4"] = "恫心夺志，破阵只在一念之间。",
  ["~fengsui_heg__sunyuan"] = "此月曾照闺中……",
}

local liuhui = General:new(extension, "fengsui_heg__liuhui", "qun", 3)
liuhui:addSkills { "fengsui_heg__jieshu" }

Fk:loadTranslationTable{
  ["fengsui_heg__liuhui"] = "刘徽",
  ["#fengsui_heg__liuhui"] = "精算者",
  ["designer:fengsui_heg__liuhui"] = "公冶长风",
  ["illustrator:fengsui_heg__liuhui"] = "公冶长风",
  ["cv:fengsui_heg__liuhui"] = "暂无",
  ["fengsui_heg__jieshu"] = "解术",
  [":fengsui_heg__jieshu"] = "当你于回合内使用牌指定目标后，你可视为使用一张合法目标数一致的普通锦囊牌，然后此技能失效直至你获得奇珍牌或使用一张与此牌合法目标数一致的实体牌。",
  ["#fengsui_heg__jieshu"] = "解术：你可以使用一张合法目标数为 %arg 的普通锦囊牌",
  ["@fengsui_heg__jieshu"] = "解术失效",
      ["$fengsui_heg__jieshu1"] = "累乘除以成九数者，可以加减解之。",
    ["$fengsui_heg__jieshu2"] = "数有其理，见筹一可知沙数。",
  ["$fengsui_heg__jieshu3"] = "万法虽繁，皆可归于一算。",
  ["$fengsui_heg__jieshu4"] = "以术破术，方知变化无穷。",
  ["~fengsui_heg__liuhui"] = "算学如海，穷我一生，只得杯水。",
}

local wanghuifeng = General:new(extension, "fengsui_heg__wanghuifeng", "jinh", 4, 4, General.Female)
wanghuifeng:addSkills { "fengsui_heg__dilie" }

Fk:loadTranslationTable{
  ["fengsui_heg__wanghuifeng"] = "王惠风",
  ["#fengsui_heg__wanghuifeng"] = "戮时者",
  ["designer:fengsui_heg__wanghuifeng"] = "公冶长风",
  ["illustrator:fengsui_heg__wanghuifeng"] = "公冶长风",
  ["cv:fengsui_heg__wanghuifeng"] = "暂无",
  ["fengsui_heg__dilie"] = "砥烈",
  [":fengsui_heg__dilie"] = "当你造成伤害后，你可以重铸任意张装备牌；当你受到伤害后，若你没有武器牌，你可以从弃牌堆获得一张武器牌，若此牌为奇珍牌，则你可以对伤害来源造成1点伤害。",
  ["#fengsui_heg__dilie-recast"] = "砥烈：你可以重铸任意张装备牌",
  ["#fengsui_heg__dilie-weapon"] = "砥烈：选择弃牌堆中的一张武器牌获得",
  ["$fengsui_heg__dilie1"] = "烈节在心，岂因危迫而改！",
  ["$fengsui_heg__dilie2"] = "宁折此身，不坠家门清望。",
  ["$fengsui_heg__dilie3"] = "刀兵虽厉，难夺我守志之心。",
  ["$fengsui_heg__dilie4"] = "我皇太子妇，司徒公之女，胡羌小丑，敢欲干我乎？",
  ["~fengsui_heg__wanghuifeng"] = "宗族倾覆，妾亦不独生……",
}

local simayou = General:new(extension, "SP_heg__simayou", "jinh", 3)
simayou:addSkills { "heg__fuzheng", "heg__yunde" }
simayou:addCompanions("fengsui_heg__jiabao")
Fk:loadTranslationTable{
  ["SP_heg__simayou"] = "司马攸",
  ["#SP_heg__simayou"] = "舞阳侯",
  ["designer:SP_heg__simayou"] = "时时六&雪人学长",
  ["$heg__fuzheng1"] = "承景王之嗣，当佐宗室以安社稷。",
  ["$heg__fuzheng2"] = "宗亲有难，攸岂可袖手旁观。",
  ["$heg__fuzheng3"] = "辅弼朝纲，所念唯国，不计私门。",
  ["$heg__fuzheng4"] = "愿移此位，换宗室一脉得安。",
  ["$heg__yunde1"] = "德不独善，当分惠于宗亲。",
  ["$heg__yunde2"] = "知人而后任之，量才而后授之。",
  ["$heg__yunde3"] = "兄弟同心，何必以储位相疑。",
  ["$heg__yunde4"] = "进不争权，退不避责，此为臣节。",
  ["~SP_heg__simayou"] = "臣弟别无他志，陛下何以疑我至此……",
}

local jiananfeng = General:new(extension, "SP_heg__jiananfeng", "wild", 3, 3, General.Female)
jiananfeng:addSkills { "heg__liaoye", "heg__fangzi", "heg__liudu" }
jiananfeng:addCompanions{ "male_generals" }
jiananfeng:addCompanionRule(function(self, other)
  return other:isMale()
end)
Fk:loadTranslationTable{
  ["SP_heg__jiananfeng"] = "贾南风",
  ["#SP_heg__jiananfeng"] = "窥鼎的司晨雉",
  ["illustrator:SP_heg__jiananfeng"] = "小罗没想好",
  ["$heg__liaoye1"] = "这晋室江山，本宫要它烧成何样，它便是何样！",
  ["$heg__liaoye2"] = "尔等尽管选边，留下的那一边，本宫亲自烧个干净。",
  ["$heg__liaoye3"] = "区区朝臣，也敢妄议本宫的手段？",
  ["$heg__liaoye4"] = "烈火焚城，正好替本宫筛尽忤逆之徒。",
  ["$heg__fangzi1"] = "废谁立谁，不过本宫一句话罢了。",
  ["$heg__fangzi2"] = "位置坐得久了，便真当自己配得上？",
  ["$heg__fangzi3"] = "今日借你一席之地，明日便可收你一条命。",
  ["$heg__fangzi4"] = "朝堂如棋，诸位都是本宫手中的子。",
  ["$heg__liudu1"] = "本宫纵入黄泉，也要看司马氏骨肉相食！",
  ["$heg__liudu2"] = "毒已入骨，尔等谁也休想独善其身！",
  ["$heg__liudu3"] = "杀了本宫又如何？这天下早已烂透了！",
  ["$heg__liudu4"] = "来啊，且看这满朝冠冕还能撑到几时！",
  ["~SP_heg__jiananfeng"] = "贾氏竟败于尔等鼠辈……本宫不服！",
  ["male_generals"] = "男性武将",
}

local liufuren = General:new(extension, "SP_heg__liufuren", "qun", 3, 3, General.Female)
liufuren:addSkills { "SP_heg__zhuidu", "SP_heg__shigong" }

local himiko = General:new(extension, "SP_heg__himiko", "qun", 3, 3, General.Female)
himiko:addSkills { "SP_heg__guishu", "SP_heg__yuanyuk" }

Fk:loadTranslationTable {
  ["SP_heg__liufuren"] = "刘夫人",
  ["#SP_heg__liufuren"] = "酷妒的海棠",
  ["illustrator:SP_heg__liufuren"] = "Jzeo",
  ["designer:SP_heg__liufuren"] = "梦魇狂朝",
  ["~SP_heg__liufuren"] = "害人终害己，最毒妇人心……",

  ["SP_heg__himiko"] = "卑弥呼",
  ["#SP_heg__himiko"] = "邪马台的女王",
  ["illustrator:SP_heg__himiko"] = "聚一_小道恩",
  ["designer:SP_heg__himiko"] = "淬毒",
  ["~SP_heg__himiko"] = "我还会从黄泉比良坂回来的……",
}


Fk:appendKingdomMap("fengsui_neutral", { "wei", "shu", "wu", "qun", "jinh" })
Fk:appendKingdomMap("fengsui_neutralall", { "wei", "shu", "wu", "qun", "jinh" })
require("packages.fengsui.pkg.fengsui_liwu.liwu_neutral_compat").install()

local jiaxu = General:new(extension, "fengsui_heg__jiaxu", "fengsui_neutralall", 3)
jiaxu:addCompanions("st_heg__jiaxu")
jiaxu:addSkill("fengsui_heg__qingshi_jx")
jiaxu:addSkill("fengsui_heg__anshi")
jiaxu:addSkill("fengsui_heg__shuge")

local lusu = General:new(extension, "fengsui_heg__lusu", "fengsui_neutralall", 4)
lusu:addCompanions("st_heg__lusu")
lusu:addSkill("fengsui_heg__xiangkui")
lusu:addSkill("fengsui_heg__yangming")

local xushu = General:new(extension, "fengsui_heg__xushu", "fengsui_neutralall", 4)
xushu.mainMaxHpAdjustedValue = -1
xushu:addCompanions("ze_heg__xushu")
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
  ["fengsui_neutralall"] = "中立者",
  ["heg__zhongliji"] = "中立技：确定势力后失去的技能。<br>中立者：单独亮明中立者时按单独势力计算，但属于未确定势力角色，可搭配任意势力武将牌。最终势力和获胜条件随有势力的武将牌一方；若一方为双势力角色则亮明该武将牌时需声明所属势力；中立者无法与野心家或另一中立者组合。中立者若阵亡时仍未确定势力，则按照单独势力处理奖惩。需先亮明中立者武将牌一轮后或受到伤害后才可亮明另一张武将牌（部分技能可无视该条件）。<br>",

  ["fengsui_heg__jiaxu"] = "贾诩",
  ["#fengsui_heg__jiaxu"] = "踱步逆世",
  ["~fengsui_heg__jiaxu"] = "肃侯已老，此生谋断，至此皆休……",
  ["designer:fengsui_heg__jiaxu"] = "公冶天纵",
  ["illustrator:fengsui_heg__jiaxu"] = "佚名",
  ["cv:fengsui_heg__jiaxu"] = "暂无",
  ["fengsui_heg__qingshi_jx"] = "清饰",
  [":fengsui_heg__qingshi_jx"] = "每轮限一次，当你成为其他角色黑色锦囊牌或【杀】的目标后，你可弃置一张手牌令此牌对你无效。若你弃置的为黑色牌，你摸一张牌。",
  ["fengsui_heg__anshi"] = "谙世",
  [":fengsui_heg__anshi"] = "出牌阶段限一次，你可以视为使用一张【知己知彼】，若你选择观看其武将牌后，其势力与你一致且你未确定势力，其可选择明置之，然后你明置另一张武将牌并令其于本回合结束后获得一个额外的回合。若你已确定势力，你令目标将手牌调整至手牌上限。",
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
  [":fengsui_heg__xiangkui"] = "其他角色的出牌阶段限一次，其可指定一种类型，然后你可正面朝上交给其任意张手牌并摸交出类别张牌。若以此法交给其的牌中包含其指定的类型，你摸两张牌。",
  ["fengsui_heg__yangming"] = "扬名",
  [":fengsui_heg__yangming"] = "每个回合结束时，你可以摸X张牌，若X不小于场上势力数，你需展示所有手牌并依次选择X张牌和X名势力不同的其他角色，这些角色依次获得一张你选择的牌。（X为你本回合使用的牌的类别数）",
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
  ["~fengsui_heg__xushu"] = "母既被获，方寸已乱，无益于事……",
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
  ["~fengsui_heg__xushao"] = "卧龙已仕，天下已定，吾终得任侠天地",
  ["designer:fengsui_heg__xushao"] = "公冶天纵",
  ["illustrator:fengsui_heg__xushao"] = "佚名",
  ["cv:fengsui_heg__xushao"] = "暂无",
  ["fengsui_heg__yingmen"] = "盈门",
  ["@[private]&fengsui_heg__fangke"] = "访客",
  [":fengsui_heg__yingmen"] = "锁定技，当你明置此武将牌后，你将X张势力不同的武将牌置于你的武将牌上，称为“访客”。回合开始时或你受到伤害后，若你的“访客”数少于X张，则你将“访客”补至X张（X为场上势力数）。",
  ["fengsui_heg__pingjian"] = "评鉴",
  ["#fengsui_heg__pingjian-remove"] = "评鉴：请选择结算后移去的访客",
  [":fengsui_heg__pingjian"] = "你可以发动“访客”武将牌上的一个无类型或仅有锁定技标签的技能（合法发动时机），然后你移去该“访客”并摸一张牌，若“访客”与你势力相同，你摸两张牌。",
  ["$fengsui_heg__yingmen1"] = "德高者，须以礼待之！",
  ["$fengsui_heg__yingmen2"] = "吾好核论乡党，长于明析臧否。",
  ["$fengsui_heg__pingjian1"] = "君清平之奸贼，乱世之英雄。",
  ["$fengsui_heg__pingjian2"] = "议于草野间，评荐俊才多。",

  ["@fengsui_neutral"] = "中立",
  ["@fengsui_neutralall"] = "中立者",
  ["anshi_reveal_main"] = "明置主将",
  ["anshi_reveal_deputy"] = "明置副将",
  ["#fengsui_heg__xiangkui-invoke"] = "飨馈：是否请求 %dest 交给你任意张手牌？",
  ["#fengsui_heg__xiangkui-give"] = "飨馈：你可交给 %dest 任意张手牌",
  ["#fengsui_heg__yangmingRemake-give"] = "扬名：选择一张手牌和一名与此前目标势力不同的角色",
  ["#fengsui_heg__shuge-give"] = "束阁：选择一张伤害牌交给一名角色，令其与 %dest 拼点",
}

return extension
