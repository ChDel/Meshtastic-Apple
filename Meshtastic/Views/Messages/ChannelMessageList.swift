//
//  UserMessageList.swift
//  MeshtasticApple
//
//  Created by Garth Vander Houwen on 12/24/21.
//

import SwiftUI
import CoreData

struct ChannelMessageList: View {

	@Environment(\.managedObjectContext) var context
	@EnvironmentObject var bleManager: BLEManager
	@EnvironmentObject var userSettings: UserSettings

	enum Field: Hashable {
		case messageText
	}

	// Keyboard State
	@State var typingMessage: String = ""
	@State private var totalBytes = 0
	var maxbytes = 228
	@FocusState var focusedField: Field?

	@ObservedObject var channel: ChannelEntity
	@State var showDeleteMessageAlert = false
	@State private var deleteMessageId: Int64 = 0
	@State private var replyMessageId: Int64 = 0
	@State private var sendPositionWithMessage: Bool = false

	var body: some View {
		NavigationStack {
			let localeDateFormat = DateFormatter.dateFormat(fromTemplate: "yyMMddjmmssa", options: 0, locale: Locale.current)
			let dateFormatString = (localeDateFormat ?? "MM/dd/YY j:mm:ss a")
			ScrollViewReader { scrollView in
				ScrollView {
					LazyVStack {
						ForEach( channel.allPrivateMessages ) { (message: MessageEntity) in
							let currentUser: Bool = (bleManager.connectedPeripheral?.num ?? -1 == message.fromUser?.num ? true : false)
							if message.replyID > 0 {
								let messageReply = channel.allPrivateMessages.first(where: { $0.messageId == message.replyID })
								HStack {
									Text(messageReply?.messagePayload ?? "EMPTY MESSAGE").foregroundColor(.accentColor).font(.caption2)
										.padding(10)
										.overlay(
											RoundedRectangle(cornerRadius: 18)
												.stroke(Color.blue, lineWidth: 0.5)
										)
									Image(systemName: "arrowshape.turn.up.left.fill")
										.symbolRenderingMode(.hierarchical)
										.imageScale(.large).foregroundColor(.accentColor)
										.padding(.trailing)
								}
							}
							HStack(alignment: .top) {
								if currentUser { Spacer(minLength: 50) }
								if !currentUser {
									CircleText(text: message.fromUser?.shortName ?? "????", color: Color(UIColor(hex: UInt32(message.fromUser?.num ?? 0))), circleSize: 44, fontSize: 14, textColor: UIColor(hex: UInt32(message.fromUser?.num ?? 0)).isLight() ? .black : .white)
										.padding(.all, 5)
										.offset(y: -5)
								}
								VStack(alignment: currentUser ? .trailing : .leading) {
									let markdownText: LocalizedStringKey =  LocalizedStringKey.init(message.messagePayloadMarkdown ?? (message.messagePayload ?? "EMPTY MESSAGE"))
									let linkBlue = Color(red: 0.4627, green: 0.8392, blue: 1) /* #76d6ff */
									Text(markdownText)
										.tint(linkBlue)
										.padding(10)
										.foregroundColor(.white)
										.background(currentUser ? .accentColor : Color(.gray))
										.cornerRadius(15)
										.contextMenu {
											VStack {
												Text("channel")+Text(": \(message.channel)")
											}
											Menu("tapback") {
												ForEach(Tapbacks.allCases) { tb in
													Button(action: {
														if bleManager.sendMessage(message: tb.emojiString, toUserNum: 0, channel: channel.index, isEmoji: true, replyID: message.messageId) {
															print("Sent \(tb.emojiString) Tapback")
															self.context.refresh(channel, mergeChanges: true)
														} else { print("\(tb.emojiString) Tapback Failed") }

													}) {
														Text(tb.description)
														let image = tb.emojiString.image()
														Image(uiImage: image!)
													}
												}
											}
											Button(action: {
												self.replyMessageId = message.messageId
												self.focusedField = .messageText
												print("I want to reply to \(message.messageId)")
											}) {
												Text("reply")
												Image(systemName: "arrowshape.turn.up.left.2.fill")
											}
											Button(action: {
												UIPasteboard.general.string = message.messagePayload
											}) {
												Text("copy")
												Image(systemName: "doc.on.doc")
											}
											Menu("message.details") {
												VStack {
													let messageDate = Date(timeIntervalSince1970: TimeInterval(message.messageTimestamp))
													Text(" \(messageDate.formattedDate(format: dateFormatString))").foregroundColor(.gray)
												}
												if !currentUser {
													VStack {
														Text("SNR \(String(format: "%.2f", message.snr)) dB")
													}
												}
												if currentUser && message.receivedACK {
													VStack {
														Text("received.ack")+Text(" \(message.receivedACK ? "✔️" : "")")
													}
												} else if currentUser && message.ackError == 0 {
													// Empty Error
													Text("waiting")
												} else if currentUser && message.ackError > 0 {
													let ackErrorVal = RoutingError(rawValue: Int(message.ackError))
													Text("\(ackErrorVal?.display ?? "Empty Ack Error")").fixedSize(horizontal: false, vertical: true)
												}
												if currentUser {
													VStack {
														let ackDate = Date(timeIntervalSince1970: TimeInterval(message.ackTimestamp))
														let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: Date())
														if ackDate >= sixMonthsAgo! {
															Text("Ack Time: \(ackDate.formattedDate(format: "h:mm:ss a"))").foregroundColor(.gray)
														} else {
															Text("unknown.age").foregroundColor(.gray)
														}
													}
												}
												if message.ackSNR != 0 {
													VStack {
														Text("Ack SNR: \(String(format: "%.2f", message.ackSNR)) dB")
															.foregroundColor(.gray)
													}
												}
											}
											Divider()
											Button(role: .destructive, action: {
												self.showDeleteMessageAlert = true
												self.deleteMessageId = message.messageId
												print(deleteMessageId)
											}) {
												Text("delete")
												Image(systemName: "trash")
											}
										}
									let tapbacks = message.value(forKey: "tapbacks") as? [MessageEntity] ?? []
									if tapbacks.count > 0 {
										VStack(alignment: .trailing) {
											HStack {
												ForEach( tapbacks ) { (tapback: MessageEntity) in
													VStack {
														let image = tapback.messagePayload!.image(fontSize: 20)
														Image(uiImage: image!).font(.caption)
														Text("\(tapback.fromUser?.shortName ?? "????")")
															.font(.caption2)
															.foregroundColor(.gray)
															.fixedSize()
															.padding(.bottom, 1)
													}
												}
											}
											.padding(10)
											.overlay(
												RoundedRectangle(cornerRadius: 18)
													.stroke(Color.gray, lineWidth: 1)
											)
										}
									}
									HStack {
										if currentUser && message.receivedACK {
											// Ack Received
											Text("Acknowledged").font(.caption2).foregroundColor(.gray)
										} else if currentUser && message.ackError == 0 {
											// Empty Error
											Text("Waiting to be acknowledged. . .").font(.caption2).foregroundColor(.orange)
										} else if currentUser && message.ackError > 0 {
											let ackErrorVal = RoutingError(rawValue: Int(message.ackError))
											Text("\(ackErrorVal?.display ?? "Empty Ack Error")").fixedSize(horizontal: false, vertical: true)
												.font(.caption2).foregroundColor(.red)
										}
									}
								}
								.padding(.bottom)
								.id(channel.allPrivateMessages.firstIndex(of: message))
								if !currentUser {
									Spacer(minLength: 50)
								}
							}
							.padding([.leading, .trailing])
							.frame(maxWidth: .infinity)
							.id(message.messageId)
							.alert(isPresented: $showDeleteMessageAlert) {
								Alert(title: Text("Are you sure you want to delete this message?"), message: Text("This action is permanent."), primaryButton: .destructive(Text("Delete")) {
									print("OK button tapped")
									if deleteMessageId > 0 {
										let message = channel.allPrivateMessages.first(where: { $0.messageId == deleteMessageId })
										context.delete(message!)
										do {
											try context.save()
											deleteMessageId = 0
										} catch {
											print("Failed to delete message \(deleteMessageId)")
										}
									}
								}, secondaryButton: .cancel())
							}
						}
					}
				}
				.padding([.top])
				.scrollDismissesKeyboard(.immediately)
				.onAppear(perform: {
					self.bleManager.context = context
					if channel.allPrivateMessages.count > 0 {
						scrollView.scrollTo(channel.allPrivateMessages.last!.messageId)
					}
				})
				.onChange(of: channel.allPrivateMessages, perform: { _ in
					if channel.allPrivateMessages.count > 0 {
						scrollView.scrollTo(channel.allPrivateMessages.last!.messageId)
					}
				})
			}
			#if targetEnvironment(macCatalyst)
			HStack {
				Spacer()
				
				Button {
					let bell = "🔔 Alert Bell Character! \u{7}"
					print(bell)
					typingMessage += bell

				} label: {
					Text("Alert Bell")
					Image(systemName: "bell.fill")
						.symbolRenderingMode(.hierarchical)
						.imageScale(.large).foregroundColor(.accentColor)
				}
				Spacer()
				Button {
					let userLongName = bleManager.connectedPeripheral != nil ? bleManager.connectedPeripheral.longName : "Unknown"
					sendPositionWithMessage = true
					if userSettings.meshtasticUsername.count > 0 {

						typingMessage +=  "📍 " + userSettings.meshtasticUsername + " has shared their position with you from node " + userLongName

					} else {

						typingMessage +=  "📍 " + userLongName + " has shared their position with you."
					}

				} label: {
					Text("share.position")
					Image(systemName: "mappin.and.ellipse")
						.symbolRenderingMode(.hierarchical)
						.imageScale(.large).foregroundColor(.accentColor)
				}
				ProgressView("\(NSLocalizedString("bytes", comment: "")): \(totalBytes) / \(maxbytes)", value: Double(totalBytes), total: Double(maxbytes))
					.frame(width: 130)
					.padding(5)
					.font(.subheadline)
					.accentColor(.accentColor)
					.padding(.trailing)
			}
			#endif
			HStack(alignment: .top) {

				ZStack {
					let kbType = UIKeyboardType(rawValue: UserDefaults.standard.object(forKey: "keyboardType") as? Int ?? 0)
					TextField("message", text: $typingMessage, axis: .vertical)
						.onChange(of: typingMessage, perform: { value in
							totalBytes = value.utf8.count
							// Only mess with the value if it is too big
							if totalBytes > maxbytes {
								let firstNBytes = Data(typingMessage.utf8.prefix(maxbytes))
								if let maxBytesString = String(data: firstNBytes, encoding: String.Encoding.utf8) {
									// Set the message back to the last place where it was the right size
									typingMessage = maxBytesString
								} else {
									print("not a valid UTF-8 sequence")
								}
							}
						})
						.keyboardType(kbType!)
						.toolbar {
							ToolbarItemGroup(placement: .keyboard) {
								Button("dismiss.keyboard") {
									focusedField = nil
								}
								.font(.subheadline)
								Spacer()
								Button {
									let bell = "🔔 Alert Bell Character! \u{7}"
									print(bell)
									typingMessage += bell

								} label: {
									Text("Alert")
									Image(systemName: "bell.fill")
										.symbolRenderingMode(.hierarchical)
										.imageScale(.large).foregroundColor(.accentColor)
								}
								Spacer()
								Button {
									let userLongName = bleManager.connectedPeripheral != nil ? bleManager.connectedPeripheral.longName : "Unknown"
									sendPositionWithMessage = true
									if userSettings.meshtasticUsername.count > 0 {

										typingMessage =  "📍 " + userSettings.meshtasticUsername + " has shared their position with you from node " + userLongName

									} else {

										typingMessage =  "📍 " + userLongName + " has shared their position with you."
									}

								} label: {
									Image(systemName: "mappin.and.ellipse")
										.symbolRenderingMode(.hierarchical)
										.imageScale(.large).foregroundColor(.accentColor)
								}

								ProgressView("\(NSLocalizedString("bytes", comment: "")): \(totalBytes) / \(maxbytes)", value: Double(totalBytes), total: Double(maxbytes))
									.frame(width: 130)
									.padding(5)
									.font(.subheadline)
									.accentColor(.accentColor)
							}
						}
						.padding(.horizontal, 8)
						.focused($focusedField, equals: .messageText)
						.multilineTextAlignment(.leading)
						.frame(minHeight: 50)
						.keyboardShortcut(.defaultAction)
						.onSubmit {
						#if targetEnvironment(macCatalyst)
							if bleManager.sendMessage(message: typingMessage, toUserNum: 0, channel: channel.index, isEmoji: false, replyID: replyMessageId) {
								typingMessage = ""
								focusedField = nil
								replyMessageId = 0
								if sendPositionWithMessage {
									if bleManager.sendPosition(destNum: Int64(channel.index), wantResponse: false, smartPosition: false) {
										print("Location Sent")
									}
								}
							}
						#endif
						}
					Text(typingMessage).opacity(0).padding(.all, 0)
				}
				.overlay(RoundedRectangle(cornerRadius: 20).stroke(.tertiary, lineWidth: 1))
				.padding(.bottom, 15)
				Button(action: {
					if bleManager.sendMessage(message: typingMessage, toUserNum: 0, channel: channel.index, isEmoji: false, replyID: replyMessageId) {
						typingMessage = ""
						focusedField = nil
						replyMessageId = 0
						if sendPositionWithMessage {
							if bleManager.sendPosition(destNum: Int64(channel.index), wantResponse: false, smartPosition: false) {
								print("Location Sent")
							}
						}
					}
				}) {
					Image(systemName: "arrow.up.circle.fill").font(.largeTitle).foregroundColor(.accentColor)
				}
			}
			.padding(.all, 15)
		}
		.navigationBarTitleDisplayMode(.inline)
		.toolbar {
			ToolbarItem(placement: .principal) {
				HStack {
					CircleText(text: String(channel.index), color: .accentColor, circleSize: 44, fontSize: 30).fixedSize()
					Text(String(channel.name ?? NSLocalizedString("unknown", comment: "Unknown")).camelCaseToWords()).font(.headline)
				}
			}
			ToolbarItem(placement: .navigationBarTrailing) {
				ZStack {
					ConnectedDevice(
						bluetoothOn: bleManager.isSwitchedOn,
						deviceConnected: bleManager.connectedPeripheral != nil,
						name: (bleManager.connectedPeripheral != nil) ? bleManager.connectedPeripheral.shortName : "????")
				}
			}
		}
	}
}
