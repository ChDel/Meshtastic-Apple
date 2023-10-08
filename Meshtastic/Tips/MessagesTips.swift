//
//  MessagesTips.swift
//  Meshtastic
//
//  Copyright(c) Garth Vander Houwen 9/15/23.
//
import SwiftUI
#if canImport(TipKit)
import TipKit
#endif

@available(iOS 17.0, macOS 14.0, *)
struct MessagesTip: Tip {

   var id: String {
	   return "tip.messages"
   }
   var title: Text {
	   Text("tip.messages.title")
   }
   var message: Text? {
	   Text("tip.messages.message")
   }
   var image: Image? {
	   Image(systemName: "bubble.left.and.bubble.right")
   }
}

@available(iOS 17.0, macOS 14.0, *)
struct ContactsTip: Tip {

   var id: String {
	   return "tip.messages.contacts"
   }
   var title: Text {
	   //Text("tip.messages.contacts.title")
	   Text("Contacts")
   }
   var message: Text? {
	   //Text("tip.messages.contacts.message")
	   Text("Each node shows as an available contact. Nodes with recent messages and favorites show up at the top of the list. Select a node to send or view messages. Long press to favorite or mute the node, send a trace route or delete the conversation.")
   }
   var image: Image? {
	   Image(systemName: "person.circle")
   }
}
