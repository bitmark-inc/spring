

module.exports = async function() {
    var yourPostsData = require('./data/posts/your_posts_1.json');
    var otherPostsData = require('./data/posts/other_people\'s_posts_to_your_timeline');

    var sqlite3 = require('sqlite3').verbose();
    var db = new sqlite3.Database(':memory:');

    db.serialize(function() {
    db.run("CREATE TABLE posts (title TEXT, type TEXT)");
    });

    db.close();
};
