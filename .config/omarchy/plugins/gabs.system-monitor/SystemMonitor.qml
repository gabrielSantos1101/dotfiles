import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
    id: root
    moduleName: "gabs.system-monitor"
    property int cpuUsage: 0
    property int ramPercent: 0
    property real ramUsedGB: 0
    property real ramTotalGB: 0
    property int tempC: 0

    implicitWidth: textMetrics.width + 8
    implicitHeight: barSize

    TextMetrics {
        id: textMetrics
        text: textItem.text
        font: textItem.font
    }

    Process {
        id: monitorProc
        command: ["bash", "-c", "python3 -c \"
import json,time,os
prev_total=0; prev_idle=0
def cpu():
    global prev_total,prev_idle
    try:
        with open('/proc/stat') as f:
            l=f.readline()
        p=[float(x) for x in l.split()[1:]]
        total=sum(p); idle=p[3] if len(p)>3 else 0
        if prev_total==0:
            prev_total,prev_idle=total,idle; time.sleep(0.05)
            with open('/proc/stat') as f:
                l=f.readline()
            p=[float(x) for x in l.split()[1:]]
            total=sum(p); idle=p[3] if len(p)>3 else 0
        td=total-prev_total; id=idle-prev_idle
        prev_total,prev_idle=total,idle
        if td<=0: return 0
        return max(0,min(100,(td-id)/td*100))
    except: return 0
def mem():
    try:
        m={}
        with open('/proc/meminfo') as f:
            for line in f:
                if ':' in line:
                    k,v=line.split(':',1)
                    parts=v.strip().split()
                    if parts: m[k]=int(parts[0])*1024
        total=m.get('MemTotal',0)
        avail=m.get('MemAvailable')
        if avail is None: avail=m.get('MemFree',0)+m.get('Buffers',0)+m.get('Cached',0)
        used=total-avail
        if total<=0: return (0,0,0)
        return (int(round(used/total*100)), round(used/1e9,1), round(total/1e9,1))
    except: return (0,0,0)
def temp():
    try:
        best=0; bpri=-1
        for z in sorted(os.listdir('/sys/class/thermal')):
            if not z.startswith('thermal_zone'): continue
            zp=os.path.join('/sys/class/thermal',z)
            try:
                with open(os.path.join(zp,'type')) as f: t=f.read().strip()
                with open(os.path.join(zp,'temp')) as f: tr=int(f.read().strip())
                tc=tr//1000 if tr>1000 else tr
                if tc<=0 or tc>150: continue
                pri=0
                if any(x in t for x in ['x86_pkg','package','cpu','acpitz']): pri=3
                elif 'core' in t: pri=2
                elif any(x in t for x in ['soc','gpu']): pri=1
                if pri>bpri or (pri==bpri and tc>best): best=tc; bpri=pri
            except: pass
        return int(best) if best>0 else 0
    except: return 0
rp,ru,rt = mem()
print(json.dumps({'cpu':int(round(cpu())),'rp':rp,'ru':ru,'rt':rt,'t':temp()}))
\""]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var d = JSON.parse(text)
                    root.cpuUsage = d.cpu
                    root.ramPercent = d.rp
                    root.ramUsedGB = d.ru
                    root.ramTotalGB = d.rt
                    root.tempC = d.t
                } catch (e) {}
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            monitorProc.running = false
            monitorProc.running = true
        }
    }

    Component.onCompleted: {
        monitorProc.running = false
        monitorProc.running = true
    }

    Text {
        id: textItem
        anchors.centerIn: parent
        text: " " + root.cpuUsage + "%   " + root.ramPercent + "%" + (root.tempC > 0 ? "  " + getTempIcon(root.tempC) + " " + root.tempC + "°C" : "")
        color: root.bar ? root.bar.barForeground : Color.foreground
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
        textFormat: Text.PlainText
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: {
            if (root.bar) root.bar.showTooltip(root, "CPU: " + root.cpuUsage + "%\nRAM: " + root.ramPercent + "% (" + root.ramUsedGB + "GB / " + root.ramTotalGB + "GB)\nTemp: " + (root.tempC > 0 ? root.tempC + "°C" : "N/A"))
        }
        onExited: {
            if (root.bar) root.bar.hideTooltip()
        }
        onClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton) {
                root.bar.run("omarchy-launch-floating-terminal-with-presentation btop")
            }
        }
    }

    function getTempIcon(temp) {
        if (temp < 40) return "󱃃"
        if (temp < 60) return "󰔏"
        if (temp < 80) return "󱃂"
        return "󰸁"
    }
}