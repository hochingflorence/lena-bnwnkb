// Function to generate random int between min (inclusive) and max (inclusive)
function getRandomInt(min, max) {
    min = Math.ceil(min);
    max = Math.floor(max);
    return Math.floor(Math.random() * (max - min + 1)) + min;
}

// Assign user to experimental condition
function assignToCondition() {

  // Calculate random number between 0 and 3
  var randomNumber = getRandomInt(0, 3);
  var experimentURL = "empty";

// Set link accordingly
  switch (randomNumber) {
  case 0:
    experimentURL = "http://ca-uncanny-c1.herokuapp.com";
    break;
  case 1:
    experimentURL = "http://ca-uncanny-c2.herokuapp.com";
    break;
  case 2:
    experimentURL = "http://ca-uncanny-c3.herokuapp.com";
    break;
  case 3:
    experimentURL = "http://ca-uncanny-c4.herokuapp.com";
    break;
  }

  // Redirect user to experimental condition
  window.open(experimentURL);
}
