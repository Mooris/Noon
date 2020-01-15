//
//  MIDIController.swift
//  Noon
//
//  Created by peloille on 14/01/2020.
//  Copyright © 2020 appankarton. All rights reserved.
//

import CoreMIDI

class MIDIController {
    struct Dest {
        let id: Int
        let name: String
        let ref: MIDIEndpointRef
    }
    struct MIDIDevice {
        let id: Int
        let name: String
        let dests: [Dest]
    }
    
    private var _devices: [MIDIDevice] = []
    private var _ref = MIDIClientRef()
    private var _edp = MIDIEndpointRef()
    //private var _thruParams = MIDIThruConnectionParams()
    //private var _ids: MIDIUniqueID = 0xFF69b4
    //private var _conRef = MIDIThruConnectionRef()
    private var _portRef = MIDIPortRef()
    
        /* Tests */
    //private var _midiThruDests: [MIDIThruConnectionEndpoint] = []
    private var tmp: (MIDIDevice, MIDIPortRef)?
    
    init() {
        MIDIClientCreate("Noon client" as CFString, nil, nil, &_ref)
        MIDIOutputPortCreate(_ref, "Noon port" as CFString, &_portRef)
        //MIDIThruConnectionParamsInitialize(&_thruParams)

        for index in 0 ... (self.numberOfDevices() - 1) {
            let ref = MIDIGetDevice(index)
            self._devices.append(MIDIDevice(id: index, name: _nameOf(device: ref), dests: _destsOf(device: ref)))
        }
        //_thruParams.numSources = 1
        //_thruParams.sources.0 = MIDIThruConnectionEndpoint(endpointRef: _edp, uniqueID: _ids)
        //_ids += 1;
        
        if let dev = _devices.first(where: { $0.dests.count == 4 }) {
            tmp = (dev, _portRef)
            MIDIDestinationCreate(_ref, "Noon endpoint" as CFString, { (pl, cls, c) -> Void in
                guard let (dsts, port) = cls?.load(as: (MIDIDevice, MIDIPortRef).self) else { print("nil arg"); return }
                for endpt in dsts.dests {
                    MIDISend(port, endpt.ref, pl)
                }
            }, &tmp, &_edp)
        }
        //withUnsafeMutablePointer(to: &_thruParams.destinations) { dst -> Void in
            //memcpy(dst, _midiThruDests, _midiThruDests.count) // Should be ok I guess
            //return
        //}
        
        //let len = MIDIThruConnectionParamsSize(&self._thruParams)
        //let paramsData = withUnsafePointer(to: &_thruParams) { p in
            //NSData(bytes: p, length: len)
        //}
        //let res = MIDIThruConnectionCreate("com.appankarton.Noon" as CFString, paramsData, &_conRef) //TODO: Make that work or remove it
        //print("res = \(res)")
    }
    
    deinit {
        //MIDIThruConnectionDispose(_conRef)
        MIDIPortDispose(_portRef)
        MIDIClientDispose(_ref)
    }
    
    func numberOfDevices() -> Int {
        return MIDIGetNumberOfDevices();
    }
        
    func nameOf(_ id: Int) -> String {
        return _devices[id].name
    }
    
    func destsOf(id: Int) -> [Dest] {
        if let idx = _devices.firstIndex(where:  {(elem) -> Bool in return elem.id == id}) {
            return _devices[idx].dests
        } else {
            return []
        }
    }
    
    private func _nameOf(device ref: MIDIObjectRef) -> String {
        var property : Unmanaged<CFString>?
        let err: OSStatus = MIDIObjectGetStringProperty(ref, kMIDIPropertyName, &property)
        
        if err == noErr {
            let displayName = property!.takeRetainedValue() as String
            return (displayName)
        }
        print("error: \(err)")
        return ("Error") //TODO: Better code...
    }
    
    private func _destsOf(device ref: MIDIDeviceRef) -> [Dest] {
        var ret: [Dest] = []
        let entitiesNb = MIDIDeviceGetNumberOfEntities(ref)
        if (entitiesNb == 0) { return [] }
        for index in 0 ... (entitiesNb - 1) {
            let entity = MIDIDeviceGetEntity(ref, index)
            let endpointsNumber = MIDIEntityGetNumberOfDestinations(entity)
            print("\(self._nameOf(device: ref)) nb = \(endpointsNumber)")
            guard endpointsNumber != 0 else { continue }
            for endptIdx in 0 ..< endpointsNumber {
                let dest = MIDIEntityGetDestination(entity, endptIdx)
                let displayName = self._nameOf(device: dest)
                if (displayName != "Error") { // TODO: Optional putain
                    ret.append(Dest(id: index, name: displayName, ref: dest));
                    //if (entitiesNb == 4) {
                        //_midiThruDests.append(MIDIThruConnectionEndpoint(endpointRef: _edp, uniqueID: self._ids))
                        //_thruParams.numDestinations += 1
                        //self._ids += 1
                        //print("Should be on teh interface need a button \(self._ids)")
                        
                    //}
                } else {
                    print("error motherf*cker")
                }
            }
        }
        return ret;
    }
}
