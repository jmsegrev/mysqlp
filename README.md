mysqlp
------

# Install

`npm install jmsegrev/mysqlp`

# Usage

## Configuration

`
mysqlp = require 'mysqlp'

configuration = {
  master: {
    host: 'host_x',
    database: 'database_x',
    user: 'user_x',
    password: 'password_x'
  },
  slave1: {
    host: 'host_x',
    database: 'database_x',
    user: 'user_x',
    password: 'password_x'
  },
  slave2: {
    host: 'host_x',
    database: 'database_x',
    user: 'user_x',
    password: 'password_x'
  },
  namex: {
    host: 'host_x',
    database: 'database_x',
    user: 'user_x',
    password: 'password_x'
  }
}

mysqlp.config(configuration)
`

All the connection configurations will be added to a mysql.poolCluster.
The slave* connections will be fetched with the default cluster mysql.poolCluster 
selector 'RR' (Round-Robin). Any other connection configuration (e.g. master, namex, whateveryouwant )
will be used directly.

## Queries 

`
#The slave mysql.cluster will be used to connect
mysqlp.connect('slave') # slave will return the promise for the round robin selected configuration connection
  .then (connection) ->
    # same as mysql connection.query
    connection.query('select username from users where user_id=?', [1]) 
      .spread (rows, fields) ->
        console.log rows

    .finally ->
      connection.end()
`

## Transactions

`
mysqlp.connect('master') 
  .then (connection) ->
    connection.begin () ->

      @query('SELECT * FROM table_x WHERE column_a > ?', [42]) 
        .spread (rows, fields) => # nested queries will need to bind this on previous context

          if rows.length > 0

            @query('UPDATE table_z SET column_b = ?', ['anything'])
              .spread (rows, fields) =>
  
                if rows.affectedRows is 1
                  @commit()
                else
                  @rollback() 
          else
            @rollback() 


    .finally ->
      connection.end()


