import Flutter
import UIKit
import AVFoundation
import CryptoKit
import UserNotifications
#if canImport(AlarmKit)
import AlarmKit
import SwiftUI
#endif

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "NLPrayerAudio") {
      NLPrayerAudioPlugin.register(with: registrar)
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "NLPrayerAlarms") {
      NLPrayerAlarmPlugin.register(with: registrar)
    }
  }
}

// Keep native audio conversion off the UI thread. Library/Sounds is the
// documented location for notification and AlarmKit sound resources.
final class NLPrayerAudioPlugin: NSObject, FlutterPlugin {
  private let queue = DispatchQueue(label: "nl.prayer.audio-import")
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "nl_prayer_times/custom_adhan", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(NLPrayerAudioPlugin(), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "importAudio" || call.method == "prepareDefaultAudio" else {
      result(FlutterMethodNotImplemented); return
    }
    let args = call.arguments as? [String: Any] ?? [:]
    queue.async {
      do {
        let fm = FileManager.default
        let support = try fm.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                 appropriateFor: nil, create: true).appendingPathComponent("AdhanAudio", isDirectory: true)
        try fm.createDirectory(at: support, withIntermediateDirectories: true)
        let isDefault = call.method == "prepareDefaultAudio"
        let source: URL
        if isDefault {
          guard let bytes = args["bytes"] as? FlutterStandardTypedData else {
            throw Self.failure("Bundled adhan is missing")
          }
          source = support.appendingPathComponent("adhan_default.mp3")
          if !fm.fileExists(atPath: source.path) { try bytes.data.write(to: source, options: .atomic) }
        } else {
          guard let path = args["path"] as? String, !path.isEmpty else {
            throw Self.failure("Choose a downloaded audio file from Files")
          }
          source = URL(fileURLWithPath: path)
        }
        let imported = try self.prepare(source: source, support: support, isDefault: isDefault)
        DispatchQueue.main.async { result(isDefault ? nil : imported) }
      } catch {
        DispatchQueue.main.async { result(FlutterError(code: "AUDIO_IMPORT_FAILED", message: error.localizedDescription, details: nil)) }
      }
    }
  }

  private static func failure(_ text: String) -> NSError {
    NSError(domain: "NLPrayerAudio", code: 1, userInfo: [NSLocalizedDescriptionKey: text])
  }

  func prepare(source: URL, support: URL, isDefault: Bool) throws -> [String: String] {
    let fm = FileManager.default
    let size = (try source.resourceValues(forKeys: [.fileSizeKey])).fileSize ?? 0
    guard size > 0 && size <= 50 * 1024 * 1024 else { throw Self.failure("Choose audio smaller than 50 MB") }
    guard ["mp3", "m4a", "wav", "caf", "aiff", "aif"].contains(source.pathExtension.lowercased()) else {
      throw Self.failure("iPhone supports MP3, M4A, WAV, CAF and AIFF files here")
    }
    let input = try AVAudioFile(forReading: source)
    let format = input.processingFormat
    let duration = Double(input.length) / format.sampleRate
    guard duration.isFinite && duration > 0 && duration <= 600 && format.channelCount <= 2 else {
      throw Self.failure("Choose playable mono/stereo audio up to 10 minutes")
    }
    let data = try Data(contentsOf: source)
    let token = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    let original = isDefault ? source : support.appendingPathComponent("\(token).\(source.pathExtension.lowercased())")
    if !fm.fileExists(atPath: original.path) { try data.write(to: original, options: .atomic) }
    let library = try fm.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    let sounds = library.appendingPathComponent("Sounds", isDirectory: true)
    try fm.createDirectory(at: sounds, withIntermediateDirectories: true)
    let prefix = isDefault ? "adhan_default" : "adhan_\(token)"
    let short = "\(prefix)_short.wav", full = "\(prefix)_full.wav"
    // Standard notification audio must be strictly less than 30 seconds.
    try convert(input, to: sounds.appendingPathComponent(short), seconds: 29)
    // AlarmKit has a separate sound resource; retain full audio for device tests.
    try convert(input, to: sounds.appendingPathComponent(full), seconds: duration)
    return ["uri": original.absoluteString, "token": token, "path": original.path,
            "iosSound": short, "iosAlarmSound": full]
  }

  private func convert(_ input: AVAudioFile, to output: URL, seconds: Double) throws {
    let fm = FileManager.default
    if fm.fileExists(atPath: output.path) { return }
    let temporary = output.deletingLastPathComponent().appendingPathComponent(UUID().uuidString + ".wav")
    defer { try? fm.removeItem(at: temporary) }
    let format = input.processingFormat
    let settings: [String: Any] = [AVFormatIDKey: kAudioFormatLinearPCM,
      AVSampleRateKey: format.sampleRate, AVNumberOfChannelsKey: format.channelCount,
      AVLinearPCMBitDepthKey: 16, AVLinearPCMIsFloatKey: false,
      AVLinearPCMIsBigEndianKey: false]
    input.framePosition = 0
    var remaining = min(input.length, AVAudioFramePosition(seconds * format.sampleRate))
    guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 8192) else {
      throw Self.failure("Unable to decode audio")
    }
    // End this scope before moving: closing AVAudioFile finalizes its WAV header.
    do {
      let writer = try AVAudioFile(forWriting: temporary, settings: settings,
                                  commonFormat: .pcmFormatFloat32, interleaved: false)
      while remaining > 0 {
        try input.read(into: buffer, frameCount: AVAudioFrameCount(min(remaining, 8192)))
        guard buffer.frameLength > 0 else { break }
        try writer.write(from: buffer)
        remaining -= AVAudioFramePosition(buffer.frameLength)
      }
    }
    try fm.moveItem(at: temporary, to: output)
  }
}

final class NLPrayerAlarmPlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "nl_prayer_times/ios_alarms", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(NLPrayerAlarmPlugin(), channel: channel)
  }
  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "openSettings" {
      if let url = URL(string: UIApplication.openSettingsURLString) {
        UIApplication.shared.open(url, options: [:]) { _ in result(nil) }
      } else { result(nil) }
      return
    }
    #if canImport(AlarmKit)
    if #available(iOS 26.0, *) {
      Task { @MainActor in
        do {
          switch call.method {
          case "status":
            result(["available": true, "authorized": AlarmManager.shared.authorizationState == .authorized])
          case "requestPermission":
            result(try await AlarmManager.shared.requestAuthorization() == .authorized)
          case "cancelPrayerAlarms":
            guard AlarmManager.shared.authorizationState == .authorized else { result(nil); return }
            let owned = Set((0..<7).flatMap { day in (1...5).map { Self.alarmID(day * 10 + $0) } })
            for alarm in try AlarmManager.shared.alarms where owned.contains(alarm.id) {
              try AlarmManager.shared.cancel(id: alarm.id)
            }
            result(nil)
          case "schedule":
            guard AlarmManager.shared.authorizationState == .authorized else {
              throw NSError(domain: "NLPrayerAlarms", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Allow alarms for NL Prayer Times in Settings"])
            }
            let args = call.arguments as? [String: Any] ?? [:]
            guard let id = args["id"] as? Int, let title = args["title"] as? String,
                  let timestamp = args["timestamp"] as? Double,
                  let sound = args["sound"] as? String,
                  sound == (sound as NSString).lastPathComponent else {
              result(FlutterError(code: "BAD_ALARM", message: "Invalid prayer alarm", details: nil)); return
            }
            let date = Date(timeIntervalSince1970: timestamp)
            guard date > Date() else { result(nil); return }
            let stop = AlarmButton(text: "Stop", textColor: .white, systemImageName: "stop.circle")
            let presentation = AlarmPresentation(alert: AlarmPresentation.Alert(
              title: LocalizedStringResource(stringLiteral: title), stopButton: stop))
            let attributes = AlarmAttributes<NLPrayerAlarmMetadata>(
              presentation: presentation, metadata: NLPrayerAlarmMetadata(), tintColor: .blue)
            let config = AlarmManager.AlarmConfiguration<NLPrayerAlarmMetadata>(
              schedule: .fixed(date), attributes: attributes, sound: .named(sound))
            _ = try await AlarmManager.shared.schedule(id: Self.alarmID(id), configuration: config)
            result(nil)
          default: result(FlutterMethodNotImplemented)
          }
        } catch {
          result(FlutterError(code: "IOS_ALARM_FAILED", message: error.localizedDescription, details: nil))
        }
      }
      return
    }
    #endif
    switch call.method {
    case "status": result(["available": false, "authorized": false])
    case "requestPermission": result(false)
    case "cancelPrayerAlarms": result(nil)
    default: result(FlutterMethodNotImplemented)
    }
  }
  private static func alarmID(_ id: Int) -> UUID {
    UUID(uuidString: String(format: "8488CEB2-0E6B-4E48-9F43-%012X", id))!
  }
}

#if canImport(AlarmKit)
@available(iOS 26.0, *)
struct NLPrayerAlarmMetadata: AlarmMetadata {}
#endif
