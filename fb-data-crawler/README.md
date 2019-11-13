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

Basic Command to run the whole process:
```
node command -u username@examplemail.com -password examplepassword
```

Note:
- You can use -i option to see the browser running with interface
- To avoid being blocked by facebook, you should run with -c, it will cache your session for next time use. Keep loging in so many times will put you in "suspicious" category.

```
node command -i -c -u username@examplemail.com -password examplepassword
```


Result:
```

```

## Run data requesting and data download separately

Options -r will tell the program to request the data only and exit. The result of this is an archive ID (it's actually the order of the requested archive in the archive list)
```
node command -i -c -r -u username@examplemail.com -password examplepassword
```

Options -d will tell the program to download the data only, with the archive number followed.
```
node command -i -c -d 2 -u username@examplemail.com -password examplepassword
```
