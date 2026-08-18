import Foundation
import IOKit
import Darwin.Mach

struct SystemMetricsSnapshot {
    var cpuUsage: Double?
    var cpuTemperature: Double?
    var gpuUsage: Double?
    var gpuTemperature: Double?
    var thermalState = "正常"
    var updatedAt: Date?
}

@MainActor
final class SystemMetricsMonitor: ObservableObject {
    @Published private(set) var snapshot = SystemMetricsSnapshot()

    func run(every seconds: Int) async {
        while !Task.isCancelled {
            snapshot = await sampler.sample()
            try? await Task.sleep(nanoseconds: UInt64(seconds) * 1_000_000_000)
        }
    }

    func reset() {
        snapshot = SystemMetricsSnapshot()
    }

    private let sampler = MetricsSampler()
}

private actor MetricsSampler {
    private var previousCPUTicks: CPUTicks?

    func sample() -> SystemMetricsSnapshot {
        SystemMetricsSnapshot(
            cpuUsage: readCPUUsage(),
            cpuTemperature: nil,
            gpuUsage: readGPUUsage(),
            gpuTemperature: nil,
            thermalState: thermalStateText,
            updatedAt: Date()
        )
    }

    private func readCPUUsage() -> Double? {
        var load = host_cpu_load_info_data_t()
        var count = mach_msg_type_number_t(
            MemoryLayout<host_cpu_load_info_data_t>.stride / MemoryLayout<integer_t>.stride
        )
        let result = withUnsafeMutablePointer(to: &load) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return nil }

        let current = CPUTicks(
            user: UInt64(load.cpu_ticks.0),
            system: UInt64(load.cpu_ticks.1),
            idle: UInt64(load.cpu_ticks.2),
            nice: UInt64(load.cpu_ticks.3)
        )
        defer { previousCPUTicks = current }
        guard let previousCPUTicks else { return nil }

        let user = current.user &- previousCPUTicks.user
        let system = current.system &- previousCPUTicks.system
        let idle = current.idle &- previousCPUTicks.idle
        let nice = current.nice &- previousCPUTicks.nice
        let total = user + system + idle + nice
        guard total > 0 else { return nil }
        return min(max(Double(user + system + nice) / Double(total) * 100, 0), 100)
    }

    private func readGPUUsage() -> Double? {
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(
            kIOMainPortDefault,
            IOServiceMatching("IOAccelerator"),
            &iterator
        ) == KERN_SUCCESS else { return nil }
        defer { IOObjectRelease(iterator) }

        var values: [Double] = []
        while true {
            let service = IOIteratorNext(iterator)
            guard service != 0 else { break }
            defer { IOObjectRelease(service) }

            guard let property = IORegistryEntryCreateCFProperty(
                service,
                "PerformanceStatistics" as CFString,
                kCFAllocatorDefault,
                0
            )?.takeRetainedValue() as? [String: Any] else { continue }

            for key in ["Device Utilization %", "GPU Activity(%)", "Renderer Utilization %"] {
                if let number = property[key] as? NSNumber {
                    values.append(number.doubleValue)
                    break
                }
            }
        }
        guard let maximum = values.max() else { return nil }
        return min(max(maximum, 0), 100)
    }

    private var thermalStateText: String {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: "正常"
        case .fair: "偏热"
        case .serious: "较热"
        case .critical: "过热"
        @unknown default: "未知"
        }
    }
}

private struct CPUTicks {
    let user: UInt64
    let system: UInt64
    let idle: UInt64
    let nice: UInt64
}
