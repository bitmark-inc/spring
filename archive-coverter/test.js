const database = require('./database.js');
const postsParser = require('./posts.js');
const reactionsParser = require('./reactions.js');

(async function() {
  let db = await database.init();
  await postsParser(db);
  await reactionsParser(db);
  db.close();
}());