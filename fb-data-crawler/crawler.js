require('chromedriver');
const chrome = require('selenium-webdriver/chrome');
const webdriver = require('selenium-webdriver');
const Builder = webdriver.Builder;
const By = webdriver.By;
const Key = webdriver.Key;
const screen = {width: 1024, height: 1024};
const sessionCache = require('./session-cache.json');

const { promisify } = require('util')
const writeFileAsync = promisify(fs.writeFile);

function getSessionFromCache(email) {
  if (sessionCache[email]) {
    return sessionCache[email];
  } else {
    return false;
  }
}

function writeSessionCache(email, content) {
  sessionCache[email] = content;
  await writeFileAsync('./session-cache.json')
}

let Crawler = function (options) {
  this.crawlerOptions = options;
}

Crawler.prototype.init = async function(options) {
  this.chromeOptions = new chrome.Options();

  this.chromeOptions.windowSize(screen);
  this.chromeOptions.addArguments('--disable-notifications');
  if (!this.crawlerOptions.showInterface) {
    this.chromeOptions.headless();
  }
  if (this.crawlerOptions.downloadDir) {
    this.chromeOptions.setUserPreferences({'download.default_directory': this.crawlerOptions.downloadDir});
  }
  this.driver = await new Builder().forBrowser('chrome').setChromeOptions(this.chromeOptions).build();
  this.targetID = this.crawlerOptions.targetID || null;
}

Crawler.prototype.isElementExisting = async function(css) {
  let elements = await this.driver.findElements(By.css(css));
  return elements.length !== 0;
}

Crawler.prototype.loginByAuthenticationCredential = async function(email, password) {
  this.facebookPassword = password;
  await this.driver.get('https://facebook.com');
  if (await this.isElementExisting('#email')) {
    await this.driver.findElement(By.css('#email')).sendKeys(email);
    await this.driver.findElement(By.css('#pass')).sendKeys(password, Key.RETURN);
  } else {
    await this.driver.findElement(By.css('input[name="email"]')).sendKeys(email);
    await this.driver.findElement(By.css('input[name="pass"]')).sendKeys(password, Key.RETURN);
  }
}

Crawler.prototype.loginByCookies = async function(cookies, password) {
  this.facebookPassword = password;
  await this.driver.get('https://facebook.com');
  for (let i = 0; i < cookies.length; i++) {
    await this.driver.manage().addCookie(cookies[i]);
  }
}

Crawler.prototype.goToArchiveSection = async function() {
  await this.driver.get('https://www.facebook.com/settings?tab=your_facebook_information');
  let dataLink = await this.driver.findElement(By.css('ul.fbSettingsList > li:nth-child(2) > a.fbSettingsListLink')).getAttribute('href');
  await this.driver.get(dataLink);
}

Crawler.prototype.triggerArchiveRequest = async function(from, to) {
  // Go to the list of archive
  await this.driver.findElement(By.css('li[data-testid="dyi/navigation/all_archives"]')).click();
  let elements = await this.driver.findElements(By.css('div[data-testid="dyi/archives"] div._86sv._4-u3._4-u8'));
  this.targetID = elements.length + 1;

  await this.driver.findElement(By.css('li[data-testid="dyi/navigation/new_archive"]')).click();
  await this.driver.findElement(By.css('div._4bl7 > [data-testid="dyi/sections/create"]')).click();
  return this.targetID;
}

Crawler.prototype.checkArchiveAvailable = async function() {
  await this.driver.findElement(By.css('li[data-testid="dyi/navigation/all_archives"]')).click();
  return await this.isElementExisting(`div[data-testid="dyi/archives"] div._86sv._4-u3._4-u8:nth-last-child(${this.targetID}) ._ikh ._4bl7 button`);
}

Crawler.prototype.triggerArchiveDownload = async function() {
  await this.driver.findElement(By.css('li[data-testid="dyi/navigation/all_archives"]')).click();
  await this.driver.findElement(By.css(`div[data-testid="dyi/archives"] div._86sv._4-u3._4-u8:nth-last-child(${this.targetID}) ._ikh ._4bl7 button`)).click();
  if (await this.isElementExisting('#ajax_password')) {
    await this.driver.findElement(By.css('#ajax_password')).sendKeys(this.facebookPassword, Key.RETURN);
  }
  return true;
}

Crawler.prototype.logout = async function() {
  await this.driver.findElement(By.css('#logoutMenu')).click();
  await this.driver.sleep(2000);
  await this.driver.findElement(By.css('div[data-ownerid="pageLoginAnchor"] ul._54nf li:last-child')).click();
}

Crawler.prototype.quit = async function() {
  await this.driver.quit();
}

module.exports = Crawler;
