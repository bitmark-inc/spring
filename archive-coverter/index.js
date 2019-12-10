const express = require('express');
const fileUpload = require('express-fileupload');
const cors = require('cors');
const bodyParser = require('body-parser');
const morgan = require('morgan');
const _ = require('lodash');

const app = express();
const port = process.env.PORT || 8080;

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
      avatar.mv('./upload/archive.zip');

      //send response
      res.send({
        status: true,
        message: 'File is uploaded'
      });
    }
  } catch (err) {
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