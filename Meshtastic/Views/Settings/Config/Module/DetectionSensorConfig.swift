//
//  DetectionSensorModule.swift
//  Meshtastic
//
//  Copyright(c) Garth Vander Houwen 8/16/23.
//
import SwiftUI

struct DetectionSensorConfig: View {

	@Environment(\.managedObjectContext) var context
	@EnvironmentObject var bleManager: BLEManager
	@Environment(\.dismiss) private var goBack
	var node: NodeInfoEntity?
	@State private var isPresentingSaveConfirm: Bool = false
	@State var hasChanges: Bool = false
	@State var enabled = false
	/// DetectionSensorModule will sends a bell character with the messages.
	@State var sendBell: Bool = false
	@State var name: String = ""
	@State var detectionTriggeredHigh: Bool = true
	@State var usePullup: Bool = false
	@State var minimumBroadcastSecs = 0
	@State var stateBroadcastSecs = 0
	@State var monitorPin = 0

	var body: some View {

		Form {
			if node != nil && node?.metadata == nil && node?.num ?? 0 != bleManager.connectedPeripheral?.num ?? 0 {
				Text("There has been no response to a request for device metadata over the admin channel for this node.")
					.font(.callout)
					.foregroundColor(.orange)

			} else if node != nil && node?.num ?? 0 != bleManager.connectedPeripheral?.num ?? 0 {
				// Let users know what is going on if they are using remote admin and don't have the config yet
				if node?.detectionSensorConfig == nil {
					Text("Detection Sensor config data was requested over the admin channel but no response has been returned from the remote node. You can check the status of admin message requests in the admin message log.")
						.font(.callout)
						.foregroundColor(.orange)
				} else {
					Text("Remote administration for: \(node?.user?.longName ?? "Unknown")")
						.font(.title3)
						.onAppear {
							setDetectionSensorValues()
						}
				}
			} else if node != nil && node?.num ?? 0 == bleManager.connectedPeripheral?.num ?? 0 {
				Text("Configuration for: \(node?.user?.longName ?? "Unknown")")
					.font(.title3)
			} else {
				Text("Please connect to a radio to configure settings.")
					.font(.callout)
					.foregroundColor(.orange)
			}
			Section(header: Text("options")) {
				Toggle(isOn: $enabled) {
					Label("enabled", systemImage: "dot.radiowaves.right")
				}
				Toggle(isOn: $sendBell) {
					Label("Send Bell", systemImage: "bell")
				}
				TextField("Friendly name (sent for detection alerts text messages)", text: $name, axis: .vertical)
					.foregroundColor(.gray)
					.autocapitalization(.none)
					.disableAutocorrection(true)
					.onChange(of: name, perform: { _ in

						let totalBytes = name.utf8.count
						// Only mess with the value if it is too big
						if totalBytes > 20 {

							let firstNBytes = Data(name.utf8.prefix(20))
							if let maxBytesString = String(data: firstNBytes, encoding: String.Encoding.utf8) {
								// Set the shortName back to the last place where it was the right size
								name = maxBytesString
							}
						}
					})
					.foregroundColor(.gray)
			}
			Section(header: Text("Sensor option")) {
				Picker("GPIO Pin to monitor", selection: $monitorPin) {
					ForEach(0..<46) {
						if $0 == 0 {
							Text("unset")
						} else {
							Text("Pin \($0)")
						}
					}
				}
				.pickerStyle(DefaultPickerStyle())
				Toggle(isOn: $detectionTriggeredHigh) {
					Label("Detection trigger High", systemImage: "dial.high")
				}
				.toggleStyle(SwitchToggleStyle(tint: .accentColor))

				Toggle(isOn: $usePullup) {
					Label("Uses pullup resistor", systemImage: "arrow.up.to.line")
				}
				.toggleStyle(SwitchToggleStyle(tint: .accentColor))
			}
			Section(header: Text("update.interval")) {
				Picker("Minimum time between detection broadcasts", selection: $minimumBroadcastSecs) {
					ForEach(UpdateIntervals.allCases) { ui in
						Text(ui.description).tag(ui.rawValue)
					}
				}
				.pickerStyle(DefaultPickerStyle())
				Text("Mininum time between detection broadcasts. Default is 45 seconds.")
					.font(.caption)
				Picker("State Broadcast Interval", selection: $stateBroadcastSecs) {
					Text("Never").tag(0)
					ForEach(UpdateIntervals.allCases) { ui in
						Text(ui.description).tag(ui.rawValue)
					}
				}
				.pickerStyle(DefaultPickerStyle())
				Text("How often to send detection sensor state to mesh regardless of detection. Default is Never.")
					.font(.caption)
			}
		}
		.scrollDismissesKeyboard(.interactively)
		.disabled(self.bleManager.connectedPeripheral == nil || node?.detectionSensorConfig == nil)

		Button {
			isPresentingSaveConfirm = true
		} label: {
			Label("save", systemImage: "square.and.arrow.down")
		}
		.disabled(bleManager.connectedPeripheral == nil || !hasChanges)
		.buttonStyle(.bordered)
		.buttonBorderShape(.capsule)
		.controlSize(.large)
		.padding()
		.confirmationDialog(
			"are.you.sure",
			isPresented: $isPresentingSaveConfirm,
			titleVisibility: .visible
		) {
			let connectedNode = getNodeInfo(id: bleManager.connectedPeripheral?.num ?? -1, context: context)
			if connectedNode != nil {
				let nodeName = node?.user?.longName ?? "unknown".localized
				let buttonText = String.localizedStringWithFormat("save.config %@".localized, nodeName)
				Button(buttonText) {
					var dsc = ModuleConfig.DetectionSensorConfig()
					dsc.enabled = self.enabled
					dsc.sendBell = self.sendBell
					dsc.name = self.name
					dsc.monitorPin = UInt32(self.monitorPin)
					dsc.detectionTriggeredHigh = self.detectionTriggeredHigh
					dsc.usePullup = self.usePullup
					dsc.minimumBroadcastSecs = UInt32(self.minimumBroadcastSecs)
					dsc.stateBroadcastSecs = UInt32(self.stateBroadcastSecs)
					let adminMessageId = bleManager.saveDetectionSensorModuleConfig(config: dsc, fromUser: connectedNode!.user!, toUser: node!.user!, adminIndex: connectedNode?.myInfo?.adminIndex ?? 0)
					if adminMessageId > 0 {
						// Should show a saved successfully alert once I know that to be true
						// for now just disable the button after a successful save
						hasChanges = false
						goBack()
					}
				}
			}
		}
		message: {
			Text("config.save.confirm")
		}
		.navigationTitle("detection.sensor.config")
		.navigationBarItems(trailing:
			ZStack {
				ConnectedDevice(bluetoothOn: bleManager.isSwitchedOn, deviceConnected: bleManager.connectedPeripheral != nil, name: (bleManager.connectedPeripheral != nil) ? bleManager.connectedPeripheral.shortName : "?")
		})
		.onAppear {
			self.bleManager.context = context
			setDetectionSensorValues()

			// Need to request a Detection Sensor Module Config from the remote node before allowing changes
			if bleManager.connectedPeripheral != nil && node?.detectionSensorConfig == nil {
				print("empty detection sensor module config")
				let connectedNode = getNodeInfo(id: bleManager.connectedPeripheral.num, context: context)
				if node != nil && connectedNode != nil {
					_ = bleManager.requestDetectionSensorModuleConfig(fromUser: connectedNode!.user!, toUser: node!.user!, adminIndex: connectedNode?.myInfo?.adminIndex ?? 0)
				}
			}
		}
		.onChange(of: enabled) { newEnabled in
			if node != nil && node?.detectionSensorConfig != nil {
				if newEnabled != node!.detectionSensorConfig!.enabled { hasChanges = true }
			}
		}
		.onChange(of: sendBell) { newSendBell in
			if node != nil && node?.detectionSensorConfig != nil {
				if newSendBell != node!.detectionSensorConfig!.sendBell { hasChanges = true }
			}
		}
		.onChange(of: detectionTriggeredHigh) { newDetectionTriggeredHigh in
			if node != nil && node?.detectionSensorConfig != nil {
				if newDetectionTriggeredHigh != node!.detectionSensorConfig!.detectionTriggeredHigh { hasChanges = true }
			}
		}
		.onChange(of: usePullup) { newUsePullup in
			if node != nil && node?.detectionSensorConfig != nil {
				if newUsePullup != node!.detectionSensorConfig!.usePullup { hasChanges = true }
			}
		}
		.onChange(of: name) { newName in
			if node != nil && node?.detectionSensorConfig != nil {
				if newName != node!.detectionSensorConfig!.name { hasChanges = true }
			}
		}
		.onChange(of: monitorPin) { newMonitorPin in
			if node != nil && node?.detectionSensorConfig != nil {
				if newMonitorPin != node!.detectionSensorConfig!.monitorPin { hasChanges = true }
			}
		}
		.onChange(of: minimumBroadcastSecs) { newMinimumBroadcastSecs in
			if node != nil && node?.detectionSensorConfig != nil {
				if newMinimumBroadcastSecs != node!.detectionSensorConfig!.minimumBroadcastSecs { hasChanges = true }
			}
		}
		.onChange(of: stateBroadcastSecs) { newStateBroadcastSecs in
			if node != nil && node?.detectionSensorConfig != nil {
				if newStateBroadcastSecs != node!.detectionSensorConfig!.stateBroadcastSecs { hasChanges = true }
			}
		}
	}
	func setDetectionSensorValues() {
		self.enabled = (node?.detectionSensorConfig?.enabled ?? false)
		self.sendBell = (node?.detectionSensorConfig?.sendBell ?? false)
		self.name = (node?.detectionSensorConfig?.name ?? "")
		self.monitorPin = Int(node?.detectionSensorConfig?.monitorPin ?? 0)
		self.usePullup = (node?.detectionSensorConfig?.usePullup ?? false)
		self.detectionTriggeredHigh = (node?.detectionSensorConfig?.detectionTriggeredHigh ?? true)
		self.minimumBroadcastSecs = Int(node?.detectionSensorConfig?.minimumBroadcastSecs ?? 45)
		self.stateBroadcastSecs = Int(node?.detectionSensorConfig?.stateBroadcastSecs ?? 0)

		self.hasChanges = false
	}
}
