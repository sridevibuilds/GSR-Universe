const bcrypt = require("bcrypt");

bcrypt.hash("Faculty@123", 10).then(hash => {
    console.log(hash);
});