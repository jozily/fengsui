import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Fk
import LunarLtk
import LunarLtk.Pages.Popups
import LunarLtk.Components

Item {
  id: root
  anchors.fill: parent
  property string generalLeft: "liubei"
  property string generalRight: "guanyu"

  GeneralCardItem {
    id: leftCard
    dataModel: Ltk.createGeneralCardModel(generalLeft, { detailed: false })
    scale: 1.7
    x: -leftCard.width - 200
    y: root.height / 2  - 100
    opacity: 0
    z: 1
  }

  GeneralCardItem {
    id: rightCard
    dataModel: Ltk.createGeneralCardModel(generalRight, { detailed: false })
    scale: 1.7
    x: root.width + 200
    y: root.height / 2 - 100
    opacity: 0
    z: 1
  }

  SequentialAnimation {
    id: crossAnim
    running: true

    // 阶段1：双卡同时淡入并向中间交叉移动
    ParallelAnimation {
      PropertyAnimation {
        target: leftCard
        property: "x"
        to: root.width / 2 + 125 
        duration: 2000
        easing.type: Easing.OutBack
      }
      PropertyAnimation {
        target: leftCard
        property: "opacity"
        to: 1
        duration: 700
      }

      PropertyAnimation {
        target: rightCard
        property: "x"
        to: root.width / 2 - 125
        duration: 2000
        easing.type: Easing.OutBack
      }
      PropertyAnimation {
        target: rightCard
        property: "opacity"
        to: 1
        duration: 700
      }
    }

    // 阶段2：短暂停留（强化交叉效果）
    PauseAnimation { duration: 600 }

    // 阶段3：双卡交换位置并淡出
    ParallelAnimation {
      PropertyAnimation {
        target: leftCard
        property: "x"
        to: root.width + 125
        duration: 2000
        easing.type: Easing.InBack 
      }
      PropertyAnimation {
        target: leftCard
        property: "opacity"
        to: 0
        duration: 1000
      }

      PropertyAnimation {
        target: rightCard
        property: "x"
        to: -rightCard.width - 125 
        duration: 2000
        easing.type: Easing.InBack
      }
      PropertyAnimation {
        target: rightCard
        property: "opacity"
        to: 0
        duration: 1000
      }
    }

    onFinished: {
      leftCard.x = -leftCard.width - 100;
      rightCard.x = root.width + 100;
      leftCard.opacity = 0;
      rightCard.opacity = 0;
      roomScene.bigAnim.source = "";
    }
  }

  function loadData(data) {
    generalLeft = data.generalLeft;
    generalRight = data.generalRight;
  }
}

