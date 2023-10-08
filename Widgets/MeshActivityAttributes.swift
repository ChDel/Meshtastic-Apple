//
//  MeshActivityAttributes.swift
//  Meshtastic
//
//  Created by Garth Vander Houwen on 3/1/23.
//

#if canImport(ActivityKit)

import ActivityKit
import WidgetKit
import SwiftUI

struct MeshActivityAttributes: ActivityAttributes {
	public typealias MeshActivityStatus = ContentState
	public struct ContentState: Codable, Hashable {
		// Dynamic stateful properties about your activity go here!
		var timerRange: ClosedRange<Date>
		var connected: Bool
		var channelUtilization: Float
		var airtime: Float
		var batteryLevel: UInt32
		var nodes: Int
		var nodesOnline: Int
	}

	// Fixed non-changing properties about your activity go here!
	var nodeNum: Int
	var name: String
}
#endif
