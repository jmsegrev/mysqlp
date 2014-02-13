
mysql = require 'mysql'
Promise = require 'bluebird'


connectionWrapper = (connection, poolCluster) ->

  db =

    query: (sql, values) ->

      return (Promise.promisify connection.query, connection) sql, values



    begin: (callback) ->

      self = this
      transactionDeferred = Promise.defer()

      transaction = {}

      transaction.rollback = ->
        @rolledback = true
        #TODO reject with error
        transactionDeferred.reject()
        connection.rollback ->

      transaction.commit = ->
        unless @rolledback
          connection.commit (err) =>
            if err
              @rollback()
              throw err

            else
              transactionDeferred.resolve(true)

      transaction.query = (sql, values) ->
        self.query sql, values
          .catch (err) =>
            @rollback()
            console.log 'Begin query error', err.message


      connection.beginTransaction (err) ->
        transaction.callback = callback
        transaction.callback()

      return transactionDeferred.promise

    end: () ->
      poolCluster.end()






module.exports =

  config: (config) ->
    @_poolCluster = mysql.createPoolCluster
      canRetry: true
      removeNodeErrorCount: 2
      defaultSelector: 'RR'

    for group, configuration of config
      @_poolCluster.add group, configuration

  connect: (group) ->

    if group is 'slave'
      #TODO set pool selection to be configurable 
      pool = @_poolCluster.of group.toLowerCase() + '*'
      getConnection = Promise.promisify pool.getConnection, pool
      getConnection()
        .then (connection) =>
          return connectionWrapper(connection, @_poolCluster)

    else
      getConnection = Promise.promisify @_poolCluster.getConnection, @_poolCluster
      getConnection(group.toLowerCase())
        .then (connection) =>
          return connectionWrapper(connection, @_poolCluster)
    
 
