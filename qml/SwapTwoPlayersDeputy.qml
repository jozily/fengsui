import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Fk
import Fk.Components.LunarLTK
import Fk.Pages.LunarLTK
import Fk.Components.Common

Item {
  id: root
  anchors.fill: parent
  property string generalNameLeft: "liubei"   
  property string generalNameRight: "guanyu"

  GeneralCardItem {
    id: leftCard
    name: generalNameLeft
    scale: 1.7            
    x: -leftCard.width - 200
    y: root.height / 2  - 100
    opacity: 0              
    detailed: false        
    z: 1                     
  }

  GeneralCardItem {
    id: rightCard
    name: generalNameRight  
    scale: 1.7           
    x: root.width + 200     
    y: root.height / 2 - 100 
    opacity: 0               
    detailed: false        
    z: 1                   
  }

  SequentialAnimation {
    id: crossAnim
    running: false          

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
    generalNameLeft = data.generalLeft || "liubei";
    generalNameRight = data.generalRight || "guanyu";
    crossAnim.restart();
  }
}

