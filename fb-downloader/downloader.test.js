const path = require('path');
const Database = require('./database.js');
const FileStore = require('./file-store.js');
const Downloader = require('./downloader.js');

const DATA_DIR = path.resolve(__dirname, 'data');
const USERNAME = 'le.hoainam1910@outlook.com';
const PASSWORD = '8xvi7rQX8';
const FROM = null;
const TO = null;

async function wait(milliseconds) {
  return new Promise(resolve => setTimeout(resolve, milliseconds));
}

(async function execute() {
   // Database intialization
   const database = new Database({data_dir: DATA_DIR});
   await database.init();

   // FileStore initialization
   const fileStore = new FileStore({data_dir: DATA_DIR});
   await fileStore.init();

  let downloadDir = await fileStore.createRandomDir()
  let downloader = new Downloader({
    showInterface: true,
    downloadDir: downloadDir,
    targetID: 7
  });
  await downloader.init();

  let cachedSession = database.getCachedSession(USERNAME);
  if (cachedSession) {
    await downloader.loginByCookies(cachedSession, PASSWORD);
  } else {
    await downloader.loginByAuthenticationCredential(USERNAME, PASSWORD);
    await database.cacheSession(USERNAME, await downloader.getCookies());
  }

  await downloader.goToArchiveSection();
  // await downloader.triggerArchiveRequest(FROM, TO);

  while (!(await downloader.checkArchiveAvailable())) {
    console.info(`Archive not found yet, the program will sleep for a bit before trying again...`);
    await wait(30 * 1000);
  }
  await downloader.triggerArchiveDownload();
  console.info(`Archive is being downloaded, please wait...`);

  // Let's give the web drive some time to download first piece
  let filename = 'crdownload';
  while (filename.indexOf('crdownload') !== -1) {
    await wait(5*1000);
    filename = await fileStore.getFirstFileNameFromDir(downloadDir);
    if (!filename) {
      console.log(`Oops! Something wrong! The file has not appeared`);
      await downloader.captureScreen(path.resolve(DATA_DIR, `${identifier}-${USERNAME}-${uuidv4()}.png`));
      throw new Error('Can not download the file');
    }
  }

  console.info(`Finish downloading the archive!`);
  let filePath = path.resolve(downloadDir, await fileStore.getFirstFileNameFromDir(downloadDir));
  console.info(`Your archive is at ${filePath}`);
  await downloader.close();
})();
