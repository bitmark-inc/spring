let iconvlite = require('iconv-lite');

let standardizeValue = function(value) {
  if (typeof value === 'string') {
    let buf = Buffer.from(value, 'utf8');
    buf = iconvlite.encode(buf, 'latin1');
    value = iconvlite.decode(buf, 'utf8');
  }
  return value;
}

module.exports = {
  standardizeValue
}
