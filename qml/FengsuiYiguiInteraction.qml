// 烽燧燎原：役鬼/汲魂的「魂 + 牌名」联合选择框。
// 由 pkg/zuoci_compat.lua 在 fengsui 包加载时挂到官方 ld__yigui 上；
// 未加载 fengsui 时官方 hegemony/qml/YiGuiInteraction.qml 照旧使用。
//
// 官方版把万能牌堆里的一堆实体牌展开供点选，这里改成两个按钮：
// 左边选牌名（复用烽燧已有的牌名框），右边选魂（烽燧版势力分栏框）。
// 两份选择打包成 "魂名|牌名" 通过 Interaction 回传，Lua 侧 viewAs 解析。
//
// 数据由 Lua 侧摊平成平行数组传进来（cardKeys / cardNames），这里不做嵌套表
// 下标对齐；所有取值都过 toList()，兼容 Qt 把数组转成「数字键对象」的情况。

import QtQuick
import Fk
import Fk.Components.Common
import LunarLtk

Item {
  id: root

  property string skillName: ""
  property var souls: []
  property var soulLabels: []
  property var availableSouls: []
  property var allCardNames: []
  // cardKeys[i] = "魂|牌名"，cardNames[i] 为同位置的可读牌名
  property var cardKeys: []
  property var cardNames: []
  property var soulTabs: []

  property string soul: ""
  property string cardName: ""

  width: buttonRow.width
  height: buttonRow.height

  // 数组可能以 JS 数组、QVariantList 或「数字键对象」三种形态抵达，统一成数组。
  function toList(v) {
    if (!v) return [];
    if (Array.isArray(v)) return v;
    if (typeof v.length === "number") return v;
    const keys = Object.keys(v).filter(k => /^\d+$/.test(k));
    if (keys.length === 0) return [];
    keys.sort((a, b) => parseInt(a, 10) - parseInt(b, 10));
    return keys.map(k => v[k]);
  }

  function keys() { return toList(root.cardKeys); }
  function names() { return toList(root.cardNames); }
  function soulsList() { return toList(root.souls); }
  function availableList() { return toList(root.availableSouls); }

  // 某个魂能不能印某个牌名
  function canPrint(soulName, name) {
    return keys().indexOf(soulName + "|" + name) >= 0;
  }

  // 该魂能印的第一个牌名，没有则空串
  function firstCardOf(soulName) {
    const list = keys();
    const prefix = soulName + "|";
    for (let i = 0; i < list.length; ++i) {
      if (typeof list[i] === "string" && list[i].indexOf(prefix) === 0)
        return list[i].substring(prefix.length);
    }
    return "";
  }

  // 数据一到就选好默认魂与默认牌名，避免出现「还没选魂所以牌名点不了」的死状态。
  onCardKeysChanged: {
    console.log("[fengsui-yigui] souls=" + soulsList().length
      + " available=" + availableList().length
      + " keys=" + keys().length
      + " names=" + names().length
      + " allCards=" + toList(root.allCardNames).length
      + " rawIsArray=" + Array.isArray(root.cardKeys)
      + "/" + Array.isArray(root.souls));
    const list = keys();
    if (list.length === 0) return;
    if (!root.soul) {
      const first = String(list[0]);
      const bar = first.indexOf("|");
      if (bar > 0) root.soul = first.substring(0, bar);
    }
    if (!root.cardName || !canPrint(root.soul, root.cardName))
      root.cardName = firstCardOf(root.soul);
    send();
  }

  function send() {
    // 即使某一项还没选也要回传，避免 interaction.data 停留在旧组合。
    Lua.updateRequestUI("Interaction", "1", "update", root.soul + "|" + root.cardName);
  }

  function setSoul(name) {
    if (root.soul === name) return;
    root.soul = name;
    // 换魂后原牌名印不出来就换成本魂能印的第一个；一个都印不出来才清空。
    if (root.cardName && !canPrint(name, root.cardName))
      root.cardName = firstCardOf(name);
    send();
  }

  function setCard(name) {
    root.cardName = name;
    // 反向对齐魂：该牌名若当前魂印不出来，换成能印它的第一个魂。
    if (!canPrint(root.soul, name)) {
      const list = keys();
      const suffix = "|" + name;
      for (let i = 0; i < list.length; ++i) {
        const k = String(list[i]);
        if (k.endsWith(suffix)) {
          root.soul = k.substring(0, k.length - suffix.length);
          break;
        }
      }
    }
    send();
  }

  function chooseCard() {
    const list = names();
    if (list.length === 0) {
      console.log("[fengsui-yigui] 牌名列表为空：交互数据未到达，或当前确实无可印牌名");
      return;
    }
    const component = Qt.createComponent(
      Cpp.path + "/packages/fengsui/pkg/fengsui_effect/qml/FengsuiCardNameBox.qml"
    );
    if (!component || component.status !== Component.Ready) {
      console.log("[fengsui-yigui] 牌名框加载失败: "
        + (component ? component.errorString() : "null"));
      return;
    }
    const scene = Ltk.roomScene;
    scene.showPopup(component, {
      choices: list,
      allChoices: toList(root.allCardNames),
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
    if (availableList().length === 0) return;
    const component = Qt.createComponent(
      Cpp.path + "/packages/fengsui/qml/FengsuiYiguiSoulBox.qml"
    );
    if (!component || component.status !== Component.Ready) {
      console.log("[fengsui-yigui] 魂选择框加载失败: "
        + (component ? component.errorString() : "null"));
      return;
    }
    const scene = Ltk.roomScene;
    scene.showPopup(component, {
      cards: soulsList(),
      availableCards: availableList(),
      soulTabs: toList(root.soulTabs),
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
      enabled: root.names().length > 0
      text: root.cardName
        ? Ltk.processPrompt(root.cardName)
        : qsTr("\u9009\u62E9\u724C\u540D")
      onClicked: root.chooseCard()
    }

    MetroButton {
      id: soulButton
      width: 148
      height: 34
      enabled: root.availableList().length > 0
      text: {
        if (!root.soul) return qsTr("\u9009\u62E9\u9B42");
        // 势力与将名的文字由 Lua 侧拼好（souls 与 soulLabels 同下标）。
        const list = root.soulsList();
        const labels = root.toList(root.soulLabels);
        const idx = list.indexOf(root.soul);
        if (idx >= 0 && labels[idx]) return String(labels[idx]);
        return Lua.tr(root.soul);
      }
      onClicked: root.chooseSoul()
    }
  }
}
