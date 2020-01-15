//
//  ContentView.swift
//  Noon
//
//  Created by peloille on 14/01/2020.
//  Copyright © 2020 appankarton. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    var midi = MIDIController();
    
    func rightPanel(_ index: Int) -> some View {
        let elems = self.midi.destsOf(id: index)
        print(elems)
        return ForEach(elems, id: \.id) {
            Text("\($0.id) \($0.name)").frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(0 ... midi.numberOfDevices() - 1, id: \.self) { index in
                    NavigationLink(destination: self.rightPanel(index)) {
                        Text(self.midi.nameOf(index))
                    }
                }
            }
            .listStyle(SidebarListStyle())
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
