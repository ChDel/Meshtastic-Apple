//
 //  ChannelTips.swift
 //  Meshtastic
 //
 //  Copyright(c) Garth Vander Houwen 8/31/23.
 //
 import SwiftUI
 #if canImport(TipKit)
 import TipKit
 #endif

 @available(iOS 17.0, macOS 14.0, *)
 struct ShareChannelsTip: Tip {

	var id: String {
		return "tip.channels.share"
	}
	var title: Text {
		Text("tip.channels.share.title")
	}
	var message: Text? {
		Text("tip.channels.share.message")
	}
	var image: Image? {
		Image(systemName: "qrcode")
	}
 }

@available(iOS 17.0, macOS 14.0, *)
struct CreateChannelsTip: Tip {

   var id: String {
	   return "tip.channels.create"
   }
   var title: Text {
	   Text("tip.channels.create.title")
   }
   var message: Text? {
	   Text("tip.channels.create.message")
   }
   var image: Image? {
	   Image(systemName: "fibrechannel")
   }
}

@available(iOS 17.0, macOS 14.0, *)
struct AdminChannelTip: Tip {

   var id: String {
	   return "tip.channel.admin"
   }
   var title: Text {
	   Text("tip.channel.admin.title")
   }
   var message: Text? {
	   Text("tip.channel.admin.message")
   }
   var image: Image? {
	   Image(systemName: "fibrechannel")
   }
}
