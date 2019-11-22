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
GET /trends{?type,duration_type,duration_amount,duration_start_at}
```

#### Params


| Name | Type | Description |
| -------- | -------- | -------- |
| type     | number *(required)*     | Trend type. 0: how you use fb, 1: how fb use you     |
| duration_type     | string *(optional)*     | Duration type like week/month/year     |
| duration_amount     | number *(optional)*     | Amount of duration type. For example: duration amount is      |
| duration_start_at     | number *(optional)*     | Timestamp value of start of the duration     |

Example:
```
type: 0
duration_type: week
duration_start_at : 1546300800000
```

#### Response 
200 (application/json)   
```json
{
    "result": [
        {
            "id" : 1,
            "section" : "post",
            "quantity" : 24,
            "diff_from_previous" : 5
        },
        {
            "id" : 2,
            "section" : "comment",
            "quantity" : 20,
            "diff_from_previous" : 3
        },
        {
            "id" : 3,
            "section" : "friend",
            "quantity" : 4,
            "diff_from_previous" : 8
        },
        {
            "id" : 4,
            "section" : "reaction",
            "quantity" : 100,
            "diff_from_previous" : -18
        }
    ]
}
```

### Statistic 
Get Post statistic in last week.

#### Endpoint
```url
GET /statistic{?section_id,duration_type,duration_amount,duration_start_at}
```

#### Params
| Name | Type | Description |
| -------- | -------- | -------- |
| section_id |number *(required)* | Section id. for example: 1: post, 2:comment, 3:reaction|
| duration_type |string *(optional)* | Duration type like week/month/year|
| duration_amount | number *(optional)* | Amount of duration type. For example: duration amount is `2` with duration type `week` mean 2 weeks|
| duration_start_at | number *(optional)* | Timestamp value of start of the duration (end of week, end of month)|


Example:
```
section_id: 1
duration_type: week
duration_start_at: 1546300800000
```

#### Response 
200 (application/json)
```json
{
    "result": {
        "section_id" : 1,
        "duration_type" : "week",
        "duration_amount" : 1,
        "diff_from_previous" : -5,
        "groups" : [
            { 
                "id" : 1,
                "name" : "type" 
                "categories" : [
                    {
                        "category" : { 
                            "id" : 1,
                            "name" : "Updates"
                        }, 
                        "quantity" : 2
                    },
                    {
                        "category" : { 
                            "id" : 2,
                            "name" : "Photos"
                        }, 
                        "quantity" : 9
                    },
                    {
                        "category" : { 
                            "id" : 3,
                            "name" : "Stories"
                        }, 
                        "quantity" : 3
                    }
                ]
            },
            { 
                "id" : 2,
                "name" : "day" 
                "categories" : [
                    {
                        "timestamp" : 1546300800000, 
                        "data" : [
                            {
                                "category" : { 
                                    "id" : 1,
                                    "name" : "Updates"
                                }, 
                                "quantity" : 2
                            },
                            {
                                "category" : { 
                                    "id" : 2,
                                    "name" : "Photos"
                                }, 
                                "quantity" : 9
                            }
                        ]
                    },
                    {
                        "timestamp" : 1546362000000, 
                        "data" : [
                            {
                                "category" : { 
                                    "id" : 1,
                                    "name" : "Updates"
                                }, 
                                "quantity" : 2
                            }
                        ]
                    },
                    {
                        "timestamp" : 1546448400000, 
                        "data" : []
                    }
                ]
            },
            { 
                "id" : 3,
                "name" : "place" 
                "categories" : [
                    {
                        "id" : 123,
                        "name" : "Hongtai Crossfit", 
                        "data" : [
                            {
                                "category" : { 
                                    "id" : 1,
                                    "name" : "Updates"
                                }, 
                                "quantity" : 2
                            },
                            {
                                "category" : { 
                                    "id" : 2,
                                    "name" : "Photos"
                                }, 
                                "quantity" : 2
                            }
                        ]
                    },
                    {
                        "id" : 234,
                        "name" : "Saffron", 
                        "data" : [
                            {
                                "category" : { 
                                    "id" : 1,
                                    "name" : "Updates"
                                }, 
                                "quantity" : 2
                            },
                            {
                                "category" : { 
                                    "id" : 2,
                                    "name" : "Photos"
                                }, 
                                "quantity" : 2
                            }
                        ]
                    }
                ]
            },
            { 
                "id" : 4,
                "name" : "friend" 
                "categories" : [
                    {
                        "id" : 4223,
                        "name" : "Mars Chen", 
                        "data" : [
                            {
                                "category" : { 
                                    "id" : 1,
                                    "name" : "Updates"
                                }, 
                                "quantity" : 2
                            },
                            {
                                "category" : { 
                                    "id" : 2,
                                    "name" : "Photos"
                                }, 
                                "quantity" : 2
                            }
                        ]
                    },
                    {   "id" : 643,
                        "name" : "Phil Lin", 
                        "data" : [
                            {
                                "category" : { 
                                    "id" : 1,
                                    "name" : "Updates"
                                }, 
                                "quantity" : 2
                            }
                        ]
                    }
                ]
            }
        ] 
    }
}
```
        
### Category Listing 

#### Endpoint
```url
GET /category?{?section_id,group_id,category_id,from,to,limit}
```

#### Params
| Name | Type | Description |
| -------- | -------- | -------- |
|section_id | number *(required)* | Section ID. for example: 1: post, 2:comment, 3:reaction|
|group_id | number *(required)* | Group ID. for example: 1: type, 2: day, etc...|
|category_id | number *(required)* | Category ID. for example: 1: update, 2: photo, etc...|
|from | number *(optional)* | Timestamp from |
|to |(number *(optional)* | Timstamp to|
|limit |number *(optional)* | page size|
    
Example: Get photo collection in last week
```
section_id : 1
group_id: 1
category_id: 1
from: 1546300800000
to: 1546300800000
limit : 20
```
#### Response 
200 (application/json)
```json
{
    "result": [
        {
            "id" : "8fd74a30-1659-4062-bcba-59e4ff088727",
            "type" : "photo",
            "caption" : "Hello, world!!!",
            "url" : "https://static.bm.com/abc",
            "tags" : [
                {
                    "id" : "8fd74a30-1659-4062-bcba-59e4ff088735",
                    "name" : "Phil"
                },
                {
                    "id" : "8fd74a30-1659-4062-bcba-59e4ff088790",
                    "name" : "Jone"
                }
            ],
            "location" : "Hongtai Crossfit",
            "timestamp" : 1546300800000
        },
        {
            "id" : "8fd74a30-1659-4062-fdac-59e4ff088727",
            "type" : "photo",
            "caption" : "Hello from Bitmark!!!",
            "url" : "https://static.bm.com/bm",
            "tags" : [
                {
                    "id" : "8fd74a30-1659-4062-bcba-59e4ff088727",
                    "name" : "Casey"
                },
                {
                    "id" : "8fd74a30-1659-4062-bcba-59e4ff088727",
                    "name" : "KC"
                }
            ],
            "location" : "Hongtai Crossfit",
            "timestamp" : 1546300800001
        }
    ]
}
```


### Average 

#### Endpoint
```url
GET /average{?section_id,duration_type}
```

#### Params
| Name | Type | Description |
| -------- | -------- | -------- |
|section_id | number *(required)* | Section id. for example: 1: post, 2:comment, 3:reaction|
|duration_type | string *(optional)* | Duration type like week/month/year|

Example:
```
section_id: 1
duration_type: week
```

#### Response 200
```json
{
    "result": {
        "section_id" : 1
        "duration_type" : "week",
        "avg" : 20
    }
}
```