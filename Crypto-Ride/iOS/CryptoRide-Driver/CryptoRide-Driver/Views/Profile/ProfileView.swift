//
//  ProfileView.swift
//  CryptoRide-Driver
//
//  Created by mitchell tucker on 10/21/22.
//

import SwiftUI

// View states for registration
enum setView{
    case profile
    case car
    case location
    case rate
    case fund
}

struct ProfileView: View {
    // EnvironmentObject
    @EnvironmentObject var registered:Registered
    @EnvironmentObject var balance:Balance
    @EnvironmentObject var driver:Driver
    @EnvironmentObject var manager:LocationManager
    // State objects
    @StateObject var profileVM = ProfileViewModel()
    @State var isLoading = false
    @State var isTransfer = false
    
    // Selectable tokens
    var tokens = ["cUSD","CELO"]

    var body: some View {
        
        VStack{
            if registered.isRegistered == false {
                switch(registered.currentView){
                case setView.profile:
                    ProfileRegistration().environmentObject(profileVM)
                case setView.car:
                    CarRegistration().environmentObject(profileVM)
                case setView.location:
                    LocationRegistration().environmentObject(driver)
                case setView.rate:
                    RateRegistration().environmentObject(profileVM)
                    
                case setView.fund:
                    FundRegistration().environmentObject(profileVM)
                                      .environmentObject(balance)
                    
                }
                HStack{
                    Spacer()
                   
                    Button{
                        switch(registered.currentView){
                        case setView.profile:
                            registered.currentView = setView.car
                        case setView.car:
                            registered.currentView = setView.rate
                        case setView.location:
                            registered.currentView = setView.rate
                        case setView.rate:
                            registered.currentView = setView.fund
                        case setView.fund:
                            isLoading = true
                            
                            let car = profileVM.registerNewDriver.vehicle.year + " " +
                            profileVM.registerNewDriver.vehicle.color
                            + " " +
                            profileVM.registerNewDriver.vehicle.makeModel
                            // set default settings for new driver
                            let defaults = UserDefaults.standard
                            defaults.set(profileVM.registerNewDriver.profile.twitterHandle, forKey: "twitter")
                            defaults.set(profileVM.registerNewDriver.profile.instagramHandle, forKey: "instagram")
                             
                            profileVM.registerDriver(rate:profileVM.registerNewDriver.rate.fare, name: profileVM.registerNewDriver.profile.name, car: car) { success in
                                isLoading = false
                                registered.isRegistered = true
                                profileVM.password = ""
                            }
                        }
                        
                    }label: {
                        if registered.currentView == .fund{
                            HStack{
                                if isLoading{
                                    ProgressView()
                                }
                                Text("Send")
                                Image(systemName: "paperplane.fill")
                                
                            }
                        }else{
                            HStack{
                                Text("Next")
                                Image(systemName: "chevron.forward.square.fill")
                            }
                        }
                        
                    }.buttonStyle(.borderedProminent)
                    .disabled(isLoading)
                }
                
            }else{
                if profileVM.driverInfo != nil {
                    ScrollView {
                    VStack(alignment:.center){
                        VStack {
                            VStack(spacing:8){
                                Text(driver.name).font(.title)
                                Text(driver.car).font(.title3)
                                Text("Rating ")
                                RatingView(rating:$driver.rating)
                           
                                Text("Reputation")
                                Text(driver.reputation)
                            
                                Text("Total Rides")
                                Text(driver.rideCount)
                            
                            }.padding()
                            HStack{
                                HStack{
                                    Image("cUSDEx")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 40, height: 30, alignment: .center)
                                    Text("\(balance.cUSD)")
                                    
                                }
                                Divider()
                                HStack{
                                    Image("CeloEx")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 40, height: 40, alignment: .center)
                                    Text("\(balance.CELO)")
                                    
                                }
                                Button{
                                    balance.getTokenBalance(.CUSD)
                                    balance.getTokenBalance(.Celo)
                                }label: {
                                    Image(systemName: "arrow.clockwise.circle.fill")
                                        .resizable()
                                        .interpolation(.none)
                                        .scaledToFit()
                                        .frame(width: 20, height: 20, alignment: .center)
                                }.buttonStyle(.borderless)
                                
                            }
                            
                        }
                        Divider()
                        VStack {
                            Text("To Address").font(.title3)
                            HStack{
                                TextField("0x00", text: $profileVM.toAddress)
                                Button(action:{
                                    profileVM.toAddress = UIPasteboard.general.string ?? ""
                                }, label: {
                                    Image(systemName: "doc.on.clipboard")
                                })
                            }
                            HStack{
                                Text("Send").font(.title3)
                                Picker("", selection: $profileVM.tokenSelected) {
                                                ForEach(tokens, id: \.self) {
                                                    Text($0)
                                        }
                                }
                            }
     
                            HStack{
                                
                                TextField("0", text:  $profileVM.amount)
                                Button(action:{
                                    if profileVM.tokenSelected == "cUSD" {
                                        profileVM.amount = balance.cUSD
                                    }else{
                                        profileVM.amount = balance.CELO
                                    }
                                   
                                }, label: {
                                    Text("MAX")
                                })
                               
                            }
                            SecureField("Wallet Password", text: $profileVM.password)
                                .multilineTextAlignment(.center)
                                .textFieldStyle(.roundedBorder)
                            
                            Button(action:{
                                isTransfer = true
                                profileVM.transfer(){ success in
                                    // Get request for token balance
                                    balance.getTokenBalance(.CUSD)
                                    balance.getTokenBalance(.Celo)
                                    // Clear all inputs
                                    profileVM.amount = ""
                                    profileVM.toAddress = ""
                                    profileVM.password = ""
                                    isTransfer = false
                                }
                            }, label: {
                                Text("Send")
                            }).disabled(profileVM.toAddress.isEmpty || profileVM.amount.isEmpty || isTransfer || profileVM.password.isEmpty)
                            
                        }
                        Divider()
                        Text("Receive").font(.title3).bold()
                        
                        Button(action: {
                            UIPasteboard.general.string = ContractServices.shared.getWallet().address
                        }, label: {
                            Image(uiImage:profileVM.generateQRCode(from: ContractServices.shared.getWallet().address))
                                .resizable()
                                .interpolation(.none)
                                .scaledToFit()
                                .padding()
                                .frame(width: 230, height: 230)
                        })
                        Text(ContractServices.shared.getWallet().address).font(.body).bold().lineLimit(2)
                        
                    }.textFieldStyle(.roundedBorder)
                        .padding(EdgeInsets(top: 8, leading: 16,
                                               bottom: 8, trailing: 16))
                        .buttonStyle(.borderedProminent)
                    }
                }else{
                    ProgressView()
                }
            }

        } .alert(item:$profileVM.error) { error in
            Alert(title: Text(profileVM.error!.title), message: Text(profileVM.error!.description), dismissButton: .cancel() {
                    profileVM.error = nil
                    profileVM.amount = ""
                    profileVM.toAddress = ""
                    profileVM.password = ""
                    isTransfer = false
                })
        }
        
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: Settings().environmentObject(registered)
                                                         .environmentObject(balance)
                                                         .environmentObject(driver)
                                                         .environmentObject(profileVM)
                ){
                    Image(systemName: "gear")
                }
            }
        }

    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
