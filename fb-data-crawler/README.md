This project could be run as a program over command line or API service.

# ROAD MAP & Progress

Finished features:
- [x] API end point
- [x] Login with correct username & password
- [x] Session backup & login with cookies
- [x] Archive requesting
- [x] Detect optional password require before downloading archive
- [x] Archive downloading
- [ ] Upload the archive to S3 & notify the caller
- [ ] Deploy to testnet K8S
- [ ] Detect wrong username & password and then return error
- [ ] Detect the archive can not be requested because another archive is being requested
- [ ] Detect 2 factor authentication and return error (considering asking users through the app later)
- [ ] Optimize the memory by closing browser while waiting for the archive to be available
- [ ] ...


# INSTALLATION
```
npm install
```

# SET UP & RUN
Environment variables
- PORT: the service will listen on this port, otherwise it will use 8080 as default
- DATA_DIR: where the service keep user data file and archives

```
PORT=123 DATA_DIR=./data npm server.js
```

# API

## POST /api/download
Request to download an archive

Request
```
Header
content-type: application/json
Body
{
	"identifier": "bitmarkAccountNumber",
	"username": "example@example.com",
	"password": "example",
	"callback": "https://example.com/receive-archive-url"
}
```

The request is successful when the program can login and request an archive
Reponse
```
{
  "message": "login successfully & data backup is scheduled!"
}
```

The program will upload the archive to S3 and notify the caller via the callback url with data
```
{identifier, from, to, s3Key}
```
