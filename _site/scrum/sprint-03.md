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
- Decided to hide the automation screen and submit to App Store
- Apple rejected the submission with the same feedback
- We could not download directly from Google Drive link
- The new onboarding change was much more than expected (thinking just removing the automation, but there is 80% change)
- The new onboarding change for get your Facebook data, and rearrange bottom navigation
- Some changes from API server affecting Android version but we did not foresee.
- Uploading big file from iOS keeps the app open & stuck for a really long time
- Thuyen found a way to upload file from background
- While background uploading, the server has to keep the whole file in the memory, causing out of memory error
- Found solution to use S3 presigned link
- Turns out the solution only accepts 5Gb
- Try the solution using S3 token and AWS SDK from client side, turns out it’s complicated for the client & might not be safe
- Decided to go with file under 5Gb
- PO helps to sort out the priority of stories when we realized there is no time to finish them all
- Finish the sprint with url, local file upload, first version of open API. Exporting & deleting user data were left out.


### If we do the sprint again, what will we do the same?
- Migrate bitsocial server to app server, reduce a lot of redundancy
- Found out transfer file in the backgroup when reliazing uploading directly is really bad UX
- The solution using presigned link is simpler for iOS
- We have more discussion even in distributed team
- Jim joins the team so we do not rely on external dependency
- Decided to go with stuitable solution in the current situation
- Be vertically integrated so that development doesn't depend on new work from external people.

### If we do the sprint again, what can we do better?
- PO can review the design faster and give feedback
- Better define url upload story (e.g: what cloud storage to support)
- Depends a lot on server side at the begining of the sprint
- Focus on one story at a time, so we can release sooner for feedback from everybody
- Ask PO to select trade-off sooner when encountering technical difficulty
- Team actively seeks out corrective feedback from PO
- Let Hieu know the changes so Android version does not get broken unexpectedly

### 3 things that we will improve in the next sprint
- Team actively seeks out corrective feedback from PO (Figure out good channel for people to do this) (5)
- Scrum master to help with coordinate component changes
