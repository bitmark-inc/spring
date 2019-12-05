//
//  Constant+FakeData.swift
//  Synergy
//
//  Created by thuyentruong on 12/5/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation

extension Constant {

    static func numberOfPosts(timeUnit: TimeUnit) -> Int {
        switch timeUnit {
        case .week:
            return 17
        case .year:
            return 733
        case .decade:
            return 25728
        }
    }

    static func postWeekUsage() -> [String: [[String: Any]]] {
        return [
            "type" : [
                [
                    "data": [
                        "keys": ["Updates", "Photos", "Stories", "Videos", "Links"],
                        "values": [9, 5, 2, 0, 1]
                    ]
                ]
            ],
            "day" : [
                [
                    "name": "2019-11-12",
                    "data": [
                        "updates": 2,
                        "photos": 9,
                        "stories": 3,
                        "videos": 2,
                        "links": 3
                    ]
                ]
            ],
            "friend": [
                [
                    "name": "PW Du Plessis",
                    "data": [
                        "keys": ["Updates", "Photos", "Stories", "Videos", "Links"],
                        "values": [0, 1]
                    ]
                ],
                [
                    "name": "Gigi DelaCruz",
                    "data": [
                        "keys": ["Updates", "Photos", "Stories", "Videos", "Links"],
                        "values": [0, 1]
                    ]
                ],
                [
                    "name": "Ivy Chuang",
                    "data": [
                        "keys": ["Updates", "Photos", "Stories", "Videos", "Links"],
                        "values": [0, 1]
                    ]
                ],
                [
                    "name": "Pg Mikey",
                    "data": [
                        "keys": ["Updates", "Photos", "Stories", "Videos", "Links"],
                        "values": [0, 1]
                    ]
                ],
                [
                    "name": "楊斯傑",
                    "data": [
                        "keys": ["Updates", "Photos", "Stories", "Videos", "Links"],
                        "values": [0, 1]
                    ]
                ]
            ],
            "place": [
                [
                    "name": "Bitmark",
                    "data": [
                        "keys": ["Updates", "Photos", "Stories", "Videos", "Links"],
                        "values": [0, 4, 1, 0, 0]
                    ]
                ],
                [
                    "name": "Hongtai CrossFit",
                    "data": [
                        "keys": ["Updates", "Photos", "Stories", "Videos", "Links"],
                        "values": [0, 0, 0, 0, 1]
                    ]
                ]
            ]
        ]
    }

    static func postYearUsage() -> [String: [[String: Any]]] {
        return [
            "type" : [
                [
                    "data": [
                        "keys": ["Updates", "Photos", "Stories", "Videos", "Links"],
                        "values": [243, 292, 89, 42, 67]
                    ]
                ]
            ],
            "day" : [
                [
                    "name": "2019-11-12",
                    "data": [
                        "updates": 2,
                        "photos": 9,
                        "stories": 3,
                        "videos": 2,
                        "links": 3
                    ]
                ]
            ],
            "friend": [
                [
                    "name": "Aaron Alt",
                    "data": [
                        "keys": ["Updates", "Photos", "Stories", "Videos", "Links"],
                        "values": [0, 18, 10, 5, 0]
                    ]
                ],
                [
                    "name": "Ching-Wei Liu",
                    "data": [
                        "keys": ["Updates", "Photos", "Stories", "Videos", "Links"],
                        "values": [1, 25, 10, 0, 0]
                    ]
                ],
                [
                    "name": "Shirla Humiston",
                    "data": [
                        "keys": ["Updates", "Photos", "Stories", "Videos", "Links"],
                        "values": [0, 19, 10, 6, 0]
                    ]
                ],
                [
                    "name": "Phil Lin",
                    "data": [
                        "keys": ["Updates", "Photos", "Stories", "Videos", "Links"],
                        "values": [1, 35, 12, 1, 0]
                    ]
                ],
                [
                    "name": "Beven Lan",
                    "data": [
                        "keys": ["Updates", "Photos", "Stories", "Videos", "Links"],
                        "values": [2, 48, 11, 4, 0]
                    ]
                ]
            ],
            "place": [
                [
                    "name": "teamLab Planets TOKYO",
                    "data": [
                        "keys": ["Updates", "Photos", "Stories", "Videos", "Links"],
                        "values": [0, 10, 0, 10, 0]
                    ]
                ],
                [
                    "name": "CUM-Create Ur Mmmagic",
                    "data": [
                        "keys": ["Updates", "Photos", "Stories", "Videos", "Links"],
                        "values": [0, 8, 4, 0, 0]
                    ]
                ],
                [
                    "name": "Bitmark",
                    "data": [
                        "keys": ["Updates", "Photos", "Stories", "Videos", "Links"],
                        "values": [1, 9, 3, 0, 7]
                    ]
                ],
                [
                    "name": "Tainan, Taiwan",
                    "data": [
                        "keys": ["Updates", "Photos", "Stories", "Videos", "Links"],
                        "values": [0, 14, 6, 0, 0]
                    ]
                ],
                [
                    "name": "Hongtai CrossFit",
                    "data": [
                        "keys": ["Updates", "Photos", "Stories", "Videos", "Links"],
                        "values": [1, 12, 28, 4, 1]
                    ]
                ]
            ]
        ]
    }


    static func postDecadeUsage() -> [String: [[String: Any]]] {
        return [
            "type" : [
                [
                    "data": [
                        "keys": ["Updates", "Photos", "Stories", "Videos", "Links"],
                        "values": [3345, 3171, 850, 236, 8126]
                    ]
                ]
            ],
            "day" : [
                [
                    "name": "2019-11-12",
                    "data": [
                        "updates": 2,
                        "photos": 9,
                        "stories": 3,
                        "videos": 2,
                        "links": 3
                    ]
                ]
            ],
            "friend": [
                [
                    "name": "Phil Lin",
                    "data": [
                        "keys": ["Updates", "Photos", "Stories", "Videos", "Links"],
                        "values": [10, 636, 164, 10, 10]
                    ]
                ],
                [
                    "name": "Leslie RH",
                    "data": [
                        "keys": ["Updates", "Photos", "Stories", "Videos", "Links"],
                        "values": [8, 235, 61, 3, 21]
                    ]
                ],
                [
                    "name": "Beven Lan",
                    "data": [
                        "keys": ["Updates", "Photos", "Stories", "Videos", "Links"],
                        "values": [6, 107, 34, 8, 143]
                    ]
                ],
                [
                    "name": "Shirla Humiston",
                    "data": [
                        "keys": ["Updates", "Photos", "Stories", "Videos", "Links"],
                        "values": [0, 211, 58, 0, 0]
                    ]
                ],
                [
                    "name": "Theo Van Eck",
                    "data": [
                        "keys": ["Updates", "Photos", "Stories", "Videos", "Links"],
                        "values": [1, 62, 19, 3, 87]
                    ]
                ]
            ],
            "place": [
                [
                    "name": "Taipei, Taiwan",
                    "data": [
                        "keys": ["Updates", "Photos", "Stories", "Videos", "Links"],
                        "values": [1, 134, 33, 2, 12]
                    ]
                ],
                [
                    "name": "Hongtai CrossFit",
                    "data": [
                        "keys": ["Updates", "Photos", "Stories", "Videos", "Links"],
                        "values": [1, 93, 28, 4, 1]
                    ]
                ],
                [
                    "name": "Los Angeles, California",
                    "data": [
                        "keys": ["Updates", "Photos", "Stories", "Videos", "Links"],
                        "values": [0, 89, 20, 0, 0]
                    ]
                ],
                [
                    "name": "Luang Prabang",
                    "data": [
                        "keys": ["Updates", "Photos", "Stories", "Videos", "Links"],
                        "values": [0, 64, 22, 0, 0]
                    ]
                ],
                [
                    "name": "Seoul, Korea",
                    "data": [
                        "keys": ["Updates", "Photos", "Stories", "Videos", "Links"],
                        "values": [0, 61, 24, 0, 1]
                    ]
                ]
            ]
        ]
    }
}
