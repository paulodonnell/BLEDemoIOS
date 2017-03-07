import CoreBluetooth
import UIKit

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate, UITableViewDataSource
{
    let ShowBabyServiceUUID = "0000FFF0-0000-1000-8000-00805F9B34FB"
    let ShowBabyCharacteristicUUID = "0000FFF4-0000-1000-8000-00805F9B34FB"
    
    let ShowBabyTriggerDownId = "QjJET1dO"
    let ShowBabyTriggerUpId = "QjJVUA=="
    
    let ShowBabyButtonDownId = "QjRET1dO"
    let ShowBabyButtonUpId = "QjRVUA=="
    
    let ShowBabyPumpDownId = "QjNET1dO"
    let ShowBabyPumpUpId = "QjNVUA=="
    
    let ShowBabyName:String = "SHOWBABY"
    var showBabyPeripheral:CBPeripheral?
    
    var centralManager: CBCentralManager!
    var commands = Array<String>()
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        //Initialise CoreBluetooth Central Manager
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
    }
    
    // MARK: - CBCentralManagerDelegate methods
    
    func centralManagerDidUpdateState(_ central: CBCentralManager)
    {
        var showAlert = true
        var message = ""
        
        switch central.state {
        case .poweredOff:
            message = "Bluetooth on this device is currently powered off."
        case .unsupported:
            message = "This device does not support Bluetooth Low Energy."
        case .unauthorized:
            message = "This app is not authorized to use Bluetooth Low Energy."
        case .resetting:
            message = "The BLE Manager is resetting; a state update is pending."
        case .unknown:
            message = "The state of the BLE Manager is unknown."
        case .poweredOn:
            showAlert = false
            message = "Bluetooth LE is turned on and ready for communication."
            
            print(message)
            
            // Initiate Scan for Peripherals
            //Option 1: Scan for all devices
            centralManager.scanForPeripherals(withServices: nil, options: nil)
            
            // Option 2: Scan for devices that have the service you're interested in...
            //let sensorTagAdvertisingUUID = CBUUID(string: Device.SensorTagAdvertisingUUID)
            //print("Scanning for SensorTag adverstising with UUID: \(sensorTagAdvertisingUUID)")
            //centralManager.scanForPeripheralsWithServices([sensorTagAdvertisingUUID], options: nil)
        }
        
        if showAlert {
            let alertController = UIAlertController(title: "Central Manager State", message: message, preferredStyle: UIAlertControllerStyle.alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil)
            alertController.addAction(okAction)
            self.show(alertController, sender: self)
        }
    }
    
    /*
     Invoked when the central manager discovers a peripheral while scanning.
     
     The advertisement data can be accessed through the keys listed in Advertisement Data Retrieval Keys.
     You must retain a local copy of the peripheral if any command is to be performed on it.
     In use cases where it makes sense for your app to automatically connect to a peripheral that is
     located within a certain range, you can use RSSI data to determine the proximity of a discovered
     peripheral device.
     
     central - The central manager providing the update.
     peripheral - The discovered peripheral.
     advertisementData - A dictionary containing any advertisement data.
     RSSI - The current received signal strength indicator (RSSI) of the peripheral, in decibels.
     */
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber)
    {
        print("centralManager didDiscoverPeripheral - CBAdvertisementDataLocalNameKey is \"\(CBAdvertisementDataLocalNameKey)\"")
        
        // Retrieve the peripheral name from the advertisement data using the "kCBAdvDataLocalName" key
        if let peripheralName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        {
            print("NEXT PERIPHERAL NAME: \(peripheralName)")
            print("NEXT PERIPHERAL UUID: \(peripheral.identifier.uuidString)")
            
            if peripheralName.uppercased().contains(ShowBabyName)
            {
                print("SHOWBABY FOUND! ADDING NOW!!!")
                
                // to save power, stop scanning for other devices
                //keepScanning = false
                //disconnectButton.enabled = true
                centralManager.stopScan()
                
                // save a reference to the peripheral
                showBabyPeripheral = peripheral
                showBabyPeripheral!.delegate = self
                
                // Request a connection to the peripheral
                centralManager.connect(showBabyPeripheral!, options: nil)
            }
        }
    }
    
    
    /*
     Invoked when a connection is successfully created with a peripheral.
     
     This method is invoked when a call to connectPeripheral:options: is successful.
     You typically implement this method to set the peripheral’s delegate and to discover its services.
     */
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral)
    {
        print("**** SUCCESSFULLY CONNECTED TO SHOWBABY!!!")
        
        // Now that we've successfully connected to the Showbaby, let's discover the services.
        // - NOTE:  we pass nil here to request ALL services be discovered.
        //          If there was a subset of services we were interested in, we could pass the UUIDs here.
        //          Doing so saves battery life and saves time.
        peripheral.discoverServices(nil)
    }
    
    
    /*
     Invoked when the central manager fails to create a connection with a peripheral.
     This method is invoked when a connection initiated via the connectPeripheral:options: method fails to complete.
     Because connection attempts do not time out, a failed connection usually indicates a transient issue,
     in which case you may attempt to connect to the peripheral again.
     */
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?)
    {
        print("**** CONNECTION TO SHOWBABY FAILED!!!")
    }
    
    
    /*
     Invoked when an existing connection with a peripheral is torn down.
     
     This method is invoked when a peripheral connected via the connectPeripheral:options: method is disconnected.
     If the disconnection was not initiated by cancelPeripheralConnection:, the cause is detailed in error.
     After this method is called, no more methods are invoked on the peripheral device’s CBPeripheralDelegate object.
     
     Note that when a peripheral is disconnected, all of its services, characteristics, and characteristic descriptors are invalidated.
     */
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?)
    {
        print("**** DISCONNECTED FROM SHOWBABY!!!")
        
        if error != nil
        {
            print("****** DISCONNECTION DETAILS: \(error!.localizedDescription)")
        }
        
        showBabyPeripheral = nil
    }
    
    
    //MARK: - CBPeripheralDelegate methods
    
    /*
     Invoked when you discover the peripheral’s available services.
     
     This method is invoked when your app calls the discoverServices: method.
     If the services of the peripheral are successfully discovered, you can access them
     through the peripheral’s services property.
     
     If successful, the error parameter is nil.
     If unsuccessful, the error parameter returns the cause of the failure.
     */
    // When the specified services are discovered, the peripheral calls the peripheral:didDiscoverServices: method of its delegate object.
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?)
    {
        if error != nil
        {
            print("ERROR DISCOVERING SERVICES: \(error?.localizedDescription)")
            return
        }
        
        // Core Bluetooth creates an array of CBService objects —- one for each service that is discovered on the peripheral.
        if let services = peripheral.services
        {
            for service in services
            {
                print("Discovered service \(service) with UUID \(service.uuid)")
                
                peripheral.discoverCharacteristics(nil, for: service)
                
                // If we found either the temperature or the humidity service, discover the characteristics for those services.
//                if (service.UUID == CBUUID(string: device.TemperatureServiceUUID)) ||
//                    (service.UUID == CBUUID(string: Device.HumidityServiceUUID)) {
//                    peripheral.discoverCharacteristics(nil, forService: service)
//                }
            }
        }
    }
    
    
    /*
     Invoked when you discover the characteristics of a specified service.
     
     If the characteristics of the specified service are successfully discovered, you can access
     them through the service's characteristics property.
     
     If successful, the error parameter is nil.
     If unsuccessful, the error parameter returns the cause of the failure.
     */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?)
    {
        if error != nil
        {
            print("ERROR DISCOVERING CHARACTERISTICS: \(error?.localizedDescription)")
            return
        }
        
        if let characteristics = service.characteristics
        {
//            var enableValue:UInt8 = 1
//            let enableBytes = NSData(bytes: &enableValue, length: 1)
            
            for characteristic in characteristics
            {
                print("Discovered characteristic with uuid \(characteristic.uuid)")
                
                if(characteristic.uuid == CBUUID(string: ShowBabyCharacteristicUUID))
                {
                    peripheral.setNotifyValue(true, for: characteristic)
                }
                
                //peripheral.writeValue(enableBytes as Data, for: characteristic, type: .withResponse)
                
//                // Temperature Data Characteristic
//                if characteristic.UUID == CBUUID(string: Device.TemperatureDataUUID) {
//                    // Enable the IR Temperature Sensor notifications
//                    temperatureCharacteristic = characteristic
//                    sensorTag?.setNotifyValue(true, forCharacteristic: characteristic)
//                }
//                
//                // Temperature Configuration Characteristic
//                if characteristic.UUID == CBUUID(string: Device.TemperatureConfig) {
//                    // Enable IR Temperature Sensor
//                    sensorTag?.writeValue(enableBytes, forCharacteristic: characteristic, type: .WithResponse)
//                }
//                
//                if characteristic.UUID == CBUUID(string: Device.HumidityDataUUID) {
//                    // Enable Humidity Sensor notifications
//                    humidityCharacteristic = characteristic
//                    sensorTag?.setNotifyValue(true, forCharacteristic: characteristic)
//                }
//                
//                if characteristic.UUID == CBUUID(string: Device.HumidityConfig) {
//                    // Enable Humidity Temperature Sensor
//                    sensorTag?.writeValue(enableBytes, forCharacteristic: characteristic, type: .WithResponse)
//                }
            }
        }
    }
    
    
    /*
     Invoked when you retrieve a specified characteristic’s value,
     or when the peripheral device notifies your app that the characteristic’s value has changed.
     
     This method is invoked when your app calls the readValueForCharacteristic: method,
     or when the peripheral notifies your app that the value of the characteristic for
     which notifications and indications are enabled has changed.
     
     If successful, the error parameter is nil.
     If unsuccessful, the error parameter returns the cause of the failure.
     */
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?)
    {
        if error != nil
        {
            print("ERROR ON UPDATING VALUE FOR CHARACTERISTIC: \(characteristic) - \(error?.localizedDescription)")
            return
        }
        
        // extract the data from the characteristic's value property and display the value based on the characteristic type
        if let dataBytes = characteristic.value
        {
            print("Did update value for characteristic with uuid \(characteristic.uuid) to \(dataBytes.base64EncodedString())")
            
            if(dataBytes.base64EncodedString() == ShowBabyTriggerDownId)
            {
                commands.append("Trigger Down");
            }
            else if(dataBytes.base64EncodedString() == ShowBabyTriggerUpId)
            {
                commands.append("Trigger Up");
            }
            else if(dataBytes.base64EncodedString() == ShowBabyButtonDownId)
            {
                commands.append("Button Down");
            }
            else if(dataBytes.base64EncodedString() == ShowBabyButtonUpId)
            {
                commands.append("Button Up");
            }
            else if(dataBytes.base64EncodedString() == ShowBabyPumpDownId)
            {
                commands.append("Pump Down");
            }
            else if(dataBytes.base64EncodedString() == ShowBabyPumpUpId)
            {
                commands.append("Pump Up");
            }
            
            tableView.reloadData()
            
            let ip:IndexPath = IndexPath(row: commands.count - 1, section: 0)
            tableView.scrollToRow(at: ip, at: .bottom, animated: true)
            
//            if characteristic.UUID == CBUUID(string: Device.TemperatureDataUUID)
//            {
//                displayTemperature(dataBytes)
//            }
//            else if characteristic.UUID == CBUUID(string: Device.HumidityDataUUID)
//            {
//                displayHumidity(dataBytes)
//            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?)
    {
        if error != nil
        {
            print("ERROR ON WRITING VALUE FOR CHARACTERISTIC: \(characteristic) - \(error?.localizedDescription)")
            return
        }
        
        // extract the data from the characteristic's value property and display the value based on the characteristic type
        if let dataBytes = characteristic.value
        {
            print("Did write value for characteristic with uuid \(characteristic.uuid) to \(dataBytes)")
            
            //            if characteristic.UUID == CBUUID(string: Device.TemperatureDataUUID)
            //            {
            //                displayTemperature(dataBytes)
            //            }
            //            else if characteristic.UUID == CBUUID(string: Device.HumidityDataUUID)
            //            {
            //                displayHumidity(dataBytes)
            //            }
        }
    }
    
    
    
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell:UITableViewCell = self.tableView.dequeueReusableCell(withIdentifier: "cell")! as UITableViewCell
        
        let commandText = commands[indexPath.row]
        cell.textLabel?.text = commandText
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return commands.count
    }
}
