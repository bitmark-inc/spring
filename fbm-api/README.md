# FBM API server
---
## Prequisites
- Go 1.13

## Testing endpoint
```url
https://fbm.test.bitmark.com
```

## API reference (real API)
### Account & Authentication

#### JWT authentication
##### Endpoint
```url
POST /api/auth
``` 

##### Response
```json
{
    "jwt_token": "jwt string",
    "expire_in": 642342532345
}
```

#### Register an account
##### Endpoint
*(JWT Authorized)*
```url
POST /api/accounts
```

##### Params
*(No params needed)*

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

#### List all submitted FB archive
This will submit a download session for fb archive. Download will be executed immediately or in a short period depends on server status. Result will be notified via OneSignal notification.
##### Endpoint
*(JWT Authorized)*
```url
GET /api/archives
```

##### Response
In case of success: HTTP Status Accepted with payload:
```json
{
    "result": [
        {
            "id": 16,
            "starting_time": "1970-01-01T08:00:00+08:00",
            "ending_time": "1970-01-01T08:00:00+08:00",
            "status": "stored",
            "created_at": "2019-12-13T16:49:16.437108+07:00",
            "updated_at": "2019-12-13T16:51:31.078849+07:00"
        }
    ]
}
```

### Server assets
Contains all server static assets

#### FB automation script
##### Endpoint
```url
GET /assets/fb_automation.json
```

## Aggregation APIs (Mocks / Design)
*(The APIs in this section may not follow REST convention. This intentionally designs for frontend's single page display.)*

### Trends 
#### Endpoint
```url
GET /trends{?type,timebox,timebox_start_at}
```

#### Params


| Name | Type | Description |
| -------- | -------- | -------- |
| type     | number *(required)*     | Trend type. 0: how you use fb, 1: how fb use you     |
| timebox     | string *(optional)*     | timebox like week,dacade,year    |
| timebox_start_at     | number *(optional)*     | Timestamp value of start of the timebox     |

Example:
```
type: 0
timebox: week
timebox_start_at : 1546300800000
```

#### Response 
200 (application/json)   
```json
{
    "result": {
        "type" : 0,
        "timebox" : "week",
        "timebox_start_at" : 1546300800000,
        "data" : [
            {
                "name" : "post",
                "quantity" : 24,
                "diff_from_previous" : 5
            },
            {
                "name" : "comment",
                "quantity" : 20,
                "diff_from_previous" : 3
            },
            {
                "name" : "friend",
                "quantity" : 4,
                "diff_from_previous" : 8
            },
            {
                "name" : "reaction",
                "quantity" : 100,
                "diff_from_previous" : -18
            }
        ]
    }
}
```

### Statistic 
Get Post statistic in last week.

#### Endpoint
```url
GET /statistic{?name,timebox,timebox_start_at}
```

#### Params
| Name | Type | Description |
| -------- | -------- | -------- |
| name |string *(required)* | Section name. for example: post, reaction |
| timebox |string *(optional)* | timebox like week,dacade,year  |
| timebox_start_at | number *(optional)* | Timestamp value of start of the timebox (start of week, start of year)   |


Example:
```
name: post
timebox: week
timebox_start_at: 1546300800000
```

#### Response 
200 (application/json)
```json
{
  "result" : {
    "name" : "post",
    "timebox" : "week",
    "timebox_start_at" : 1546300800000,
    "diff_from_previous" : -5,
    "entities" : [
      {
        "timestamp" : 1574823116000,
        "type" : "Updates",
        "metadata" : {
          "tags" : ["Phil Chen", "KC Alt"],
          "places" : ["Taipei 101"]
        }
      },
      {
        "timestamp" : 1574823796000,
        "type" : "Photos",
        "metadata" : {
          "tags" : ["Phil Chen", "KC Alt"],
          "places" : ["Taipei 101"]
        }
      },
      {
        "timestamp" : 1574823126000,
        "type" : "Stories",
        "metadata" : {}
      },
      {
        "timestamp" : 1574823526000,
        "type" : "Links",
        "metadata" : {
          "tags" : ["KC Alt"],
          "places" : ["Hongtai Crossfit"]
        }
      }
    ]
  }
}
```
        
### Category Listing 

#### Endpoint
```url
GET /category?{?}
```

#### Params
// TODO declare later

#### Response 
200 (application/json)
// TODO declare later


### Average 

#### Endpoint
```url
GET /average{?section_name,timebox}
```

#### Params
| Name | Type | Description |
| -------- | -------- | -------- |
|section_name | string *(required)* | Section name. for example: post, reaction|
|timebox | string *(optional)* | timebox like week/month/year|

Example:
```
section_name: 1
timebox: week
```

#### Response 200
```json
{
    "result": {
        "section_name" : "post",
        "duration_type" : "week",
        "avg" : 20
    }
}
```