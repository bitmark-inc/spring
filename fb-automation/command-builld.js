let fspromise = require('fs').promises;
let path = require('path');
let filePath = path.resolve(__dirname, 'commands.json');

function buildLoginPage() {
  let loginPage = {};
  loginPage.name = `login`;
  loginPage.detection = `!!document.querySelector("input#m_login_email");`;
  loginPage.actions = {};
  loginPage.actions.login = `document.querySelector("input#m_login_email").value = "%username%";`; // Input username
  loginPage.actions.login += `document.querySelector("input#m_login_password").value = "%password%";`; // Input password
  loginPage.actions.login += `document.querySelector('button[name="login"]').click();`; // Click Log In button
  loginPage.actions.isLogInFailed = `!!(document.querySelector('#login_error') && document.querySelector('#login_error').offsetParent) || !!document.querySelector('[data-sigil="code-input"]');`;
  return loginPage;
}

function buildAccountPickingPage() {
  let accountPickingPage = {};
  accountPickingPage.name = 'account_picking';
  accountPickingPage.detection = `!!document.querySelector('a[href*="/login/?ref=dbl&fl"]');`;
  accountPickingPage.actions = {};
  accountPickingPage.actions.pickAnother = `document.querySelector('a[href*="/login/?ref=dbl&fl"]').click()`;
  return accountPickingPage;

}

function buildSaveDevicePage() {
  let saveDevicePage = {};
  saveDevicePage.name = 'save_device';
  saveDevicePage.detection = `!!document.querySelector('a[href*="save-device/cancel"]');`;
  saveDevicePage.actions = {};
  saveDevicePage.actions.notNow = `document.querySelector('a[href*="save-device/cancel"]').click();`;
  saveDevicePage.actions.ok = `document.querySelector('button[type="submit"]').click();`;
  return saveDevicePage;
}

function buildNewFeedPage() {
  let newFeedPage = {};
  newFeedPage.name = `new_feed`;
  newFeedPage.detection = `!!document.querySelector("#MComposer");`;
  newFeedPage.actions = {};
  newFeedPage.actions.goToSettingsPage = `window.location.href = "/settings/?entry_point=bookmark";`;
  return newFeedPage;
}

function buildSettingsPage() {
  let settingsPage = {};
  settingsPage.name = `settings`;
  settingsPage.urlSignal = `/settings/`;
  settingsPage.detection = `document.querySelector('a[href*="/dyi/"]') && document.location.href.indexOf('/settings') !== -1;`;
  settingsPage.actions = {};
  settingsPage.actions.goToArchivePage = `document.querySelector('a[href*="/dyi/"]').click();`;
  settingsPage.actions.goToAdsPreferencesPage = `document.querySelector('a[href*="/ads/"]').click();`;
  return settingsPage;
}

function buildArchivePage() {
  let archivePage = {};
  archivePage.name = 'archive';
  archivePage.detection = `!!document.querySelector('[data-testid="dyi/navigation/new_archive"]');`;
  archivePage.actions = {};
  archivePage.actions.selectRequestTab = `document.querySelector('[data-testid="dyi/navigation/new_archive"]').click();`;
  archivePage.actions.selectDownloadTab = `document.querySelector('[data-testid="dyi/navigation/all_archives"]').click();`;
  archivePage.actions.selectJSONOption = `
    (function() {
      let simulateHTMLEvent = function(element, eventName) {
        let evt = document.createEvent("HTMLEvents");
        evt.initEvent(eventName, true, true);
        element.dispatchEvent(evt);
      }
      let selectEl = document.querySelector('select[name="format"]');
      selectEl.selectedIndex = 1;
      selectEl.value = 'JSON';
      simulateHTMLEvent(selectEl, 'change');
    })();
  `;
  archivePage.actions.setFromTimestamp = `
    (async function() {
      let from = new Date(%fromTimestamp%);
      let fromValue = \`\${from.getUTCFullYear()}-\${from.getUTCMonth() + 1}-\${from.getUTCDate()}\`;
    
      let simulateHTMLEvent = function(element, eventName) {
        var evt = document.createEvent("HTMLEvents");
        evt.initEvent(eventName, true, true);
        element.dispatchEvent(evt);
      }
      let simulateEvent = function(element, eventName) {
        element.dispatchEvent(new Event(eventName, { bubbles: true}));
      }
    
      let selectEl = document.querySelector('select[name="date"]');
      selectEl.selectedIndex = 1;
      selectEl.value = 'custom';
      simulateHTMLEvent(selectEl, 'change');
    
      let inputEl = document.querySelectorAll('input[type="date"][min][max]')[0];
      let nativeInputValueSetter = Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, "value").set;
      nativeInputValueSetter.call(inputEl, fromValue);
      simulateEvent(inputEl, 'input');
    })();
  `;
  archivePage.actions.selectHighResolutionOption = `
    (function() {
      let simulateHTMLEvent = function(element, eventName) {
        let evt = document.createEvent("HTMLEvents");
        evt.initEvent(eventName, true, true);
        element.dispatchEvent(evt);
      }
      let selectEl = document.querySelector('select[name="media_quality"]');
      selectEl.selectedIndex = 1;
      selectEl.value = 'VERY_HIGH';
      simulateHTMLEvent(selectEl, 'change');
    })();
  `;
  archivePage.actions.createFile = `document.querySelector('button[data-testid="dyi/sections/create"]').click();`;
  archivePage.actions.isCreatingFile = `document.querySelector('button[data-testid="dyi/sections/create"]').disabled;`;
  archivePage.actions.downloadFirstFile = `document.querySelectorAll('button[data-testid*="dyi/archives"]')[0].click();`;
  return archivePage;
}

function buildAdsReferencesPage() {
  let adsPreferencesPage = {};
  adsPreferencesPage.name = `ads_preferences`;
  adsPreferencesPage.detection = `!!document.querySelector('a[href*="/ads/preferences/demographics/"]');`;
  adsPreferencesPage.actions = {};
  adsPreferencesPage.actions.goToYourInformationPage = `document.querySelector('a[href*="/ads/preferences/demographics/"]').click();`;
  return adsPreferencesPage;
}

function buildDemographicsPage() {
  let demographicPage = {};
  demographicPage.name = `demographics`;
  demographicPage.detection = `!!document.querySelector('a[href*="/ads/preferences/behaviors"]');`;
  demographicPage.actions = {};
  demographicPage.actions.goToBehaviorsPage = `document.querySelector('a[href*="/ads/preferences/behaviors"]').click();`;
  return demographicPage;
}

function buildBehaviorsPage() {
  let behaviorsPage = {};
  behaviorsPage.name = `behaviors`;
  behaviorsPage.detection = `!!(document.querySelector('article > div._1lbp') || document.querySelector('a[data-sigil="redirect_to_behavior"]'))`;
  behaviorsPage.actions = {};
  behaviorsPage.actions.getCategories = `
    (function() {
      let nodes = [...document.querySelectorAll('a[data-sigil="redirect_to_behavior"]')];
      return nodes.map(node => node.text)
    })();
  `;
  return behaviorsPage;
}

function buildReauthPage() {
  let reauthPage = {};
  reauthPage.name = `reauth`;
  reauthPage.detection = `!!document.querySelector('input[data-testid="sec_ac_button"]');`;
  reauthPage.actions = {};
  reauthPage.actions.reauth = `document.querySelector('input[name="pass"]').value = "%password%";`;
  reauthPage.actions.reauth += `document.querySelector('input[data-testid="sec_ac_button"]').click();`;
  return reauthPage;
}

(async function() {
  let commands = {
    pages: [
      buildLoginPage(),
      buildAccountPickingPage(),
      buildSaveDevicePage(),
      buildNewFeedPage(),
      buildSettingsPage(),
      buildArchivePage(),
      buildReauthPage(),
      buildAdsReferencesPage(),
      buildDemographicsPage(),
      buildBehaviorsPage()
    ]
  };
  
  await fspromise.writeFile(filePath, JSON.stringify(commands, null, 2));
})();
