//
//  MeshPackets.swift
//  Meshtastic Apple
//
//  Created by Garth Vander Houwen on 5/27/22.
//

import Foundation
import CoreData
import SwiftUI


func myInfoPacket (myInfo: MyNodeInfo, meshLogging: Bool, context: NSManagedObjectContext) -> MyInfoEntity? {
	
	let fetchMyInfoRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest.init(entityName: "MyInfoEntity")
	fetchMyInfoRequest.predicate = NSPredicate(format: "myNodeNum == %lld", Int64(myInfo.myNodeNum))

	do {
		let fetchedMyInfo = try context.fetch(fetchMyInfoRequest) as! [MyInfoEntity]
		// Not Found Insert
		if fetchedMyInfo.isEmpty {
			
			let myInfoEntity = MyInfoEntity(context: context)
			myInfoEntity.myNodeNum = Int64(myInfo.myNodeNum)
			myInfoEntity.hasGps = myInfo.hasGps_p
			myInfoEntity.hasWifi = myInfo.hasWifi_p
			myInfoEntity.bitrate = myInfo.bitrate

			// Swift does strings weird, this does work to get the version without the github hash
			let lastDotIndex = myInfo.firmwareVersion.lastIndex(of: ".")
			var version = myInfo.firmwareVersion[...(lastDotIndex ?? String.Index(utf16Offset: 6, in: myInfo.firmwareVersion))]
			version = version.dropLast()
			myInfoEntity.firmwareVersion = String(version)
			myInfoEntity.messageTimeoutMsec = Int32(bitPattern: myInfo.messageTimeoutMsec)
			myInfoEntity.minAppVersion = Int32(bitPattern: myInfo.minAppVersion)
			myInfoEntity.maxChannels = Int32(bitPattern: myInfo.maxChannels)
			
			do {

				try context.save()
				if meshLogging { MeshLogger.log("💾 Saved a new myInfo for node number: \(String(myInfo.myNodeNum))") }
				return myInfoEntity

			} catch {

				context.rollback()

				let nsError = error as NSError
				print("💥 Error Inserting New Core Data MyInfoEntity: \(nsError)")
			}
			
		} else {

			fetchedMyInfo[0].myNodeNum = Int64(myInfo.myNodeNum)
			fetchedMyInfo[0].hasGps = myInfo.hasGps_p
			fetchedMyInfo[0].bitrate = myInfo.bitrate
			
			let lastDotIndex = myInfo.firmwareVersion.lastIndex(of: ".")//.lastIndex(of: ".", offsetBy: -1)
			var version = myInfo.firmwareVersion[...(lastDotIndex ?? String.Index(utf16Offset:6, in: myInfo.firmwareVersion))]
			version = version.dropLast()
			fetchedMyInfo[0].firmwareVersion = String(version)
			fetchedMyInfo[0].messageTimeoutMsec = Int32(bitPattern: myInfo.messageTimeoutMsec)
			fetchedMyInfo[0].minAppVersion = Int32(bitPattern: myInfo.minAppVersion)
			fetchedMyInfo[0].maxChannels = Int32(bitPattern: myInfo.maxChannels)
			
			do {

				try context.save()
				if meshLogging { MeshLogger.log("💾 Updated myInfo for node number: \(String(myInfo.myNodeNum))") }
				return fetchedMyInfo[0]

			} catch {

				context.rollback()

				let nsError = error as NSError
				print("💥 Error Updating Core Data MyInfoEntity: \(nsError)")
			}
		}

	} catch {

		print("💥 Fetch MyInfo Error")
	}
	return nil
}

func nodeInfoPacket (nodeInfo: NodeInfo, meshLogging: Bool, context: NSManagedObjectContext) -> NodeInfoEntity? {
	
	let fetchNodeInfoRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest.init(entityName: "NodeInfoEntity")
	fetchNodeInfoRequest.predicate = NSPredicate(format: "num == %lld", Int64(nodeInfo.num))

	do {

		let fetchedNode = try context.fetch(fetchNodeInfoRequest) as! [NodeInfoEntity]
		// Not Found Insert
		if fetchedNode.isEmpty && nodeInfo.hasUser {

			let newNode = NodeInfoEntity(context: context)
			newNode.id = Int64(nodeInfo.num)
			newNode.num = Int64(nodeInfo.num)
			
			if nodeInfo.hasDeviceMetrics {
				
				let telemetry = TelemetryEntity(context: context)
				
				telemetry.batteryLevel = Int32(nodeInfo.deviceMetrics.batteryLevel)
				telemetry.voltage = nodeInfo.deviceMetrics.voltage
				telemetry.channelUtilization = nodeInfo.deviceMetrics.channelUtilization
				telemetry.airUtilTx = nodeInfo.deviceMetrics.airUtilTx
				
				var newTelemetries = [TelemetryEntity]()
				newTelemetries.append(telemetry)
				newNode.telemetries? = NSOrderedSet(array: newTelemetries)
			}
			
			newNode.lastHeard = Date(timeIntervalSince1970: TimeInterval(Int64(nodeInfo.lastHeard)))
			newNode.snr = nodeInfo.snr
			
			if nodeInfo.hasUser {

				let newUser = UserEntity(context: context)
				newUser.userId = nodeInfo.user.id
				newUser.num = Int64(nodeInfo.num)
				newUser.longName = nodeInfo.user.longName
				newUser.shortName = nodeInfo.user.shortName
				newUser.macaddr = nodeInfo.user.macaddr
				newUser.hwModel = String(describing: nodeInfo.user.hwModel).uppercased()
				newNode.user = newUser
			}

			let position = PositionEntity(context: context)
			position.latitudeI = nodeInfo.position.latitudeI
			position.longitudeI = nodeInfo.position.longitudeI
			position.altitude = nodeInfo.position.altitude
			position.time = Date(timeIntervalSince1970: TimeInterval(Int64(nodeInfo.position.time)))
			
			var newPostions = [PositionEntity]()
			newPostions.append(position)
			newNode.positions? = NSOrderedSet(array: newPostions)

			// Look for a MyInfo
			let fetchMyInfoRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest.init(entityName: "MyInfoEntity")
			fetchMyInfoRequest.predicate = NSPredicate(format: "myNodeNum == %lld", Int64(nodeInfo.num))

			do {

				let fetchedMyInfo = try context.fetch(fetchMyInfoRequest) as! [MyInfoEntity]
				if fetchedMyInfo.count > 0 {
					newNode.myInfo = fetchedMyInfo[0]
				}
				
				do {

					try context.save()
					
					if nodeInfo.hasUser {

						if meshLogging { MeshLogger.log("💾 BLE FROMRADIO received and nodeInfo inserted for \(nodeInfo.user.longName)") }

					} else {

						if meshLogging { MeshLogger.log("💾 BLE FROMRADIO received and nodeInfo inserted for \(nodeInfo.num)") }
					}
					return newNode

				} catch {

					context.rollback()

					let nsError = error as NSError
					print("💥 Error Saving Core Data NodeInfoEntity: \(nsError)")
				}

			} catch {
				print("💥 Fetch MyInfo Error")
			}

		} else if nodeInfo.hasUser && nodeInfo.num > 0 {

			fetchedNode[0].id = Int64(nodeInfo.num)
			fetchedNode[0].num = Int64(nodeInfo.num)
			fetchedNode[0].lastHeard = Date(timeIntervalSince1970: TimeInterval(Int64(nodeInfo.lastHeard)))
			fetchedNode[0].snr = nodeInfo.snr
			

			if nodeInfo.hasUser {

				fetchedNode[0].user!.userId = nodeInfo.user.id
				fetchedNode[0].user!.num = Int64(nodeInfo.num)
				fetchedNode[0].user!.longName = nodeInfo.user.longName
				fetchedNode[0].user!.shortName = nodeInfo.user.shortName
				fetchedNode[0].user!.macaddr = nodeInfo.user.macaddr
				fetchedNode[0].user!.hwModel = String(describing: nodeInfo.user.hwModel).uppercased()
			}

			if nodeInfo.hasDeviceMetrics {
				
				let newTelemetry = TelemetryEntity(context: context)

				newTelemetry.batteryLevel = Int32(nodeInfo.deviceMetrics.batteryLevel)
				newTelemetry.voltage = nodeInfo.deviceMetrics.voltage
				newTelemetry.channelUtilization = nodeInfo.deviceMetrics.channelUtilization
				newTelemetry.airUtilTx = nodeInfo.deviceMetrics.airUtilTx
				
				let mutableTelemetries = fetchedNode[0].telemetries!.mutableCopy() as! NSMutableOrderedSet
				fetchedNode[0].telemetries = mutableTelemetries.copy() as? NSOrderedSet
			}
			
			if nodeInfo.hasPosition {

				let position = PositionEntity(context: context)
				position.latitudeI = nodeInfo.position.latitudeI
				position.longitudeI = nodeInfo.position.longitudeI
				position.altitude = nodeInfo.position.altitude
				position.time = Date(timeIntervalSince1970: TimeInterval(Int64(nodeInfo.position.time)))

				let mutablePositions = fetchedNode[0].positions!.mutableCopy() as! NSMutableOrderedSet

				fetchedNode[0].positions = mutablePositions.copy() as? NSOrderedSet
				
			}

			// Look for a MyInfo
			let fetchMyInfoRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest.init(entityName: "MyInfoEntity")
			fetchMyInfoRequest.predicate = NSPredicate(format: "myNodeNum == %lld", Int64(nodeInfo.num))

			do {

				let fetchedMyInfo = try context.fetch(fetchMyInfoRequest) as! [MyInfoEntity]
				if fetchedMyInfo.count > 0 {

					fetchedNode[0].myInfo = fetchedMyInfo[0]
				}
				
				do {

					try context.save()
					
					if nodeInfo.hasUser {

						if meshLogging { MeshLogger.log("💾 BLE FROMRADIO received and nodeInfo inserted for \(nodeInfo.user.longName)") }

					} else {

						if meshLogging { MeshLogger.log("💾 BLE FROMRADIO received and nodeInfo inserted for \(nodeInfo.num)") }
					}
					
					return fetchedNode[0]

				} catch {

					context.rollback()

					let nsError = error as NSError
					print("💥 Error Saving Core Data NodeInfoEntity: \(nsError)")
				}

			} catch {
				print("💥 Fetch MyInfo Error")
			}
		}

	} catch {

		print("💥 Fetch NodeInfoEntity Error")
	}
	
	return nil
}

func nodeInfoAppPacket (packet: MeshPacket, meshLogging: Bool, context: NSManagedObjectContext) {

	let fetchNodeInfoAppRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest.init(entityName: "NodeInfoEntity")
	fetchNodeInfoAppRequest.predicate = NSPredicate(format: "num == %lld", Int64(packet.from))

	do {

		let fetchedNode = try context.fetch(fetchNodeInfoAppRequest) as! [NodeInfoEntity]

		if fetchedNode.count == 1 {
			fetchedNode[0].id = Int64(packet.from)
			fetchedNode[0].num = Int64(packet.from)
			fetchedNode[0].lastHeard = Date(timeIntervalSince1970: TimeInterval(Int64(packet.rxTime)))
			fetchedNode[0].snr = packet.rxSnr
			
			if let nodeInfoMessage = try? NodeInfo(serializedData: packet.decoded.payload) {
		
				if nodeInfoMessage.hasDeviceMetrics {
					
					let telemetry = TelemetryEntity(context: context)
					
					telemetry.batteryLevel = Int32(nodeInfoMessage.deviceMetrics.batteryLevel)
					telemetry.voltage = nodeInfoMessage.deviceMetrics.voltage
					telemetry.channelUtilization = nodeInfoMessage.deviceMetrics.channelUtilization
					telemetry.airUtilTx = nodeInfoMessage.deviceMetrics.airUtilTx
					
					var newTelemetries = [TelemetryEntity]()
					newTelemetries.append(telemetry)
					fetchedNode[0].telemetries? = NSOrderedSet(array: newTelemetries)
				}
			}
			
		} else {
			return
		}
		do {

			try context.save()

			if meshLogging { MeshLogger.log("💾 Updated NodeInfo SNR \(packet.rxSnr) and Time from Node Info App Packet For: \(fetchedNode[0].num)")}

		} catch {

			context.rollback()

			let nsError = error as NSError
			print("💥 Error Saving NodeInfoEntity from NODEINFO_APP \(nsError)")

		}
	} catch {

		print("💥 Error Fetching NodeInfoEntity for NODEINFO_APP")
	}
}

func adminAppPacket (packet: MeshPacket, meshLogging: Bool, context: NSManagedObjectContext) {
	
    if let deviceConfig = try? MeshtasticApple.Config.DeviceConfig(serializedData: packet.decoded.payload) {
		
		print(try! deviceConfig.jsonString())
		
	} else if let displayConfig = try? MeshtasticApple.Config.DisplayConfig(serializedData: packet.decoded.payload) {
		
		print(try! displayConfig.jsonUTF8Data())
		print(displayConfig.gpsFormat)
		
	} else if let loraConfig = try? MeshtasticApple.Config.LoRaConfig(serializedData: packet.decoded.payload) {
		
		print(try! loraConfig.jsonUTF8Data())
		print(loraConfig.region)
		
	} else if let positionConfig = try? MeshtasticApple.Config.PositionConfig(serializedData: packet.decoded.payload) {
		
		print(try! positionConfig.jsonUTF8Data())
		print(positionConfig.positionBroadcastSecs)
		
	} else if let powerConfig = try? MeshtasticApple.Config.PowerConfig(serializedData: packet.decoded.payload) {
		
		print(try! powerConfig.jsonUTF8Data())
		print(powerConfig.meshSdsTimeoutSecs)
		
	}
	
	
	if meshLogging { MeshLogger.log("ℹ️ MESH PACKET received for Admin App UNHANDLED \(try! packet.jsonString())") }
	
	//PowerConfig
	//WiFiConfig
	
	
	
	
	//if let loraConfig = try? MeshtasticApple.Config.LoRaConfig(serializedData: packet.serializedData) {
		
	//	print(loraConfig)
	//}
}

func positionPacket (packet: MeshPacket, meshLogging: Bool, context: NSManagedObjectContext) {
	
	let fetchNodePositionRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest.init(entityName: "NodeInfoEntity")
	fetchNodePositionRequest.predicate = NSPredicate(format: "num == %lld", Int64(packet.from))

	do {

		let fetchedNode = try context.fetch(fetchNodePositionRequest) as! [NodeInfoEntity]

		if fetchedNode.count == 1 {
			
			fetchedNode[0].id = Int64(packet.from)
			fetchedNode[0].num = Int64(packet.from)
			fetchedNode[0].lastHeard = Date(timeIntervalSince1970: TimeInterval(Int64(packet.rxTime)))
			fetchedNode[0].snr = packet.rxSnr
				
			if let positionMessage = try? Position(serializedData: packet.decoded.payload) {
				
				let position = PositionEntity(context: context)
				position.latitudeI = positionMessage.latitudeI
				position.longitudeI = positionMessage.longitudeI
				position.altitude = positionMessage.altitude
				position.time = Date(timeIntervalSince1970: TimeInterval(Int64(positionMessage.time)))

				let mutablePositions = fetchedNode[0].positions!.mutableCopy() as! NSMutableOrderedSet
				mutablePositions.add(position)
				
				fetchedNode[0].positions = mutablePositions.copy() as? NSOrderedSet
			}
			
		} else {
			
			return
		}
		do {

		  try context.save()

			if meshLogging {
				MeshLogger.log("💾 Updated Node Position Coordinates, SNR and Time from Position App Packet For: \(fetchedNode[0].num)")
			}

		} catch {

			context.rollback()

			let nsError = error as NSError
			print("💥 Error Saving NodeInfoEntity from POSITION_APP \(nsError)")
		}
	} catch {

		print("💥 Error Fetching NodeInfoEntity for POSITION_APP")
	}

}

func routingPacket (packet: MeshPacket, meshLogging: Bool, context: NSManagedObjectContext) {
	
	if let routingMessage = try? Routing(serializedData: packet.decoded.payload) {
		
		let error = routingMessage.errorReason
		
		var errorExplanation = "Unknown Routing Error"
		
		switch error {
			case Routing.Error.none:
				errorExplanation = "This message is not a failure"
			case Routing.Error.noRoute:
				errorExplanation = "Our node doesn't have a route to the requested destination anymore."
			case Routing.Error.gotNak:
				errorExplanation = "We received a nak while trying to forward on your behalf"
			case Routing.Error.timeout:
				errorExplanation = "Timeout"
			case Routing.Error.noInterface:
				errorExplanation = "No suitable interface could be found for delivering this packet"
			case Routing.Error.maxRetransmit:
				errorExplanation = "We reached the max retransmission count (typically for naive flood routing)"
			case Routing.Error.noChannel:
				errorExplanation = "No suitable channel was found for sending this packet (i.e. was requested channel index disabled?)"
			case Routing.Error.tooLarge:
				errorExplanation = "The packet was too big for sending (exceeds interface MTU after encoding)"
			case Routing.Error.noResponse:
				errorExplanation = "The request had want_response set, the request reached the destination node, but no service on that node wants to send a response (possibly due to bad channel permissions)"
			case Routing.Error.badRequest:
				errorExplanation = "The application layer service on the remote node received your request, but considered your request somehow invalid"
			case Routing.Error.notAuthorized:
				errorExplanation = "The application layer service on the remote node received your request, but considered your request not authorized (i.e you did not send the request on the required bound channel)"
			fallthrough
			default: ()
		}
		
		if meshLogging { MeshLogger.log("🕸️ ROUTING PACKET received for RequestID: \(packet.decoded.requestID) Error: \(errorExplanation)") }
						
		if routingMessage.errorReason == Routing.Error.none {
			
			let fetchMessageRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest.init(entityName: "MessageEntity")
			fetchMessageRequest.predicate = NSPredicate(format: "messageId == %lld", Int64(packet.decoded.requestID))

			do {

				let fetchedMessage = try context.fetch(fetchMessageRequest)[0] as? MessageEntity
				
				if fetchedMessage != nil {
					
					fetchedMessage!.receivedACK = true
					fetchedMessage!.ackSNR = packet.rxSnr
					fetchedMessage!.ackTimestamp = Int32(packet.rxTime)
					fetchedMessage!.objectWillChange.send()
					fetchedMessage!.fromUser?.objectWillChange.send()
					fetchedMessage!.toUser?.objectWillChange.send()
				}
				
				try context.save()

				  if meshLogging {
					  MeshLogger.log("💾 ACK Received and saved for MessageID \(packet.decoded.requestID)")
				  }
				
			} catch {
				
				context.rollback()

				let nsError = error as NSError
				print("💥 Error Saving ACK for message MessageID \(packet.id) Error: \(nsError)")
			}
		}
	}
}
	
func telemetryPacket(packet: MeshPacket, meshLogging: Bool, context: NSManagedObjectContext) {
	
	if let telemetryMessage = try? Telemetry(serializedData: packet.decoded.payload) {
		
		let telemetry = TelemetryEntity(context: context)
		
		let fetchNodeTelemetryRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest.init(entityName: "NodeInfoEntity")
		fetchNodeTelemetryRequest.predicate = NSPredicate(format: "num == %lld", Int64(packet.from))

		do {

			let fetchedNode = try context.fetch(fetchNodeTelemetryRequest) as! [NodeInfoEntity]

			if fetchedNode.count == 1 {
				
				// Device Metrics
				telemetry.airUtilTx = telemetryMessage.deviceMetrics.airUtilTx
				telemetry.channelUtilization = telemetryMessage.deviceMetrics.channelUtilization
				telemetry.batteryLevel = Int32(telemetryMessage.deviceMetrics.batteryLevel)
				telemetry.voltage = telemetryMessage.deviceMetrics.voltage
				
				// Environment Metrics
				telemetry.barometricPressure = telemetryMessage.environmentMetrics.barometricPressure
				telemetry.current = telemetryMessage.environmentMetrics.current
				telemetry.gasResistance = telemetryMessage.environmentMetrics.gasResistance
				telemetry.relativeHumidity = telemetryMessage.environmentMetrics.relativeHumidity
				telemetry.temperature = telemetryMessage.environmentMetrics.temperature
				let mutableTelemetries = fetchedNode[0].telemetries!.mutableCopy() as! NSMutableOrderedSet
				mutableTelemetries.add(telemetry)
				
				fetchedNode[0].lastHeard = Date(timeIntervalSince1970: TimeInterval(Int64(telemetryMessage.time)))
				fetchedNode[0].telemetries = mutableTelemetries.copy() as? NSOrderedSet
				fetchedNode[0].objectWillChange.send()
			}
			
			try context.save()

			  if meshLogging {
				  MeshLogger.log("💾 Telemetry Saved for Node: \(packet.from)")
			  }
			
		} catch {
			
			context.rollback()

			let nsError = error as NSError
			print("💥 Error Saving Telemetry for Node \(packet.from) Error: \(nsError)")
		}
		
	} else {
		
	}
}

func textMessageAppPacket(packet: MeshPacket, connectedNode: Int64, meshLogging: Bool, context: NSManagedObjectContext) {
	
	let broadcastNodeNum: UInt32 = 4294967295
		
	if let messageText = String(bytes: packet.decoded.payload, encoding: .utf8) {

		if meshLogging { MeshLogger.log("💬 Message received for text message app \(messageText)") }

		let messageUsers: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest.init(entityName: "UserEntity")
		messageUsers.predicate = NSPredicate(format: "num IN %@", [packet.to, packet.from])

		do {

			let fetchedUsers = try context.fetch(messageUsers) as! [UserEntity]

			let newMessage = MessageEntity(context: context)
			newMessage.messageId = Int64(packet.id)
			newMessage.messageTimestamp = Int32(bitPattern: packet.rxTime)
			newMessage.receivedACK = false
			newMessage.direction = "IN"
			newMessage.isEmoji = packet.decoded.emoji == 1
			
			if packet.decoded.replyID > 0 {
				
				newMessage.replyID = Int64(packet.decoded.replyID)
			}

			if packet.to == broadcastNodeNum && fetchedUsers.count == 1 {

				// Save the broadcast user if it does not exist
				let bcu: UserEntity = UserEntity(context: context)
				bcu.shortName = "ALL"
				bcu.longName = "All - Broadcast"
				bcu.hwModel = "UNSET"
				bcu.num = Int64(broadcastNodeNum)
				bcu.userId = "BROADCASTNODE"
				newMessage.toUser = bcu

			} else {

				newMessage.toUser = fetchedUsers.first(where: { $0.num == packet.to })
			}

			newMessage.fromUser = fetchedUsers.first(where: { $0.num == packet.from })
			newMessage.messagePayload = messageText
			newMessage.fromUser?.objectWillChange.send()
			newMessage.toUser?.objectWillChange.send()

			do {

				try context.save()

				if meshLogging { MeshLogger.log("💾 Saved a new message for \(newMessage.messageId)") }
				
				if newMessage.toUser != nil && newMessage.toUser!.num == broadcastNodeNum || connectedNode == newMessage.toUser!.num {
					
					// Create an iOS Notification for the received message and schedule it immediately
					let manager = LocalNotificationManager()

					manager.notifications = [
						Notification(
							id: ("notification.id.\(newMessage.messageId)"),
							title: "\(newMessage.fromUser?.longName ?? "Unknown")",
							subtitle: "AKA \(newMessage.fromUser?.shortName ?? "???")",
							content: messageText)
					]
					manager.schedule()
					if meshLogging { MeshLogger.log("💬 iOS Notification Scheduled for text message from \(newMessage.fromUser?.longName ?? "Unknown") \(messageText)") }

				}
				
			} catch {

				context.rollback()

					let nsError = error as NSError
					print("💥 Failed to save new MessageEntity \(nsError)")
				}

			} catch {

			print("💥 Fetch Message To and From Users Error")
		}
	}
}