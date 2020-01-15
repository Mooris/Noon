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
    private var _thruParams = MIDIThruConnectionParams()
    private var _ids: MIDIUniqueID = 0
    private var _conRef = MIDIThruConnectionRef()
    private var _portRef = MIDIPortRef()
    private var tmp: (MIDIDevice, MIDIPortRef)?
    
    init() {
        MIDIClientCreate("Noon client" as CFString, nil, nil, &_ref)
        MIDIOutputPortCreate(_ref, "Noon port" as CFString, &_portRef)
        MIDIThruConnectionParamsInitialize(&_thruParams)

        for index in 0 ... (self.numberOfDevices() - 1) {
            let ref = MIDIGetDevice(index)
            self._devices.append(MIDIDevice(id: index, name: _nameOf(device: ref), dests: _destsOf(device: ref)))
        }
        _thruParams.numSources = 1
        _thruParams.sources.0 = MIDIThruConnectionEndpoint(endpointRef: _edp, uniqueID: _ids)
        _ids += 1;
        
        tmp = (_devices[6], _portRef)
        MIDIDestinationCreate(_ref, "Noon endpoint" as CFString, { (pl, cls, c) -> Void in
            guard let (dsts, port) = cls?.load(as: (MIDIDevice, MIDIPortRef).self) else { print("nil arg"); return }
            for endpt in dsts.dests {
                MIDISend(port, endpt.ref, pl)
            }
        }, &tmp, &_edp)

        
        let len = MIDIThruConnectionParamsSize(&self._thruParams)
        let paramsData = withUnsafePointer(to: &_thruParams) { p in
            NSData(bytes: p, length: len)
        }
        let res = MIDIThruConnectionCreate(nil, paramsData, &_conRef) //TODO: Make that work or remove it
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
                    print("NOWOWO \(displayName)")
                    if (entitiesNb == 4) {
                        _thruParams.numDestinations += 1
                        switch _ids {
                            case 0:
                                _thruParams.destinations.0 = MIDIThruConnectionEndpoint(endpointRef: _edp, uniqueID: self._ids)
                            case 1:
                                _thruParams.destinations.1 = MIDIThruConnectionEndpoint(endpointRef: _edp, uniqueID: self._ids)
                            case 2:
                                _thruParams.destinations.2 = MIDIThruConnectionEndpoint(endpointRef: _edp, uniqueID: self._ids)
                            case 3:
                                _thruParams.destinations.3 = MIDIThruConnectionEndpoint(endpointRef: _edp, uniqueID: self._ids)
                        default:
                            continue
                        }
                        self._ids += 1
                        print("Should be on teh interface need a button \(self._ids)")
                        
                    }
                } else {
                    print("error motherf*cker")
                }
            }
        }
        return ret;
    }
}
