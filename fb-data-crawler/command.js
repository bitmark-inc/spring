const program = require('commander');
program.version('0.0.1');

program
  .option('-u, --username <username>', 'Facebook username')
  .option('-p, --password <password>', 'Facebook password')
  .option('-r, --request', 'Request only - this command return id of the archive')
  .option('-d, --download <id>', 'Download only - this command requires archive id, gotten from command with -r option')
  .option('-i, --interface', 'Show interface');

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
async function wait(milliseconds) {
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve();
    }, milliseconds);
  });
}

// MAIN FLOW
const Crawler = require('./crawler.js');

(async function execute() {
  try {
    let crawler = new Crawler({
      showInterface: program.interface,
      downloadDir: __dirname,
      targetID: program.download
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

    // If needed to request the archive
    if (program.request) {
      await crawler.goToArchiveSection();
      await crawler.triggerArchiveRequest();
      console.info(`Request archive successfully, archive ID is ${crawler.targetID}.`);
    }

    // if not download now, then just quit then
    if (!program.download) {
      await crawler.quit();
      return;
    }

    // Continue here mean the crawler should wait and download
    while (!(await crawler.checkArchiveAvailable())) {
      console.info(`Archive not found yet, the program will sleep for a bit...`);
      await wait(30 * 1000);
    }

    await crawler.triggerArchiveDownload();
    console.info(`Archive is being downloaded, please wait...`);
    await wait(5 * 60 * 1000);
    await crawler.quit();
    console.info(`Finish downloading the archive!`);

  } catch (err) {
    console.info('Error happened!');
    console.error(err);
  }


})();


