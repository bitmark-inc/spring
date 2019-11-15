HOST: https://api.synergy.com/v1/

# Synergy API

## Account \[/account]

// TODO consider to keep/remove this api

### Register Account \[POST]

+ Request (application/json)
      
        {
            "bm_account_number" : "f8pWX9LoE97GLHwdF9KjzD4XBybmNQr6unwp8zhGgfHpbHwPFu",
            "signature" : "32400b5e89822de254e8d5d94252c52bdcb27a3562ca593e980364d9848b8041b98eabe16c1a6797484941d2376864a1b0e248b0f7af8b1555a778c336a5bf48"
        }
  
+ Response 200 (application/json)

        {
            "account_id" : "f8pWX9LoE97GLHwdF9KjzD4XBybmNQr6unwp8zhGgfHpbHwPFu"
        }
        
## Authentication \[/auth]

### Register JWT \[POST]

+ Request (application/json)
        
        {
            "account_id" : "f8pWX9LoE97GLHwdF9KjzD4XBybmNQr6unwp8zhGgfHpbHwPFu",
            "signature" : "32400b5e89822de254e8d5d94252c52bdcb27a3562ca593e980364d9848b8041b98eabe16c1a6797484941d2376864a1b0e248b0f7af8b1555a778c336a5bf48",
            "timestamp" : 1546300800000
        }

+ Response 200 (application/json)

        {
            "jwt" : "f8pWX9LoE97GLHwp8zhGgfHpbHwPFu.f8pWX9LoE97GLHwdF9KjzD4XBybm.f8pWX9Lwp8zhGgfHpbHwPFu",
            "expired_in" : 30000000
        }
        
## Notification \[/uuid]

### Register device UUID \[POST]

+ Request (application/json)

        {
            "account_id" : "f8pWX9LoE97GLHwdF9KjzD4XBybmNQr6unwp8zhGgfHpbHwPFu",
            "uuid" : "8fd74a30-1659-4062-bcba-59e4ff088727"
        }

+ Response 200 

### Delete device UUID \[DELETE]

+ Response 200

## Facebook Archive \[/archive]

### Request Archive \[POST]

+ Request (application/json)

        {
            "account_id" : "f8pWX9LoE97GLHwdF9KjzD4XBybmNQr6unwp8zhGgfHpbHwPFu",
            "credential" : 
                {
                    "id" : "testing@bitmark.com",
                    "password" : "thisispassword"
                }
        }

+ Response 200 

### Get Archive info \[GET]

+ Response 200 

        {
            "timestamp" : 1546300800000,
            "size" : 1073741824,
            "fingerprint" : "32400b5e89822de254e8d5d94252c52bdcb27a3562ca593e980364d9848b8041b98eabe16c1a6797484941d2376864a1b0e248b0f7af8b1555a778c336a5bf48"
        }

## Trends \[/trends{?type,duration_type,duration_amount,duration_start_at}]

+ Parameters
    + type (number, required, `0` ) ... Trend type. 0: how you use fb, 1: how fb use you
    + duration_type (string, optional, `week` ) ... Duration type like week/month/year
    + duration_amount (number, optional, `1`) ... Amount of duration type. For example: duration amount is `2` with duration type `week` mean 2 weeks
    + duration_start_at (number, optional, `1546300800000`) ... Timestamp value of start of the duration
    
### Get Trends \[GET]

+ Request

    + Parameters
        + type: 0
        + duration_type: "week"
        + duration_start_at : 1546300800000

+ Response 200 (application/json)   
    
        [
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

## Statistic \[/statistic{?section_id,duration_type,duration_amount,duration_start_at}]

+ Parameters
    + section_id (number, required, `1` ) ... Section id. for example: 1: post, 2:comment, 3:reaction
    + duration_type (string, optional, `week` ) ... Duration type like week/month/year
    + duration_amount (number, optional, `1`) ... Amount of duration type. For example: duration amount is `2` with duration type `week` mean 2 weeks
    + duration_start_at (number, optional, `1546300800000`) ... Timestamp value of start of the duration (end of week, end of month)

### Get Statistic \[GET]


+ Request Get Post statistic in last week

    + Parameters
        + section_id: 1
        + duration_type: week
        + duration_start_at: 1546300800000

+ Response 200 (application/json)

        {
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
                                {"id" : 1, "name" : "Updates", "quantity" : 1},
                                {"id" : 2, "name" : "Photos", "quantity" : 5}
                            ]
                        },
                        {
                            "id" : 234,
                            "name" : "Saffron", 
                            "data" : [
                                {"id" : 1, "name" : "Updates", "quantity" : 2},
                                {"id" : 2, "name" : "Photos", "quantity" : 2}
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
        
        
        
+ Request Get Reaction statistic in last week

    + Parameters
        + section_id: 2
        + duration_type: week
        + duration_start_at: 1546300800000

+ Response 200 (application/json)

        {
            "section_id" : 2,
            "duration_type" : "week",
            "duration_amount" : 1,
            "diff_from_previous" : 20,
            "groups" : [
                { 
                    "id" : 1,
                    "name" : "type" 
                    "categories" : [
                        {
                            "category" : { 
                                "id" : 1,
                                "name" : "Like"
                            }, 
                            "quantity" : 34
                        },
                        {
                            "category" : { 
                                "id" : 2,
                                "name" : "Love"
                            }, 
                            "quantity" : 40
                        },
                        {
                            "category" : { 
                                "id" : 3,
                                "name" : "Haha"
                            }, 
                            "quantity" : 19
                        },
                        {
                            "category" : { 
                                "id" : 4,
                                "name" : "Wow"
                            }, 
                            "quantity" : 10
                        },
                        {
                            "category" : { 
                                "id" : 5,
                                "name" : "Like"
                            }, 
                            "quantity" : 0
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
                                        "name" : "Like"
                                    }, 
                                    "quantity" : 3
                                },
                                {
                                    "category" : { 
                                        "id" : 2,
                                        "name" : "Love"
                                    }, 
                                    "quantity" : 4
                                }
                            ]
                        },
                        {
                            "timestamp" : 1546362000000, 
                            "data" : [
                                {
                                    "category" : { 
                                        "id" : 1,
                                        "name" : "Like"
                                    }, 
                                    "quantity" : 3
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
                    "name" : "friend" 
                    "categories" : [
                        {
                            "id" : 1,
                            "name" : "Mars Chen", 
                            "data" : [
                                {
                                    "category" : { 
                                        "id" : 1,
                                        "name" : "Like"
                                    }, 
                                    "quantity" : 6
                                },
                                {
                                    "category" : { 
                                        "id" : 2,
                                        "name" : "Love"
                                    }, 
                                    "quantity" : 5
                                }
                            ]
                        },
                        {
                            "id" : 2,
                            "name" : "Phil Lin", 
                            "data" : [
                                {
                                    "category" : { 
                                        "id" : 1,
                                        "name" : "Like"
                                    }, 
                                    "quantity" : 6
                                }
                            ]
                        }
                    ]
                }
            ] 
        }
        
        
## Category Listing \[/category?{?section_id,group_id,category_id,from,to,limit}]

+ Parameters
    + section_id (number, required, `1` ) ... Section ID. for example: 1: post, 2:comment, 3:reaction
    + group_id (number, required, `1` ) ... Group ID. for example: 1: type, 2: day, etc...
    + category_id (number, required, `1` ) ... Category ID. for example: 1: update, 2: photo, etc...
    + from (number, optional, `1546300800000` ) ... Timestamp from 
    + to (number, optional, `1546300800000` ) ... Timstamp to
    + limit (number, optional, `20`) ... page size
    
### Get Category collection \[GET]

+ Request Get photo collection in last week
    + Parameters
        + section_id : 1
        + group_id: 1
        + category_id: 1
        + from: 1546300800000
        + to: 1546300800000
        + limit : 20

+ Response 200 (application/json)

        [
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

## Average \[/average{?section_id,duration_type}]

+ Parameters
    + section_id (number, required, `1` ) ... Section id. for example: 1: post, 2:comment, 3:reaction
    + duration_type (string, optional, `week` ) ... Duration type like week/month/year

### Get Average \[GET]

+ Request

    + Parameters
        + section_id: 1
        + duration_type: week

+ Response 200

        {
            "section_id" : 1
            "duration_type" : "week",
            "avg" : 20
        }















        
