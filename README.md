# tarantool
Tarantool lua template

Here is my template for fast tarantool db creating. check app.lua
just write a db struct and thats it

## Just descibe a db
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

Then use it
```lua
db.accounts:replace({1, 'nice@apple.com', '12345'})
```
