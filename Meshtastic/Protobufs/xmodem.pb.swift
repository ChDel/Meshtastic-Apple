// DO NOT EDIT.
// swift-format-ignore-file
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: xmodem.proto
//
// For information on using the generated types, please see the documentation:
//   https://github.com/apple/swift-protobuf/

import Foundation
import SwiftProtobuf

// If the compiler emits an error on this type, it is because this file
// was generated by a version of the `protoc` Swift plug-in that is
// incompatible with the version of SwiftProtobuf to which you are linking.
// Please ensure that you are building against the same version of the API
// that was used to generate this file.
fileprivate struct _GeneratedWithProtocGenSwiftVersion: SwiftProtobuf.ProtobufAPIVersionCheck {
  struct _2: SwiftProtobuf.ProtobufAPIVersion_2 {}
  typealias Version = _2
}

struct XModem {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var control: XModem.Control = .nul

  var seq: UInt32 = 0

  var crc16: UInt32 = 0

  var buffer: Data = Data()

  var unknownFields = SwiftProtobuf.UnknownStorage()

  enum Control: SwiftProtobuf.Enum {
    typealias RawValue = Int
    case nul // = 0
    case soh // = 1
    case stx // = 2
    case eot // = 4
    case ack // = 6
    case nak // = 21
    case can // = 24
    case ctrlz // = 26
    case UNRECOGNIZED(Int)

    init() {
      self = .nul
    }

    init?(rawValue: Int) {
      switch rawValue {
      case 0: self = .nul
      case 1: self = .soh
      case 2: self = .stx
      case 4: self = .eot
      case 6: self = .ack
      case 21: self = .nak
      case 24: self = .can
      case 26: self = .ctrlz
      default: self = .UNRECOGNIZED(rawValue)
      }
    }

    var rawValue: Int {
      switch self {
      case .nul: return 0
      case .soh: return 1
      case .stx: return 2
      case .eot: return 4
      case .ack: return 6
      case .nak: return 21
      case .can: return 24
      case .ctrlz: return 26
      case .UNRECOGNIZED(let i): return i
      }
    }

  }

  init() {}
}

#if swift(>=4.2)

extension XModem.Control: CaseIterable {
  // The compiler won't synthesize support with the UNRECOGNIZED case.
  static var allCases: [XModem.Control] = [
    .nul,
    .soh,
    .stx,
    .eot,
    .ack,
    .nak,
    .can,
    .ctrlz,
  ]
}

#endif  // swift(>=4.2)

#if swift(>=5.5) && canImport(_Concurrency)
extension XModem: @unchecked Sendable {}
extension XModem.Control: @unchecked Sendable {}
#endif  // swift(>=5.5) && canImport(_Concurrency)

// MARK: - Code below here is support for the SwiftProtobuf runtime.

extension XModem: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = "XModem"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "control"),
    2: .same(proto: "seq"),
    3: .same(proto: "crc16"),
    4: .same(proto: "buffer"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularEnumField(value: &self.control) }()
      case 2: try { try decoder.decodeSingularUInt32Field(value: &self.seq) }()
      case 3: try { try decoder.decodeSingularUInt32Field(value: &self.crc16) }()
      case 4: try { try decoder.decodeSingularBytesField(value: &self.buffer) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if self.control != .nul {
      try visitor.visitSingularEnumField(value: self.control, fieldNumber: 1)
    }
    if self.seq != 0 {
      try visitor.visitSingularUInt32Field(value: self.seq, fieldNumber: 2)
    }
    if self.crc16 != 0 {
      try visitor.visitSingularUInt32Field(value: self.crc16, fieldNumber: 3)
    }
    if !self.buffer.isEmpty {
      try visitor.visitSingularBytesField(value: self.buffer, fieldNumber: 4)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: XModem, rhs: XModem) -> Bool {
    if lhs.control != rhs.control {return false}
    if lhs.seq != rhs.seq {return false}
    if lhs.crc16 != rhs.crc16 {return false}
    if lhs.buffer != rhs.buffer {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension XModem.Control: SwiftProtobuf._ProtoNameProviding {
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    0: .same(proto: "NUL"),
    1: .same(proto: "SOH"),
    2: .same(proto: "STX"),
    4: .same(proto: "EOT"),
    6: .same(proto: "ACK"),
    21: .same(proto: "NAK"),
    24: .same(proto: "CAN"),
    26: .same(proto: "CTRLZ"),
  ]
}
