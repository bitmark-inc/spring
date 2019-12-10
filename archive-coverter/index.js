const express = require('express');
const fileUpload = require('express-fileupload');
const cors = require('cors');
const bodyParser = require('body-parser');
const morgan = require('morgan');
const _ = require('lodash');

const fs = require('fs');
const path = require('path');
const unzip = require('unzip');

const app = express();
const port = process.env.PORT || 8080;
const uploadDir = process.env.UPLOAD_DIR || path.resolve(__dirname, 'upload');
const dataDir = process.env.DATA_DIR || path.resolve(__dirname, 'data');

// enable files upload
app.use(fileUpload({
  createParentPath: true
}));

//add other middleware
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({extended: true}));
app.use(morgan('dev'));

app.post('/upload', async (req, res) => {
  try {
    if(!req.files) {
      res.send({
        status: false,
        message: 'No file uploaded'
      });
    } else {
      let archive = req.files.archive;
      let archivePath = path.resolve(uploadDir, 'archive.zip');
      archive.mv(archivePath);

      fs.createReadStream(archivePath)
        .pipe(unzip.Extract({path: dataDir}))
        .on('close', () => {
          console.log('Finished unzip archive');
        });

      //send response
      res.send({
        status: true,
        message: 'File is uploaded'
      });
    }
  } catch (err) {
    console.log(err);
    res.status(500).send(err);
  }
});

app.listen(port, () => 
  console.log(`App is listening on port ${port}.`)
);



// API multi part
// Unzip
// Save post
// Save message
// Save reaction
// Save location