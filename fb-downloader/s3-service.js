const AWS = require('aws-sdk');
const fs = require('fs');
const fspromises = fs.promises;

// Stream file from original bucket to preview bucket through file converter
const s3 = new AWS.S3({apiVersion: '2006-03-01'});

function S3Service(options) {
  this.bucketName = options.bucket_name;
}

S3Service.prototype.init = async function() {
  if (!global.process.env.AWS_ACCESS_KEY_ID || !global.process.env.AWS_SECRET_ACCESS_KEY || !this.bucketName) {
    throw new Error('Archive bucket or AWS authentication credential is not provided.');
  }
}

S3Service.prototype.upload = async function(filepath, s3key, identifier, from, to) {
  let params = {
    Bucket: this.bucketName,
    Key: s3key,
    Body: fs.createReadStream(filepath),
    Metadata: {
      'identifier': identifier,
      'from': from.toString(),
      'to': to.toString()
    }
  };
  return s3.putObject(params).promise();
}

module.exports = S3Service;
