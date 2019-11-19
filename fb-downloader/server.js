/** ----------------------------------------------- */
// THIS PROGRAM CREATE A SERVER THAT WILL
// 1. Download Facebook database
// 2. Upload Facebook database to the callback link
/** ----------------------------------------------- */

//------- Server dependencies ------------//
const DEBUG_MODE = global.process.env.DEBUG_MODE || false;
// server
const express = require('express');
const PORT = global.process.env.PORT || 8080;
let hasReceivedSignterm = false;
// app logic
const Database = require('./database.js');
const FileStore = require('./file-store.js');
const Downloader = require('./downloader.js');
const S3Service = require('./s3-service');
const path = require('path');
const DATA_DIR = global.process.env.DATA_DIR || path.resolve(__dirname, 'data');
const ARCHIVE_BUCKET = global.process.env.ARCHIVE_BUCKET;
const axios = require('axios');
const uuidv4 = require('uuid/v4');
//------------- Server main API ---------------//
(async function create() {

  // Utilities
  async function wait(milliseconds) {
    return new Promise(resolve => setTimeout(resolve, milliseconds));
  }

  // Database intialization
  const database = new Database({data_dir: DATA_DIR});
  await database.init();

  // FileStore initialization
  const fileStore = new FileStore({data_dir: DATA_DIR});
  await fileStore.init();

  // S3 initialization
  const s3Service = new S3Service({bucket_name: ARCHIVE_BUCKET});
  await s3Service.init();

  // Server creation
  const app = express();
  app.use(express.json());

  //------------- Server main APIs ---------------//
  app.post('/api/download', async (req, res) => {
    let identifier = req.body.identifier;
    let username = req.body.username;
    let password = req.body.password;
    let from = req.body.from;
    let to = new Date().getTime();
    let callbackUrl = req.body.callback;
    let isAlreadyRespond = false;
  
    if (!identifier || !username || !password) {
      res.status('400').send({message: 'missing parameter'});
      return;
    }

    try {
      let downloadDir = await fileStore.createRandomDir()
      let downloader = new Downloader({
        showInterface: DEBUG_MODE,
        downloadDir: downloadDir,
        targetID: null
      });
      await downloader.init();
  
      let cachedSession = database.getCachedSession(username);
      let isAbleToLogIn;
      if (cachedSession) {
        isAbleToLogIn = await downloader.loginByCookies(cachedSession, password);
      } else {
        isAbleToLogIn = await downloader.loginByAuthenticationCredential(username, password);
        await database.cacheSession(username, await downloader.getCookies());
      }

      if (!isAbleToLogIn) {
        res.status(400).send({message: 'wrong username & password', code: 1001});
        await downloader.close();
        return;
      }

      res.send({message: 'login successfully & data backup is scheduled!'});
      isAlreadyRespond = true;
  
      await downloader.goToArchiveSection();
      await downloader.triggerArchiveRequest(from, to);
  
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
          await downloader.captureScreen(path.resolve(DATA_DIR, `${identifier}-${username}-${uuidv4()}.png`));
          throw new Error('Can not download the file');
        }
      }
  
      console.info(`Finish downloading the archive!`);
      let filePath = path.resolve(downloadDir, await fileStore.getFirstFileNameFromDir(downloadDir));
      console.info(`Your archive is at ${filePath}`);
      await downloader.close();

      let s3Key = `${identifier}/${from ? from : 0}-${to}`;
      await s3Service.upload(filePath, s3Key, identifier, from ? from : 0, to);
      if (callbackUrl) {
        await axios.post(callbackUrl, {identifier, from, to, s3Key});
      }
      fileStore.removeDirAndFile(filePath, downloadDir);
    } catch (err) {
      if (isAlreadyRespond) {
        console.log('WARNING: something wrong');
      } else {
        res.status(400).send({message: 'server error', code: 1000});
      }
      console.log(err);
    }
  });
  
  //------------- Server health check API ---------------//
  
  app.get('/api/healthz', (req, res) => {
    res.status(hasReceivedSignterm ? 500 : 200).end();
  });
  
  global.process.on('SIGTERM', function () {
    hasReceivedSignterm = true;
  });

  //------------- Let's run it ---------------//
  app.listen(PORT, () => console.log(`Facebook data fetcher app is listening on port ${PORT}!`))  
})();
