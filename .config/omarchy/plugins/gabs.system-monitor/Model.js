// System Monitor Model - parses /proc and /sys content

let prevCpuIdle = 0
let prevCpuTotal = 0

function parseCpuStat(content) {
    if (!content) return { usage: 0 }

    var lines = content.split("\n")
    var cpuLine = null
    for (var i = 0; i < lines.length; i++) {
        if (lines[i].startsWith("cpu ")) {
            cpuLine = lines[i]
            break
        }
    }
    if (!cpuLine) return { usage: 0 }

    var parts = cpuLine.trim().split(/\s+/).slice(1).map(Number)
    var user = parts[0] || 0
    var nice = parts[1] || 0
    var system = parts[2] || 0
    var idle = parts[3] || 0
    var iowait = parts[4] || 0
    var irq = parts[5] || 0
    var softirq = parts[6] || 0
    var steal = parts[7] || 0

    var idleTime = idle + iowait
    var totalTime = user + nice + system + idle + iowait + irq + softirq + steal

    var usage = 0
    if (prevCpuTotal > 0) {
        var idleDelta = idleTime - prevCpuIdle
        var totalDelta = totalTime - prevCpuTotal
        if (totalDelta > 0) {
            usage = Math.max(0, Math.min(100, Math.round((1 - idleDelta / totalDelta) * 100)))
        }
    }

    prevCpuIdle = idleTime
    prevCpuTotal = totalTime

    return { usage: usage }
}

function parseMemInfo(content) {
    if (!content) return { usedPercent: 0, usedGB: 0, totalGB: 0 }

    var lines = content.split("\n")
    var memTotal = 0
    var memAvailable = 0

    for (var i = 0; i < lines.length; i++) {
        var line = lines[i]
        if (line.startsWith("MemTotal:")) {
            memTotal = parseInt(line.split(/\s+/)[1]) || 0
        } else if (line.startsWith("MemAvailable:")) {
            memAvailable = parseInt(line.split(/\s+/)[1]) || 0
        }
    }

    var usedKB = memTotal - memAvailable
    var usedPercent = memTotal > 0 ? Math.round((usedKB / memTotal) * 100) : 0
    var usedGB = (usedKB / 1024 / 1024).toFixed(1)
    var totalGB = (memTotal / 1024 / 1024).toFixed(1)

    return { usedPercent: usedPercent, usedGB: usedGB, totalGB: totalGB }
}

function parseTemperature(content) {
    if (!content) return { temperature: 0 }

    var lines = content.trim().split("\n")
    var maxTemp = 0
    for (var i = 0; i < lines.length; i++) {
        var line = lines[i].trim()
        if (!line) continue
        var parts = line.split(/\s+/)
        var temp = parseInt(parts[0]) || 0
        var tempC = temp / 1000
        var type = parts.length > 1 ? parts.slice(1).join(" ").toLowerCase() : ""

        // Prioritize CPU package / core temps
        if (type.includes("cpu") || type.includes("core") || type.includes("package") || type.includes("x86_pkg")) {
            if (tempC > maxTemp) maxTemp = tempC
        } else if (tempC > maxTemp && tempC < 120) {
            maxTemp = tempC
        }
    }

    return { temperature: Math.round(maxTemp) }
}

if (typeof module !== "undefined") {
    module.exports = {
        parseCpuStat: parseCpuStat,
        parseMemInfo: parseMemInfo,
        parseTemperature: parseTemperature
    }
}