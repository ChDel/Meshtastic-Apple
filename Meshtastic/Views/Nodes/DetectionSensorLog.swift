//
//  DetectionSensorLog.swift
//  Meshtastic
//
//  Created by Ben on 8/22/23.
//

import SwiftUI
import Charts

struct DetectionSensorLog: View {
	@Environment(\.managedObjectContext) var context
	@EnvironmentObject var bleManager: BLEManager
	@State private var isPresentingClearLogConfirm: Bool = false
	@State var isExporting = false
	@State var exportString = ""
	@ObservedObject var node: NodeInfoEntity

	var body: some View {
		let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: Date())
		let detections = getDetectionSensorMessages(nodeNum: node.num, context: context)
		let chartData = detections
			.filter { $0.timestamp >= oneDayAgo! }
			.sorted { $0.timestamp < $1.timestamp }

		VStack {
			if chartData.count > 0 {
				GroupBox(label: Label("\(detections.count) Total Detection Events", systemImage: "sensor")) {
					Chart {
						ForEach(chartData, id: \.self) { point in
							Plot {
								BarMark(
									x: .value("x", point.timestamp),
									y: .value("y", 1)
								)
							}
							.accessibilityLabel("Bar Series")
							.accessibilityValue("X: \(point.timestamp), Y: \(1)")
							.interpolationMethod(.cardinal)
							.foregroundStyle(
								.linearGradient(
									colors: [.green, .yellow, .orange, .red],
									startPoint: .bottom,
									endPoint: .top
								)
							)
							.alignsMarkStylesWithPlotArea()
						}
					}
					.chartXAxis(content: {
						AxisMarks(position: .top)
//						AxisMarks(position: .top, values: .stride(by: .hour)) { date in
//							AxisValueLabel(format: .dateTime.hour())
//						}
					})
					.chartXAxis(.automatic)
					.chartYScale(domain: 0...20)
					.chartForegroundStyleScale([
						"Detection events": .green
					])
					.chartLegend(position: .automatic, alignment: .bottom)
				}
				.frame(minHeight: 250)
			}
			let localeDateFormat = DateFormatter.dateFormat(fromTemplate: "yyMMddjmma", options: 0, locale: Locale.current)
			let dateFormatString = (localeDateFormat ?? "MM/dd/YY j:mma").replacingOccurrences(of: ",", with: "")
			if UIDevice.current.userInterfaceIdiom == .pad || UIDevice.current.userInterfaceIdiom == .mac {
				// Add a table for mac and ipad
				Table(detections) {
					TableColumn("Detection event") { d in
						Text(d.messagePayload ?? "Detected")
					}

					TableColumn("timestamp") { d in
						Text(d.timestamp.formattedDate(format: dateFormatString))
					}
					.width(min: 180)
				}
			} else {
				ScrollView {
					let columns = [
						GridItem(),
						GridItem()
					]
					LazyVGrid(columns: columns, alignment: .leading, spacing: 1) {
						GridRow {
							Text("Detection")
								.font(.caption)
								.fontWeight(.bold)
							Text("timestamp")
								.font(.caption)
								.fontWeight(.bold)
						}
						ForEach(detections) { d in
							GridRow {
								Text(d.messagePayload ?? "Detected")
								Text(d.timestamp.formattedDate(format: dateFormatString))
									.font(.caption)
							}
						}
					}
					.padding(.leading, 15)
					.padding(.trailing, 5)
				}
			}
		}
		HStack {
			Button {
				exportString = detectionsToCsv(detections: chartData)
				isExporting = true
			} label: {
				Label("save", systemImage: "square.and.arrow.down")
			}
			.buttonStyle(.bordered)
			.buttonBorderShape(.capsule)
			.controlSize(.large)
			.padding(.bottom)
			.padding(.trailing)
		}
		.navigationTitle("detection.sensor.log")
		.navigationBarTitleDisplayMode(.inline)
		.navigationBarItems(trailing:
			ZStack {
				ConnectedDevice(bluetoothOn: bleManager.isSwitchedOn, deviceConnected: bleManager.connectedPeripheral != nil, name: (bleManager.connectedPeripheral != nil) ? bleManager.connectedPeripheral.shortName : "?")
		})
		.onAppear {
			if self.bleManager.context == nil {
				self.bleManager.context = context
			}
		}
		.fileExporter(
			isPresented: $isExporting,
			document: CsvDocument(emptyCsv: exportString),
			contentType: .commaSeparatedText,
			defaultFilename: String("\(node.user?.longName ?? "Node") \("detection.sensor.log".localized)"),
			onCompletion: { result in
				if case .success = result {
					print("Detections metrics log download succeeded.")
					self.isExporting = false
				} else {
					print("Detections log download failed: \(result).")
				}
			}
		)
	}
}
