// ------- Data & caching utilities -----//
// We use json data as a quick & dirty solution for now

const path = require('path');
const fs = require('fs');
const fspromises = fs.promises;

function Database(options) {
  this.dataDir = options.data_dir;
  this.dataFilePath = path.resolve(this.dataDir, 'data.json');
}

Database.prototype.init = async function() {
  let isDatabaseFileExisting = false;
  try {
    await fspromises.stat(this.dataFilePath);
    isDatabaseFileExisting = true;
  } catch (err) {}

  if (!isDatabaseFileExisting) {
    await fspromises.writeFile(this.dataFilePath, JSON.stringify({}));
  }
  this.database = require(this.dataFilePath);
}

Database.prototype.getCachedSession = function(username) {
  if (this.database[username] && this.database[username].session) {
    return this.database[username].session;
  } else {
    return false;
  }
}

Database.prototype.cacheSession = async function(username, session) {
  this.database[username] = this.database[username] || {};
  this.database[username].session = session;

  // It's not neccessary to write the cache file every request
  // We write once more when the program is suspended
  try {
    await fspromises.writeFile(this.dataFilePath, JSON.stringify(this.database, null, 2));
  } catch (err) {
    console.error(err);
  }
}

module.exports = Database;
