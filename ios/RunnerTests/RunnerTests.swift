import AVFoundation
import XCTest
@testable import Runner

final class RunnerTests: XCTestCase {
  private var directory: URL!
  override func setUpWithError() throws {
    directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
  }
  override func tearDownWithError() throws {
    try FileManager.default.removeItem(at: directory)
  }

  private func source(seconds: Double) throws -> URL {
    let url = directory.appendingPathComponent("source.wav")
    let format = AVAudioFormat(standardFormatWithSampleRate: 8000, channels: 1)!
    let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 8000)!
    buffer.floatChannelData![0].initialize(repeating: 0, count: 8000)
    do {
      let file = try AVAudioFile(forWriting: url, settings: format.settings)
      var remaining = Int(seconds * 8000)
      while remaining > 0 {
        let count = min(remaining, 8000)
        buffer.frameLength = AVAudioFrameCount(count)
        try file.write(from: buffer)
        remaining -= count
      }
    }
    return url
  }

  func testLongAudioCreatesShortNotificationAndFullAlarmResources() throws {
    let sourceURL = try source(seconds: 45)
    let support = directory.appendingPathComponent("stored")
    try FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
    let imported = try NLPrayerAudioPlugin().prepare(source: sourceURL, support: support, isDefault: false)
    let sounds = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("Sounds")
    let shortURL = sounds.appendingPathComponent(imported["iosSound"]!)
    let fullURL = sounds.appendingPathComponent(imported["iosAlarmSound"]!)
    defer { try? FileManager.default.removeItem(at: shortURL); try? FileManager.default.removeItem(at: fullURL) }
    let short = try AVAudioFile(forReading: shortURL)
    let full = try AVAudioFile(forReading: fullURL)
    XCTAssertEqual(Double(short.length) / short.processingFormat.sampleRate, 29, accuracy: 0.01)
    XCTAssertLessThan(Double(short.length) / short.processingFormat.sampleRate, 30)
    XCTAssertEqual(Double(full.length) / full.processingFormat.sampleRate, 45, accuracy: 0.01)
    XCTAssertEqual(short.fileFormat.settings[AVLinearPCMBitDepthKey] as? Int, 16)
    XCTAssertTrue(FileManager.default.contentsEqual(atPath: sourceURL.path, andPath: imported["path"]!))
    XCTAssertNotEqual(sourceURL.path, imported["path"])
    XCTAssertEqual(imported["token"]?.count, 64)
    // Importing the same audio reuses playable, finalized files.
    let repeated = try NLPrayerAudioPlugin().prepare(source: sourceURL, support: support, isDefault: false)
    XCTAssertEqual(imported, repeated)
  }

  func testUnreadableAudioDoesNotProduceASelection() throws {
    let url = directory.appendingPathComponent("invalid.mp3")
    try Data("This is not an audio file".utf8).write(to: url)
    XCTAssertThrowsError(try NLPrayerAudioPlugin().prepare(source: url, support: directory, isDefault: false))
  }

  func testExcessiveDurationIsRejectedBeforeConversion() throws {
    let url = try source(seconds: 601)
    XCTAssertThrowsError(try NLPrayerAudioPlugin().prepare(source: url, support: directory, isDefault: false))
  }
}
