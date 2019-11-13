const program = require('commander');
program.version('0.0.1');

program
  .option('-u, --username <username>', 'Facebook username')
  .option('-p, --password <password>', 'Facebook password')
  .option('-r, --request', 'Request only - this command return id of the archive')
  .option('-d, --download <id>', 'Download only - this command requires archive id, gotten from command with -r option')
  .option('-i, --interface', 'Show interface')
  .option('-c, --cache', 'Allow local caching of log in session');

program.parse(process.argv);

if (!program.username) {
  console.log('Username is required!');
  process.exit(1);
}

if (!program.password) {
  console.log('Password is required!');
  process.exit(1);
}

if (program.request && program.download) {
  console.log('Can not use both option at the same time');
  process.exit();
}


// UTILITIES
const fs = require('fs');
const fspromise = fs.promises;
const uuidv4 = require('uuid/v4');
const path = require('path');

async function wait(milliseconds) {
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve();
    }, milliseconds);
  });
}

async function createRandomDir() {
  let dirName = uuidv4();
  let dirPath = path.resolve(__dirname, 'downloaded-files', dirName);
  await fspromise.mkdir(dirPath);
  return dirPath;
}

async function getFirstFileNameFromDir(dirPath) {
  let files = await fspromise.readdir(dirPath);
  return files[0];
}

async function isFileReadableYet(filePath) {
  try {
    await fspromise.access(filePath, fs.constants.W_OK | fs.constants.R_OK);
    return true;
  } catch (err) {
    console.log(err);
    return false;
  }
}

async function removeDirAndFile(filePath, dirPath) {
  if (filePath) {
    await fspromise.unlink(filePath);
  }
  if (dirPath) {
    await fspromise.rmdir(dirPath);
  }
}

// MAIN FLOW
const Crawler = require('./crawler.js');

(async function execute() {
  try {
    let downloadDir = await createRandomDir()
    let crawler = new Crawler({
      showInterface: program.interface,
      downloadDir: downloadDir,
      targetID: program.download,
      cache: program.cache
    });
    await crawler.init();

    // If both are true or not specified at all, mean doing both
    let doBoth = (program.request && program.download) || (!program.request && !program.download);
    if (doBoth) {
      program.request = true;
      program.download = true;
    }

    console.info('Logging in now...');
    await crawler.loginByAuthenticationCredential(program.username, program.password);
    await crawler.goToArchiveSection();

    // If needed to request the archive
    if (program.request) {
      await crawler.triggerArchiveRequest();
      console.info(`Request archive successfully, archive ID is ${crawler.targetID}.`);
    }

    // if not download now, then just quit then
    if (!program.download) {
      if (!program.cache) { // if caching is enable, let's not log out
        await crawler.logout();
      }
      await crawler.quit();
      await removeDirAndFile(null, downloadDir);
      return;
    }

    // Continue here mean the crawler should wait and download
    while (!(await crawler.checkArchiveAvailable())) {
      console.info(`Archive not found yet, the program will sleep for a bit before trying again...`);
      await wait(30 * 1000);
    }

    await crawler.triggerArchiveDownload();
    console.info(`Archive is being downloaded, please wait...`);

    // Let's give the web drive some time to download first piece
    let filename;
    while (!filename || filename.indexOf('crdownload') !== -1) {
      await wait(5*1000);
      filename = await getFirstFileNameFromDir(downloadDir);
      if (!filename) {
        console.log(`Oops! Something wrong! The file has not appeared`);
        await crawler.captureScreen(path.resolve(__dirname, 'debug.png'));
      }
    }

    console.info(`Finish downloading the archive!`);
    let filePath = path.resolve(downloadDir, await getFirstFileNameFromDir(downloadDir));
    console.info(`Your archive is at ${filePath}`);

    console.info(`Exiting the program in 1 minute...`);
    // Give me some buffer time to debug for now
    await wait(1 * 60 * 1000);

    // webdriver finished downloading the file now, should exit
    if (!program.cache) { // if caching is enable, let's not log out
      await crawler.logout();
    }
    await crawler.quit();

  } catch (err) {
    console.info('Error happened!');
    console.error(err);
  }
})();
