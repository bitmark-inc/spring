# Spring Team, sprint 3

## Planning

### Sprint goal
1. Get to Apple App Store
2. Show user control of data

### Sprint backlog

- Upload of FB archive by URL (3)
- Upload of FB archive by local file (2)
- Export user data (3)
- Personal API (2)
- Delete user account (2)

Estimated velocity: 12
(See our dashboard at https://github.com/bitmark-inc/spring/projects/1)

### Schedule

- Sprint period: Feb 25th 2020 - Mar 9th 2020
- Daily scrum: 9:15 AM ICT via Zoom
- Sprint review: 14:00 Mar 9th 2020

### Team

- Sean (Product Owner)
- Jim
- Rita
- Thuyen Truong
- Hieu Pham
- Cuong Le (Scrum Master)

## Retrospective

### Summary of events & decision
- Decide to hide the automation screen and submit to App Store
- Apple rejected the submission with the same feedback
- We can not download directly from Google Drive link
- The new onboarding change is much more than expected (thinking just removing the automation, but there is 80%)
- Uploading big file from iOS keeps the app stuck for a really long time
- Thuyen found a way to upload file from background
- While background uploading, the server has to keep the whole file in the memory
- Found solution to use S3 presigned link
- Turns out the solution it only accepts 5Gb
- Decided to go with file under 5Gb


### If we do the sprint again, what will we do the same?

### If we do the sprint again, what can we do better?

### 3 things that we will improve in the next sprint
