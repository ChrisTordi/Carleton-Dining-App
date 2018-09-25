//
//  ViewController.swift
//  CARL Eats
//
//  Created by Chris Tordi on 8/19/18.
//  Copyright © 2018 Chris Tordi. All rights reserved.
//

import UIKit
import Firebase

struct Food {
    let meal : String
    var foods : [String:Any]
}

class ViewController: UIViewController {
    
    @IBOutlet var diningLocBar: UITabBar!
    @IBOutlet weak var diningLocation: UILabel!
    @IBOutlet var menuTable: UITableView!
    @IBOutlet weak var favoriteDay: UITextField!
    
    var menuItems = [String]();
    var mealMaster = ["Breakfast", "Brunch", "Lunch", "Dinner", "Late Night"];
    var menuDict = ["Breakfast" : [String](), "Brunch" : [String]() , "Lunch" : [String](), "Dinner" : [String](), "Late Night" : [String]()]
    
    var days = [String]();
    var selectedDay : String?

    override func viewDidLoad() {
        super.viewDidLoad()
        //populate daypicker
        findDays();
        createDayPicker();
        createToolBar();
        
        //set up table view
        menuTable.delegate = self;
        menuTable.dataSource = self;
        
        //set up dining location tab bar
        diningLocBar.delegate = self;
        diningLocBar.selectedItem = diningLocBar.items![0]
        diningLocation.text = diningLocBar.items![0].title
        
        
        retrieveMessages()


        

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // finds days, begining with current date. populates datepicker options
    func findDays() {
        //create db ref
        let dateDB = Database.database().reference().child("dateData")
        //query date db for dates
        dateDB.observe(.childAdded) { (snapshot) in
            
            let snapshotValue = snapshot.value as! Dictionary<String,String>
            let date = snapshotValue["date"]!
            self.days.append(date);
        }
    }
    
    //return current date as string
    func getCurrentDate() -> String {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let result = formatter.string(from: date)
        return result
    }
    
    //sorts list of dates from db in chronological order
    func sortByDate(daysToBeSorted: [String]) -> [String] {
        var convertedArray: [Date] = []
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-mm-dd"// yyyy-MM-dd"
        
        //convert strings to dates
        for dat in daysToBeSorted {
            let date = dateFormatter.date(from: dat)
            if let date = date {
                convertedArray.append(date)
            }
        }
        
        let sortedDateList = convertedArray.sorted(by: { $0.compare($1) == .orderedDescending })
        var sortedStringList = [String]()
        
        //convert date list into string list
        for date in sortedDateList {
            let stringDate = dateFormatter.string(from: date)
            sortedStringList.append(stringDate)
        }
        return sortedStringList
    
    
    }
    
    //creates daypicker
    func createDayPicker() {
        let dayPicker = UIPickerView()
        dayPicker.delegate = self
        favoriteDay.inputView = dayPicker;
        favoriteDay.text = getCurrentDate()
        selectedDay = favoriteDay.text;
    }
    
    
    
    //creates tool bar for datepicker view
    func createToolBar() {
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        //done button
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(ViewController.dismissKeyBoard))
        
        toolBar.setItems([doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true;
        
        favoriteDay.inputAccessoryView = toolBar;
    }
    
    // dismisses datepicker keyboard
    //calls retrieve messages
    @objc func dismissKeyBoard() {
        //dismiss keyboard
        view.endEditing(true);
        //update table view
        retrieveMessages()
    }
    
    //rempoves old data from menu dict
    func cleanMenDict() {
        for meal in mealMaster {
            menuDict[meal]?.removeAll()
        }
    }
    
    func cleanMealMaster() {
        for i in 0..<mealMaster.count {
            print(i)
            print(mealMaster[i])
            if ((menuDict[mealMaster[i]]?.count)! < 1) {
                mealMaster.remove(at: i)
            }
        }
    }
    
    func restoreMealMaster() {
        mealMaster.removeAll()
        mealMaster = Array(arrayLiteral: "Breakfast", "Brunch", "Lunch", "Dinner")
    }
    
    
    // retrieves food data for particular day
    func retrieveMessages() {

        print("Retrieve messages has been called")
        //clears old data
        menuItems.removeAll()
        //clear old data
        cleanMenDict()
        //restore meal master
       // restoreMealMaster()
        
        
        let messageDB = Database.database().reference().child("masterData")
        
        //grabs foods with matching dates and locations
        messageDB.observe(.childAdded) { (snapshot) in
            
            let snapshotValue = snapshot.value as! Dictionary<String,String>
            let menuItem = MenuItem();
            menuItem.food = snapshotValue["food"]!
            menuItem.location = snapshotValue["location"]!
            menuItem.meal = snapshotValue["meal"]!
            menuItem.date = snapshotValue["date"]!
            
            if (self.selectedDay! == menuItem.date && self.diningLocation.text == menuItem.location) {
                var arr = self.menuDict[menuItem.meal]
                arr?.append(menuItem.food)
                self.menuDict[menuItem.meal] = arr
                self.menuTable.reloadData()
            }
            //reloads table view
            self.menuTable.reloadData()
        }
    }

}

extension ViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    //number of columns in date picker view
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    //number of choices to choose
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return days.count
    }
    
    //
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return days[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedDay = days[row];
        favoriteDay.text = selectedDay;
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //let intIndex = 1 // where intIndex < myDictionary.count
        //let index = menuDict.startIndex.advancedBy(intIndex) // index 1
        return menuDict[mealMaster[section]]!.count
        //return menuDict["Dinner"]!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "cell");
        //move down array
        print("=========================================")
        print(self.menuDict)
        cell.textLabel?.numberOfLines = 0;
        cell.textLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping;
        cell.textLabel?.text = menuDict[mealMaster[indexPath.section]]?[indexPath.row];
        
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return menuDict.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        //cleanMealMaster()
        return mealMaster[section]
    }
    
}

extension ViewController: UITabBarDelegate, UITabBarControllerDelegate {
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
       diningLocation.text = item.title
        retrieveMessages()
    }
}

