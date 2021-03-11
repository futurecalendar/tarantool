#!/usr/bin/tarantool
-------------------------------------------------- modules ----------------------------------------------------    
    json    = require('json')
    --yaml    = require('yaml')
    --fiber   = require('fiber')
    --msgpack = require('msgpack')
    --curl = require('curl')

----------------------------------------- Small tools -------------------------------------------      
    function Q(data)            return print(require('yaml').encode(data))  end -- print as yaml
    function time()             return require('os').time()                 end -- unixtime
    function js(data)           return require('json').encode(data)         end -- print as json
  
    -- get string enivroment keys with default value
    function env(key, default)  --string key
        local a = require('os').getenv(key) 
        if a then 
            return a 
        else 
            return default 
        end 
    end

    -- get int enivroment keys with default value
    function envInt(key, default)  
        local a = require('os').getenv(key) 
        a = tonumber(a)
        if a then 
            return a 
        else 
            return default 
        end 
    end
-------------------------------------------------- Settings ----------------------------------------------------    
        local volume = env('volume', 'db')
        os.execute('mkdir -p '..volume)
       
        local readonly = false
        if envInt('readonly', 0) == 0 then
            readonly=false
        else
            readonly=true
        end
       
        box.cfg {
                
                listen              = envInt('port', 3301), 
                checkpoint_interval = envInt('period', 3600),
                checkpoint_count    = envInt('count', 10),
                memtx_memory        = envInt('memory', 2000 * 1024 * 1024), --memtx_memory --2gb
                read_only           = readonly, --take from env or false
                log                 = env('log', 'tarantool.log'),
                work_dir            = volume,
        }
---------------------------------------------------- Access -------------------------------------------------------

    box.schema.user.create('api', {if_not_exists = true, password = env("pass", "12345") }) --create a user 
    box.schema.user.grant('api', 'read, write, execute', 'universe', nil, {if_not_exists=true, password = env("pass", "12345")}) --access
    box.schema.user.create('replicator', {if_not_exists=true, password = env("replication", "12345")}) --replications
    box.schema.user.grant('replicator','execute','role','replication',{if_not_exists=true}) --repl access

------------------------------------------ Create db engine (do not touch it) ------------------------------------------------    
    function init(db) 
        local newdb = {}
        --tables count
        for name, tbl in pairs(db) do     
                newtable = box.schema.space.create(name, {id = 555, if_not_exists = true, engine = tbl.engine})
                local map = {}
                local types = {}
                --fields count
                for pos = 1, #tbl do  
                    field = tbl[pos]
                    map[field.tag] = pos
                    map[pos] = field.tag
                    types[field.tag] = field.type
                    --index field
                    if field.index then
                        idxname = field.tag
                        if pos == 1 then idxname = 'primary' end
                        newtable:create_index(idxname, { if_not_exists = true, unique = field.unique, parts = {pos, field.type}})     
                    end
                end
                --index count
                if tbl.indexes then
                    for _, idx in pairs(tbl.indexes) do
                        if idx.name then 
                            parts = {}
                            for _, tag in pairs(idx.tags) do
                                table.insert(parts, map[tag])
                                table.insert(parts, types[tag])
                            end
                            newtable:create_index(idx.name, { if_not_exists = true, type = idx.type, unique = idx.unique, parts = parts})
                        end
                    end
                end
                newdb[name] = newtable
                newdb[name.."_"] = map
                print("db:", "db."..name..":select{}")
                print("map:", "db."..name.."_['user'] = 1")
                print("list:", "db."..name.."_[1] = 'user'")
        end
        return newdb
        end
----------------------------------------------- DB struct ------------------------------------------------  
       
        --db plan
        db = {}

        --create new db
        --you can add more db
        db.profiles = {
                -- named fields (just for pleasure), tag - field in tuple
                { tag = 'id',     type = 'unsigned' },
                { tag = 'email',  type = 'string' },
                { tag = 'pass',   type = 'string' },
                
                --indexes
                indexes = {
                    {name = 'primary',  tags = {'id'},  unique = true},
                    {name = 'email',    tags = {'email'},  unique = true},
                    {name = 'creds',    tags = {'email', 'pass'},  unique = true},
                }
            }

        -- init db
        db = init(db)

        -- sequence example
        if box.sequence["id"] == nil then
            box.schema.sequence.create("id")
        end
        

----------------------------------------------------- just print init info -----------------------------------------------------

        print()
        print('listen       ',box.cfg.listen)
        print('interval     ',box.cfg.checkpoint_interval)
        print('count        ',box.cfg.checkpoint_count)
        print('memory       ',box.cfg.memtx_memory/1000000, 'mb')
        print('read_only    ',box.cfg.read_only)
        print('work_dir     ',box.cfg.work_dir)
        print('log          ',box.cfg.log)

----------------------------------------------------- functions (write your own) -----------------------------------------------------
        
        --get next ID
        function next()
            return box.sequence["id"]:next()
        end
      
