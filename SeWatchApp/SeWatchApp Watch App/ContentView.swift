//
//  ContentView.swift
//  SeWatchApp Watch App
//
//  Created by Nich on 10/29/23.
//

import SwiftUI
import CoreMotion
import WatchConnectivity

struct ContentView: View {
    @State private var isRecording = false
    let motionManager = CMMotionManager()
    @State private var recordedData = [(linearAcceleration: CMAcceleration, gravityVector: CMAcceleration)]()

    func exportData() {
        let csvString = createCSVString()

        if let directory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.your.app.group") {
            let fileURL = directory.appendingPathComponent("recordedData.csv")

            do {
                try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            } catch {
                print("Error writing CSV file: \(error.localizedDescription)")
                return
            }

            if WCSession.default.isReachable {
                WCSession.default.transferFile(fileURL, metadata: nil)
            } else {
                print("iPhone is not reachable")
            }
        } else {
            print("Error creating file directory")
        }
    }

    func processMotionData(motionData: CMDeviceMotion?) {
        if let motionData = motionData {
            let linearAcceleration = motionData.userAcceleration
            let gravityVector = motionData.gravity
            recordedData.append((linearAcceleration, gravityVector))
        }
    }

    func createCSVString() -> String {
        var csvString = "Linear_Acc_X,Linear_Acc_Y,Linear_Acc_Z,Gravity_X,Gravity_Y,Gravity_Z\n" // Add column headers
        for data in recordedData {
            csvString += "\(data.linearAcceleration.x),\(data.linearAcceleration.y),\(data.linearAcceleration.z),\(data.gravityVector.x),\(data.gravityVector.y),\(data.gravityVector.z)\n"
        }
        return csvString
    }

    func toggleRecording() {
        if isRecording {
            motionManager.stopDeviceMotionUpdates()
        } else {
            if motionManager.isDeviceMotionAvailable {
                motionManager.deviceMotionUpdateInterval = 0.1
                motionManager.startDeviceMotionUpdates(to: OperationQueue.current!) { (motionData, error) in
                    self.processMotionData(motionData: motionData)
                }
            } else {
                print("Device Motion data not available")
            }
        }
        isRecording.toggle()
    }

    var body: some View {
        Button(action: {
            toggleRecording()
        }) {
            Circle()
                .fill(isRecording ? Color.green : Color.red)
                .frame(width: 110, height: 110)
                .overlay(
                    Text(isRecording ? "Stop" : "Start")
                        .foregroundColor(.black)
                        .font(.system(size: 20, weight: .semibold))
                )
        }
        .frame(width: 110, height: 110)
        .buttonStyle(PlainButtonStyle())

        Spacer()

        Button(action: {
            exportData()
        }) {
            Text("Export Data")
                .font(.system(size: 13))
        }
        .frame(width: 110, height: 50)

    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

