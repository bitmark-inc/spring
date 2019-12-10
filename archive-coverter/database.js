const path = require('path');
let sqlite3 = require('sqlite3').verbose();

const DB_PATH = process.env.DB_PATH || path.resolve(__dirname, './database/data.sqlite')

module.exports = {
  init: async function() {
    return new Promise((resolve, reject) => {
      var db = new sqlite3.Database(DB_PATH, sqlite3.OPEN_READWRITE | sqlite3.OPEN_CREATE, function() {
        resolve(db);
      });
    });
  }
}
