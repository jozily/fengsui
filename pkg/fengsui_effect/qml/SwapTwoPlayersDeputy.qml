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

  // 左武将卡片
  GeneralCardItem {
    id: leftCard
    dataModel: Ltk.createGeneralCardModel(generalLeft, { detailed: false })
    scale: 1.7             // 初始缩放比例（可根据实际调整）
    x: -leftCard.width - 200  // 初始位置：左侧屏幕外
    y: root.height / 2  - 100
    opacity: 0               // 初始透明
    z: 1                     // 层级高于背景（若有）
  }

  // 右武将卡片
  GeneralCardItem {
    id: rightCard
    dataModel: Ltk.createGeneralCardModel(generalRight, { detailed: false })
    scale: 1.7           // 初始缩放比例
    x: root.width + 200     // 初始位置：右侧屏幕外
    y: root.height / 2 - 100
    opacity: 0               // 初始透明
    z: 1                     // 层级高于背景
  }

  // 交叉互换核心动画（仅卡片和名字）
  SequentialAnimation {
    id: crossAnim
    running: true

    // 阶段1：双卡同时淡入并向中间交叉移动
    ParallelAnimation {
      // 左卡：从左侧外 → 中间偏右（目标位置为屏幕中心偏右）
      PropertyAnimation {
        target: leftCard
        property: "x"
        to: root.width / 2 + 125  // 最终停在中心右侧125像素
        duration: 2000
        easing.type: Easing.OutBack  // 弹性效果（先快后慢带回弹）
      }
      PropertyAnimation {
        target: leftCard
        property: "opacity"
        to: 1                    // 淡入
        duration: 700
      }

      // 右卡：从右侧外 → 中间偏左（目标位置为屏幕中心偏左）
      PropertyAnimation {
        target: rightCard
        property: "x"
        to: root.width / 2 - 125 // 最终停在中心左侧125像素
        duration: 2000
        easing.type: Easing.OutBack
      }
      PropertyAnimation {
        target: rightCard
        property: "opacity"
        to: 1                    // 淡入
        duration: 700
      }
    }

    // 阶段2：短暂停留（强化交叉效果）
    PauseAnimation { duration: 600 }  // 停留600ms

    // 阶段3：双卡交换位置并淡出
    ParallelAnimation {
      // 左卡：从中间偏右 → 右侧外（原右卡退出位置）
      PropertyAnimation {
        target: leftCard
        property: "x"
        to: root.width + 125    // 回到右侧初始位置
        duration: 2000
        easing.type: Easing.InBack  // 反向弹性（先慢后快）
      }
      PropertyAnimation {
        target: leftCard
        property: "opacity"
        to: 0                    // 淡出
        duration: 1000
      }

      // 右卡：从中间偏左 → 左侧外（原左卡退出位置）
      PropertyAnimation {
        target: rightCard
        property: "x"
        to: -rightCard.width - 125  // 回到左侧初始位置
        duration: 2000
        easing.type: Easing.InBack
      }
      PropertyAnimation {
        target: rightCard
        property: "opacity"
        to: 0                    // 淡出
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
    crossAnim.restart();
  }
}
