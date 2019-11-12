This project could be run as a program over command line or API service.

# INSTALLATION
```
npm install
```

# COMMAND LINE

## How it works?

The program will connect to Facebook, log in by users' username and password. It then
1. Requests to download the Facebook archive
2. Wait for the archive to be available and download it

You can run the process as a whole, the program will keep running until it can get the data. Sometime, the process takes too long that you might want to run the step #2 much later after step #1.

## Run process as a whole

Command:
```
node command -u username@examplemail.com -password examplepassword
```
Note: you can use -i option to see the browser run with interface

Result:
```

```