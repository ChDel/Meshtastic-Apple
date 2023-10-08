//
//  BatteryLevel.swift
//  Meshtastic
//
//  Copyright Garth Vander Houwen 3/24/23.
//
import SwiftUI

struct BatteryIcon: View {
	var batteryLevel: Int32?
	var font: Font
	var color: Color

	var body: some View {

		if batteryLevel == 100 {

			Image(systemName: "battery.100.bolt")
				.font(font)
				.foregroundColor(color)
				.symbolRenderingMode(.hierarchical)
		} else if batteryLevel! < 100 && batteryLevel! > 74 {

			Image(systemName: "battery.75")
				.font(font)
				.foregroundColor(color)
				.symbolRenderingMode(.hierarchical)
		} else if batteryLevel! < 75 && batteryLevel! > 49 {

			Image(systemName: "battery.50")
				.font(font)
				.foregroundColor(color)
				.symbolRenderingMode(.hierarchical)
		} else if batteryLevel! < 50 && batteryLevel! > 14 {

			Image(systemName: "battery.25")
				.font(font)
				.foregroundColor(color)
				.symbolRenderingMode(.hierarchical)
		} else if batteryLevel! < 15 && batteryLevel! > 0 {

			Image(systemName: "battery.0")
				.font(font)
				.foregroundColor(color)
				.symbolRenderingMode(.hierarchical)
		} else if batteryLevel! == 0 {
			Image(systemName: "battery.0")
				.font(font)
				.foregroundColor(.red)
				.symbolRenderingMode(.hierarchical)
		} else if batteryLevel! > 100 {
			Image(systemName: "powerplug")
				.font(font)
				.foregroundColor(color)
				.symbolRenderingMode(.hierarchical)
		}
	}
}

struct BatteryIcon_Previews: PreviewProvider {
	static var previews: some View {
		BatteryIcon(batteryLevel: 111, font: .title2, color: Color.accentColor)
			.previewLayout(.fixed(width: 75, height: 75))
		BatteryIcon(batteryLevel: 100, font: .title2, color: Color.accentColor)
			.previewLayout(.fixed(width: 75, height: 75))
		BatteryIcon(batteryLevel: 99, font: .title2, color: Color.accentColor)
			.previewLayout(.fixed(width: 75, height: 75))
		BatteryIcon(batteryLevel: 74, font: .title2, color: Color.accentColor)
			.previewLayout(.fixed(width: 75, height: 75))
		BatteryIcon(batteryLevel: 49, font: .title2, color: Color.accentColor)
			.previewLayout(.fixed(width: 75, height: 75))
		BatteryIcon(batteryLevel: 14, font: .title2, color: Color.accentColor)
			.previewLayout(.fixed(width: 75, height: 75))
	}
}
