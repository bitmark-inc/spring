const chromePath = require('chromedriver').path;
const chrome = require('selenium-webdriver/chrome');
const webdriver = require('selenium-webdriver');
const command = require('selenium-webdriver/lib/command');
const Builder = webdriver.Builder;
const By = webdriver.By;
const Key = webdriver.Key;
const screen = {width: 1024, height: 1024};
const fs = require('fs').promises;
const path = require('path');

let Downloader = function (options) {
  this.downloaderOptions = options;
}

Downloader.prototype.init = async function() {
  this.chromeOptions = new chrome.Options({'useAutomationExtension': false});
  if (global.process.env.CHROME_PATH) {
    this.chromeOptions.setChromeBinaryPath(global.process.env.CHROME_PATH);
  }

  this.chromeOptions.addArguments('no-sandbox');
  this.chromeOptions.addArguments('disable-dev-shm-usage');
  this.chromeOptions.addArguments('disable-notifications');
  this.chromeOptions.addArguments('disable-extensions');
  this.chromeOptions.addArguments('disable-infobars');
  this.chromeOptions.addArguments(`log-path=${path.resolve(__dirname), 'chromedriver.log'}`);

  if (!this.downloaderOptions.showInterface) {
    this.chromeOptions.headless();
  }
  if (this.downloaderOptions.downloadDir) {
    this.chromeOptions.setUserPreferences({'download.default_directory': this.downloaderOptions.downloadDir});
  }

  this.chromeOptions.windowSize(screen);
  this.driver = await new Builder()
                .forBrowser('chrome')
                .setChromeOptions(this.chromeOptions)
                .build();
  this.targetID = this.downloaderOptions.targetID || null;

  // Alow downloading in headless mode
  const cmd = new command.Command("SEND_COMMAND")
                  .setParameter("cmd", "Page.setDownloadBehavior")
                  .setParameter("params", {'behavior': 'allow', 'downloadPath': this.downloaderOptions.downloadDir});

  await this.driver.getExecutor().defineCommand("SEND_COMMAND", "POST", `/session/${(await this.driver.getSession()).getId()}/chromium/send_command`);
  await this.driver.execute(cmd);
}

Downloader.prototype.isElementExisting = async function(css) {
  let elements = await this.driver.findElements(By.css(css));
  return elements.length !== 0;
}

Downloader.prototype.loginByAuthenticationCredential = async function(email, password) {
  this.facebookPassword = password;
  await this.driver.get('https://facebook.com');
  if (await this.isElementExisting('#email')) {
    await this.driver.findElement(By.css('#email')).sendKeys(email);
    await this.driver.findElement(By.css('#pass')).sendKeys(password, Key.RETURN);
  } else {
    await this.driver.findElement(By.css('input[name="email"]')).sendKeys(email);
    await this.driver.findElement(By.css('input[name="pass"]')).sendKeys(password, Key.RETURN);
  }
  let currentUrl = await this.driver.getCurrentUrl();
  return currentUrl.indexOf('login_attempt') === -1;
}

Downloader.prototype.loginByCookies = async function(cookies, password) {
  this.facebookPassword = password;
  await this.driver.get('https://facebook.com');
  for (let i = 0; i < cookies.length; i++) {
    await this.driver.manage().addCookie(cookies[i]);
  }
  return true;
}

Downloader.prototype.getCookies = async function() {
  return await this.driver.manage().getCookies();
}

Downloader.prototype.goToArchiveSection = async function() {
  await this.driver.get('https://www.facebook.com/settings?tab=your_facebook_information');
  let dataLink = await this.driver.findElement(By.css('ul.fbSettingsList > li:nth-child(2) > a.fbSettingsListLink')).getAttribute('href');
  await this.driver.get(dataLink);
}

Downloader.prototype._setTimestampValue = async function(from) {
  let now = new Date();
  let tmp = new Date(`${from.getUTCFullYear()}-${from.getUTCMonth() + 1}-${from.getUTCDate()}`);

  let markAllContextMenuAsOld = async () => {
    await this.driver.executeScript(`
      document.querySelectorAll('.uiContextualLayerPositioner').forEach(el => el.setAttribute('is-old', 'true'))
    `);
  }

  let getNewContextMenu = async () => {
    // return await this.driver.findElement(By.css('.uiContextualLayerPositioner:not(.is-old)'));
    return await this.driver.findElement(By.xpath('//*[contains(@class, "uiContextualLayerPositioner")][not(@is-old)]'));
  }

  // Firstly, let's mark all context menu as old
  await markAllContextMenuAsOld();
  // Click the date time box
  await this.driver.findElement(By.css('span[endinputname="start_time"]')).click();
  // Get new menu & also mark it as old menu
  let datePicker = await getNewContextMenu();
  await markAllContextMenuAsOld();
  // Now click the year picker
  await datePicker.findElement(By.xpath('.//*[string(@selectdate)][string(@maxyear)][string(@minyear)][1]/div[2]')).click();
  let yearPicker = await getNewContextMenu();
  await markAllContextMenuAsOld();
  await yearPicker.findElement(By.xpath(`.//ul/li[${now.getUTCFullYear() - tmp.getUTCFullYear() + 1}]/a`)).click();
  // Now click the month picker
  await datePicker.findElement(By.xpath('.//*[string(@selectdate)][string(@maxyear)][string(@minyear)][1]/div[1]')).click();
  let monthPicker = await getNewContextMenu();
  await markAllContextMenuAsOld();
  await monthPicker.findElement(By.xpath(`.//ul/li[${tmp.getUTCMonth() + 1}]`)).click();
  // Now pick the date
  let firstDatePlate = await datePicker.findElement(By.xpath(`(.//*[string(@daterestraints)])[1]`));
  await firstDatePlate.findElement(By.xpath(`(.//a[string(@date)])[${tmp.getUTCDate()}]`)).click();
  // Hit OK
  await datePicker.findElement(By.xpath(`.//button[3]`)).click();
}

Downloader.prototype.triggerArchiveRequest = async function(fromTimestamp) {
  // Go to the list of archive
  await this.driver.findElement(By.css('li[data-testid="dyi/navigation/all_archives"]')).click();
  let elements = await this.driver.findElements(By.css('div[data-testid="dyi/archives"] div._86sv._4-u3._4-u8'));
  this.targetID = elements.length + 1;

  await this.driver.findElement(By.css('li[data-testid="dyi/navigation/new_archive"]')).click();

  // Choosing JSON type
  await this.driver.findElement(By.css('[data-testid="dyi/sections"] ._5aj7 > div:nth-child(2) a')).click();
  await this.driver.sleep(1 * 1000);
  await this.driver.findElement(By.css('ul._54nf[role="menu"] > li:nth-child(2)')).click();

  // Set from timestamp
  if (fromTimestamp) {
    await this._setTimestampValue(new Date(fromTimestamp));
  }

  // Trigger downloading
  await this.driver.findElement(By.css('div._4bl7 > [data-testid="dyi/sections/create"]')).click();
  return this.targetID;
}

Downloader.prototype.checkArchiveAvailable = async function() {
  await this.driver.navigate().refresh();
  await this.driver.findElement(By.css('li[data-testid="dyi/navigation/all_archives"]')).click();
  return await this.isElementExisting(`div[data-testid="dyi/archives"] div._86sv._4-u3._4-u8:nth-last-child(${this.targetID}) ._ikh ._4bl7 button`);
}

Downloader.prototype.triggerArchiveDownload = async function() {
  await this.driver.findElement(By.css('li[data-testid="dyi/navigation/all_archives"]')).click();
  await this.driver.findElement(By.css(`div[data-testid="dyi/archives"] div._86sv._4-u3._4-u8:nth-last-child(${this.targetID}) ._ikh ._4bl7 button`)).click();
  await this.driver.sleep(2 * 1000);
  if (await this.isElementExisting('#ajax_password')) {
    await this.driver.findElement(By.css('#ajax_password')).sendKeys(this.facebookPassword, Key.RETURN);
  }
  return true;
}

Downloader.prototype.logout = async function() {
  await this.driver.findElement(By.css('#logoutMenu')).click();
  await this.driver.sleep(2000);
  await this.driver.findElement(By.css('div[data-ownerid="pageLoginAnchor"] ul._54nf li:last-child')).click();
}

Downloader.prototype.captureScreen = async function(filepath) {
  let image = await this.driver.takeScreenshot();
  await fs.writeFile(filepath, image, 'base64');
}

Downloader.prototype.close = async function() {
  await this.driver.close();
}

module.exports = Downloader;
