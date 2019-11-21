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
##### Endpoint
*(JWT Authorized)*
```url
POST /api/archives
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