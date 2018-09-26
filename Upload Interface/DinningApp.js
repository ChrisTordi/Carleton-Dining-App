/*****
******/
//API config
var config = {
    apiKey: "AIzaSyA2cUx7BOzK-nucCvHuG4y7rR6KcpCutFY",
    authDomain: "flash-chat-883d0.firebaseapp.com",
    databaseURL: "https://flash-chat-883d0.firebaseio.com",
    projectId: "flash-chat-883d0",
    storageBucket: "flash-chat-883d0.appspot.com",
    messagingSenderId: "694183600230"
};

//initialize db
firebase.initializeApp(config);
var database = firebase.database();

//var filePath = "/DinningApp/Dining%20App/" + "2018-09-12" + ".json"
var filePath = "/DinningApp/Dining%20App/" + getCurrentDate() + ".json"
removeDates()
readTextFile(filePath)
archiveMasterData()


/**
*
* Returns the current date
*/
function getCurrentDate() {
    var today = new Date();
    var dd = today.getDate();
    var mm = today.getMonth()+1; //January is 0!
    var yyyy = today.getFullYear();

    if(dd<10) {
        dd = '0'+dd
    }

    if(mm<10) {
        mm = '0'+mm
    }

    today = yyyy + '-' + mm + '-' + dd;
    return today;

}

/**
*
* Reads json file and passes data to parser method
*/
function readTextFile(file) {
    var rawFile = new XMLHttpRequest();
    rawFile.open("GET", file, false);
    rawFile.onreadystatechange = function ()
    {
        if(rawFile.readyState === 4)
        {
            if(rawFile.status === 200 || rawFile.status == 0)
            {
                var allText = rawFile.responseText;
                var obj = JSON.parse(allText);
                var str = JSON.stringify(obj, null, 2);
                parseJSON(obj);
            }
        }
    }
    rawFile.send(null);
}

/**
*
* Parses json file and calls db write methods
*
*/
function parseJSON(data) {
    document.write(data)
    for (var date in data) {
        if (data.hasOwnProperty(date)) {
            //console.log(date + " -> " + data[date]);
            var day = data[date];
            //console.log("Date: " + date)
            writeDateData(date);
            for (var meal in day) {
                if (day.hasOwnProperty(meal)) {
                    //console.log(meal + " -> " + day[meal])
                    var mealOfTheDay = day[meal];
                    for (var loc in mealOfTheDay) {
                        if (mealOfTheDay.hasOwnProperty(loc)) {
                            //console.log(loc + " -> " + mealOfTheDay[loc])
                            var menuItems = mealOfTheDay[loc];
                            if (menuItems.length > 1) {
                                for (var menuItem in menuItems) {
                                   writeUserData(date, meal, loc, menuItems[menuItem])
                                }
                            } else {
                                writeUserData(date, meal, "Burton", menuItems[0])
                                writeUserData(date, meal, "East Hall", menuItems[0])
                                writeUserData(date, meal, "Sayles Hill Café", menuItems[0])
                                writeUserData(date, meal, "Weitz Café", menuItems[0])
                                /*console.log("There should be no specials at this time")
                                console.log("Date" + date)
                                console.log("Meal" + meal)
                                console.log("Location" + loc)
                                console.log(menuItems[0])*/

                            }
                        }
                    }
                }
            }
        }
    }
}



/**
*
* Writes food data to masterData database
*
*/
function writeUserData(date, meal, location, food) {
  firebase.database().ref(`masterData`).push().set({
    date : date,
    meal : meal,
    location : location,
    food : food
  });
 document.write("Successfully wrote " + food + " to master db")
}

/**
* Writes food to archive database
*
*/
function writeToArchive(food) {
    firebase.database().ref('foodArchive').push().set({
      food : food
    });
}


/**
* Writes date info to date db
*
*
*/
function writeDateData(date) {
    firebase.database().ref(`dateData`).push().set({
      date : date
    });
   document.write("Successfully wrote " + date + " to date db")
}



/**
*
* Maintains date database. Removes dates that are prior to current date
*
*/
function removeDates() {
    firebase.database().ref(`dateData`).remove()
}



/**
*
* Maintains master database. Archives food by moving to archive db
*
*/
function archiveMasterData() {
    var query = firebase.database().ref('masterData');
    query.once("value")
        .then(function(snapshot) {
        snapshot.forEach(function(childSnapshot) {
          var key = childSnapshot.key;
          // childData will be the actual contents of the child
          var childData = childSnapshot.val();
          var childDate = childData.date;
          console.log("child date " + childDate);
          if (Date.parse(childDate) < Date.parse(getCurrentDate())) {
              console.log("Archive")
              writeToArchive(childData.food);
              firebase.database().ref('masterData').child(key).remove();
          }
        });
    });
}
