const http = require('http');
const url = require('url');
const querystring = require('querystring');
const AWS = require('aws-sdk');
const fs = require('fs');
const mime = require('mime-types');
const uuidv4 = require('uuid/v4');
const { promisify } = require('util')
const writeFileAsync = promisify(fs.writeFile);
const unlinkFileAsync = promisify(fs.unlink);

// Check bucket configuration
const BUCKET = global.process.env.BUCKET;
const PORT = global.process.env.PORT;
let serverShouldStopProcessing = false;

if (!BUCKET) {
  console.error('Original & preview buckets are not provided.');
  global.process.exit(1);
}


// Stream file from original bucket to preview bucket through file converter
const s3 = new AWS.S3({apiVersion: '2006-03-01'});

const removeTempFile = async (filepath) => {
  await unlinkFileAsync(filepath);
};

const uploadFileToS3 = async (filepath, s3key) => {
  let params = {
    Bucket: BUCKET,
    Key: s3key,
    Body: fs.createReadStream(filepath),
    ContentType: mime.lookup(PREVIEW_FORMAT)
  };
  return s3.putObject(params).promise();
};

const downloadUrlFilter = /^\/api\/download(\?.+)?$/;
http.createServer(async function (req, res) {
  if (downloadUrlFilter.test(req.url) && req.method === 'POST') {
    try {
      let query = querystring.decode(url.parse(req.url).query);
      let username = query.username;
      let password = query.password;
      let from = query.from;
      let to = query.to;

      res.writeHead(200, {'Content-Type': 'application/jason'});
      res.end(JSON.stringify({key: previewS3Key}));
    } catch (err) {
      console.log(err);
      res.writeHead(500, {'Content-Type': 'application/jason'});
      res.end(JSON.stringify({message: err.message}));
    }
  } else if (req.url === '/api/healthz') {
    res.writeHead(serverShouldStopProcessing ? 500 : 200);
    res.end();
  } else {
    res.writeHead(404);
    res.end();
  }
}).listen(PORT || 8080);

global.process.on('SIGTERM', function () {
  serverShouldStopProcessing = true;
});
