//
//  DeviceMap.swift
//  MeshtasticClient
//
//  Created by Garth Vander Houwen on 8/7/21.
//  Copyright © 2021 Apple. All rights reserved.
//

import SwiftUI
import MapKit
import CoreLocation

struct NodeMap: View {
    
    
    
    @ObservedObject var bleManager = BLEManager()
    @EnvironmentObject var meshData: MeshData
    
    var locationNodes: [NodeInfoModel] {
        meshData.nodes.filter { node in
            (node.position.coordinate != nil)
        }
    }
    struct MapLocation: Identifiable {
        let id = UUID()
        let name: String
        let coordinate: CLLocationCoordinate2D
    }

    
    
    var body: some View {
        let location = LocationHelper.currentLocation

        let currentCoordinatePosition = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        let regionBinding = Binding<MKCoordinateRegion>(
            get: {
                MKCoordinateRegion(center: currentCoordinatePosition, span: MKCoordinateSpan(latitudeDelta: 0.0359, longitudeDelta: 0.0359))
            },
            set: { _ in }
        )
                
        NavigationView {
            
            ZStack {
                Map(coordinateRegion: regionBinding,
                    interactionModes: [.all],
                    showsUserLocation: true,
                    userTrackingMode: .constant(.follow), annotationItems: locationNodes) { location in
                    
                    MapAnnotation(
                        coordinate: location.position.coordinate!,
                       content: {
						   CircleText(text: location.user.shortName, color: .accentColor)
                       }
                    )
                }
                .frame(maxHeight:.infinity)
                .ignoresSafeArea(.all, edges: [.leading, .trailing])
            }
            .navigationTitle("Mesh Map")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear{
            meshData.load()
        }
    }
}

struct NodeMap_Previews: PreviewProvider {
    static let meshData = MeshData()
    static let bleManager = BLEManager()

    static var previews: some View {
        NodeMap(bleManager: bleManager)
            .environmentObject(MeshData())
    }
}
