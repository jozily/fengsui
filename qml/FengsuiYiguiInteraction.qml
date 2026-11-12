// 烽燧燎原：役鬼/汲魂的「魂 + 牌名」联合选择框。
// 由 pkg/zuoci_compat.lua 在 fengsui 包加载时挂到官方 ld__yigui 上；
// 未加载 fengsui 时官方 hegemony/qml/YiGuiInteraction.qml 照旧使用。
//
// 官方版把万能牌堆里的一堆实体牌展开供点选，这里改成两个按钮：
// 左边选牌名（复用烽燧已有的牌名框），右边选魂（烽燧版势力分栏框）。
// 两份选择打包成 "魂名|牌名" 通过 Interaction 回传，Lua 侧 viewAs 解析。

import QtQuick
import Fk
import Fk.Components.Common
import LunarLtk

Item {
  id: root

  property string skillName: ""
  property var souls: []
  property var availableSouls: []
  property var allCardNames: []
  property var cardNamesBySoul: []
  property var soulTabs: []

  property string soul: ""
  property string cardName: ""

  width: buttonRow.width
  height: buttonRow.height

  readonly property var currentCardNames: {
    const idx = souls.indexOf(soul);
    const list = idx >= 0 ? cardNamesBySoul[idx] : [];
    return Array.isArray(list) ? list : [];
  }

  function send() {
    // 即使某一项还没选也要回传，避免 interaction.data 停留在旧组合。
    Lua.updateRequestUI("Interaction", "1", "update", soul + "|" + cardName);
  }

  function setSoul(name) {
    if (soul === name) return;
    soul = name;
    if (!currentCardNames.includes(cardName))
      cardName = "";
    send();
  }

  function setCard(name) {
    if (cardName === name) return;
    cardName = name;
    send();
  }

  function chooseCard() {
    if (currentCardNames.length === 0) return;
    const component = Qt.createComponent(
      Cpp.path + "/packages/fengsui/pkg/fengsui_effect/qml/FengsuiCardNameBox.qml"
    );
    const scene = Ltk.roomScene;
    scene.showPopup(component, {
      choices: currentCardNames,
      allChoices: allCardNames,
      prompt: "#fengsui_yigui-card",
      result: cardName,
    });
    const box = scene.popupItem;
    box.accepted.connect(() => {
      if (box.result)
        setCard(box.result);
      box.finished();
    });
  }

  function chooseSoul() {
    if (availableSouls.length === 0) return;
    const component = Qt.createComponent(
      Cpp.path + "/packages/fengsui/qml/FengsuiYiguiSoulBox.qml"
    );
    const scene = Ltk.roomScene;
    scene.showPopup(component, {
      cards: souls,
      availableCards: availableSouls,
      soulTabs: soulTabs,
      result: soul,
    });
    const box = scene.popupItem;
    box.accepted.connect(() => {
      if (box.result)
        setSoul(box.result);
      box.finished();
    });
  }

  // RoomBase 每次刷新交互后会调用 item.clicked()；这里保持静默，
  // 由玩家自己点按钮打开弹框，避免自动弹窗打断出牌。
  function clicked() {}

  Row {
    id: buttonRow
    spacing: 8

    MetroButton {
      id: cardButton
      width: 148
      height: 34
      enabled: root.currentCardNames.length > 0
      text: root.cardName
        ? Ltk.processPrompt(root.cardName)
        : qsTr("\u9009\u62E9\u724C\u540D")
      onClicked: root.chooseCard()
    }

    MetroButton {
      id: soulButton
      width: 148
      height: 34
      enabled: root.availableSouls.length > 0
      text: {
        if (!root.soul) return qsTr("\u9009\u62E9\u9B42");
        const data = Ltk.getGeneralData(root.soul);
        const k = data && data.kingdom ? data.kingdom : "";
        // 本模式把 "jin" 翻译成带 HTML 的富文本势力名，按钮上直接写汉字。
        const kingdom = k === "jin" ? qsTr("\u664B")
          : k === "wild" ? qsTr("\u91ce")
          : k ? Lua.tr(k) : "";
        return (kingdom ? kingdom + "|" : "") + Lua.tr(root.soul);
      }
      onClicked: root.chooseSoul()
    }
  }
}
