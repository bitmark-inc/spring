# FBM API server
---
## Prequisites
- Go 1.13

## API reference
### Account & Authentication

#### JWT authentication
##### Endpoint
```url
POST /api/auth
``` 

#### Register an account
##### Endpoint
*(JWT Authorized)*
```url
POST /api/accounts
```

##### Params
| Name | Type | Description |
| -------- | -------- |-------- |
| enc_pub_key *(required)*     | string | Bitmark account's public encryption key in hex representation.     |

```json
{
    "enc_pub_key": "bytes_in_hex"
}
```

##### Response
```json
{
    "result": {
        "account_number": "fq5dQwwm7Y5ckZwYgG7aK1exL3oS8w7BvqCNbV8Bzf8wzZc5qo",
        "metadata": {},
        "created_at": "2019-10-29T16:05:27.617069+07:00",
        "updated_at": "2019-10-29T16:14:09.762852+07:00"
    }
}
```

#### Current account information
##### Endpoint
*(JWT Authorized)*
```url
GET /api/accounts/me
```

##### Response
```json
{
    "result": {
        "account_number": "fq5dQwwm7Y5ckZwYgG7aK1exL3oS8w7BvqCNbV8Bzf8wzZc5qo",
        "metadata": {},
        "created_at": "2019-10-29T16:05:27.617069+07:00",
        "updated_at": "2019-10-29T16:14:09.762852+07:00"
    }
}
```

### FB archives
#### Submit an FB archive
This will submit a download session for fb archive. Download will be executed immediately or in a short period depends on server status. Result will be notified via OneSignal notification.
##### Endpoint
*(JWT Authorized)*
```url
POST /api/archives
```

#### Params

| Name | Type | Description |
| -------- | -------- |-------- |
| headers *(optional)*     | string | Simulate all existing headers from current session     |
| cookies *(optional)*     | array of objects | Simulate all existing cookies from current session     |
| raw_cookie *(optional)*     | string | Simulate all existing cookies from current session     |
| file_url *(required)*     | string | File url to download     |


Example:
```json
{
    "headers": {
        "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148",
        "Referer": "https://m.facebook.com/dyi/?x=AdnFXqQNnRYgIln8&referrer=cc_settings&tab=all_archives",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
    },
    "file_url": "https://bigzipfiles.facebook.com/p/dl/download/file.php?r=100012706444503&t=100012706444503&j=11&i=817084935391714&f=817086042058270&ext=1574238815&hash=AaAvn-lUGvTSYnuX",
    "cookies": [
        {
            "expire": "2021-11-19T04:03:19.000Z",
            "domain": ".facebook.com",
            "secure": true,
            "value": "%7B%22100012706444503%22%3A%22Ig81wj4g%22%7D",
            "path": "/login/device-based/",
            "httponly": true,
            "name": "dbln"
        }
    ]
}
```
##### Response
In case of success: HTTP Status Accepted with payload:
```json
{
    "result": "OK"
}
```