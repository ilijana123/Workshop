//
//  User.swift
//  Workshop
//
//  Created by Ilijana Simonovska on 12/15/24.
//

import Foundation
internal class User {
    internal let id : String
    internal let email : String
    internal let name : String
    internal let type : String
    init(id:String,email:String,name:String,type:String) {
        self.id=id;
        self.email=email;
        self.name=name;
        self.type=type;
    }
}
