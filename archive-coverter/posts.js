module.exports = async function(db) {
    return new Promise((resolve, reject) => {
        var yourPostsData = require('./data/posts/your_posts_1.json');
        var otherPostsData = require('./data/posts/other_people\'s_posts_to_your_timeline');
    
        db.serialize(function() {
            // Db schema
            db.run("CREATE TABLE IF NOT EXISTS post (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, timestamp INTEGER);");
            db.run("CREATE TABLE IF NOT EXISTS post_media (id INTEGER PRIMARY KEY AUTOINCREMENT, uri TEXT, type TEXT, post_id INTEGER, timestamp INTEGER);");
    
            // insert data
            yourPostsData.forEach(element => {
                db.run("INSERT INTO post (title, timestamp) VALUES (?, ?)", element.title, element.timestamp, function(err) {
                    if (null == err){
                        if (element.attachments) {
                            var url = ""
                            var timestamp = 0
            
                            var stmt = db.prepare("INSERT INTO post_media (uri, type, post_id, timestamp) VALUES (?, ?, ?, ?)");
                            element.attachments.forEach(attachment => {
                                var type = ""
                                if (attachment.media) {
                                    type = "photo";
                                    url = attachment.media.uri;
                                    timestamp = attachment.media.creation_timestamp;
                                }
        
                                if (attachment.external_context) {
                                    type = "url";
                                    url = attachment.media.url;
                                    timestamp = element.timestamp;
                                }

                                stmt.run(url, type, this.lastID, timestamp)
                            });
                            stmt.finalize();
                        }
                        resolve();
                    }
                    else {
                        reject(err);
                    }
                });
            });
        });
    });
};
