# Tarantool DB Template
Here is my template for fast tarantool db creating. check app.lua
Just describe a db struct and thats it.

## Create a db
```lua
--db name
db.accounts = {
    -- fields name
    { tag = 'id',     type = 'unsigned' },
    { tag = 'email',  type = 'string' },
    { tag = 'pass',   type = 'string' },

    --indexes
    indexes = {
        {name = 'primary',  tags = {'id'},  unique = true},
        {name = 'email',    tags = {'email'},  unique = true},
        {name = 'creds',    tags = {'email','pass'}, unique = false},
    }
}
```

## Use
```lua
db.accounts:replace({1, 'nice@apple.com', '12345'})
```
