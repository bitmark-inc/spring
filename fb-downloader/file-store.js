//------- Utilities for file processing--//
const path = require('path');
const fs = require('fs');
const fspromises = fs.promises;
const uuidv4 = require('uuid/v4');

function FileStore(options) {
  this.dataDir = options.data_dir;
}

FileStore.prototype.init = async function() {}

FileStore.prototype.createRandomDir = async function() {
  let dirPath = path.resolve(this.dataDir, uuidv4());
  await fspromises.mkdir(dirPath);
  return dirPath;
}

FileStore.prototype.getFirstFileNameFromDir = async function(dirPath) {
  let files = await fspromises.readdir(dirPath);
  return files[0];
}

FileStore.prototype.removeDirAndFile = async function(filePath, dirPath) {
  if (filePath) {
    await fspromises.unlink(filePath);
  }
  if (dirPath) {
    await fspromises.rmdir(dirPath);
  }
}

module.exports = FileStore;
