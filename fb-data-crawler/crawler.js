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

let Crawler = function (options) {
  this.crawlerOptions = options;
}

Crawler.prototype.init = async function() {
  this.chromeOptions = new chrome.Options({'useAutomationExtension': false});
  this.chromeOptions.setChromeBinaryPath(global.process.env.CHROME_PATH || chromePath);

  this.chromeOptions.addArguments('no-sandbox');
  this.chromeOptions.addArguments('disable-dev-shm-usage');
  this.chromeOptions.addArguments('disable-notifications');
  this.chromeOptions.addArguments('disable-extensions');
  this.chromeOptions.addArguments('disable-infobars');
  this.chromeOptions.addArguments(`log-path=${path.resolve(__dirname), 'chromedriver.log'}`);

  if (!this.crawlerOptions.showInterface) {
    this.chromeOptions.headless();
  }
  if (this.crawlerOptions.downloadDir) {
    this.chromeOptions.setUserPreferences({'download.default_directory': this.crawlerOptions.downloadDir});
  }

  this.chromeOptions.windowSize(screen);
  this.driver = await new Builder()
                .forBrowser('chrome')
                .setChromeOptions(this.chromeOptions)
                .build();
  this.targetID = this.crawlerOptions.targetID || null;

  // Alow downloading in headless mode
  const cmd = new command.Command("SEND_COMMAND")
                  .setParameter("cmd", "Page.setDownloadBehavior")
                  .setParameter("params", {'behavior': 'allow', 'downloadPath': this.crawlerOptions.downloadDir});

  await this.driver.getExecutor().defineCommand("SEND_COMMAND", "POST", `/session/${(await this.driver.getSession()).getId()}/chromium/send_command`);
  await this.driver.execute(cmd);
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

Crawler.prototype.getCookies = async function() {
  return await this.driver.manage().getCookies();
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

  // Choosing JSON type
  await this.driver.findElement(By.css('[data-testid="dyi/sections"] ._5aj7 > div:nth-child(2) a')).click();
  await this.driver.sleep(1 * 1000);
  await this.driver.findElement(By.css('ul._54nf[role="menu"] > li:nth-child(2)')).click();

  // if (from || to) {
  //   await this.driver.findElement(By.xpath('//span[@endinputname="start_time"]')).click();
  // }

  // // Set date range
  // let now = new Date();
  // if (from) {
  //   let tmp = new Date(`${from.getUTCFullYear()}-${from.getUTCMonth()}-${from.getUTCDate()}`);
  //   await this.driver.findElement(By.xpath('//*[string(@selectdate)][string(@maxyear)]/div[2]')).click();
  //   await this.driver.findElement(By.xpath(`//div[not(contains(@class, "hidden_elem"))]//*[contains(@class, "uiContextualLayer")]//ul[@role="menu"]/li[${now.getUTCFullYear() - tmp.getUTCFullYear() + 1}]`)).click();
  //   await this.driver.findElement(By.xpath('//*[string(@selectdate)][string(@maxyear)]/div[1]')).click();
  //   await this.driver.findElement(By.xpath(`//div[not(contains(@class, "hidden_elem"))]//*[contains(@class, "uiContextualLayer")]//ul[@role="menu"]/li[${tmp.getUTCFullYear() + 1}]`)).click();
  //   await this.driver.findElement(By.xpath(`//div[not(contains(@class, "hidden_elem"))]//*[contains(@class, "uiContextualLayer")]//div[contains(@class, "_ikh")]/div[contains(@class, "_4bl7")][1]/a[string(@date)][10]`)).click();

  // }
  // if (to) {
  //   let tmp = new Date(`${to.getUTCFullYear()}-${to.getUTCMonth()}-${to.getUTCDate()}`);
  //   await this.driver.executeScript(`document.querySelector('[name="end_time"]').setAttribute('value', ${tmp.getTime()})`);
  // }

  // process.exit();
  // Trigger downloading
  await this.driver.findElement(By.css('div._4bl7 > [data-testid="dyi/sections/create"]')).click();
  return this.targetID;
}

Crawler.prototype.checkArchiveAvailable = async function() {
  await this.driver.navigate().refresh();
  await this.driver.findElement(By.css('li[data-testid="dyi/navigation/all_archives"]')).click();
  return await this.isElementExisting(`div[data-testid="dyi/archives"] div._86sv._4-u3._4-u8:nth-last-child(${this.targetID}) ._ikh ._4bl7 button`);
}

Crawler.prototype.triggerArchiveDownload = async function() {
  await this.driver.findElement(By.css('li[data-testid="dyi/navigation/all_archives"]')).click();
  await this.driver.findElement(By.css(`div[data-testid="dyi/archives"] div._86sv._4-u3._4-u8:nth-last-child(${this.targetID}) ._ikh ._4bl7 button`)).click();
  await this.driver.sleep(2 * 1000);
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

Crawler.prototype.captureScreen = async function(filepath) {
  let image = await this.driver.takeScreenshot();
  await fs.writeFile(filepath, image, 'base64');
}

Crawler.prototype.close = async function() {
  await this.driver.close();
}

module.exports = Crawler;
