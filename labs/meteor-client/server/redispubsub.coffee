class Meteor.RedisPubSub
  constructor: () ->
    console.log "constructor RedisPubSub"

    @pubClient = redis.createClient()
    @subClient = redis.createClient()

    @subClient.on "psubscribe", Meteor.bindEnvironment(@_onSubscribe )
    @subClient.on "pmessage", Meteor.bindEnvironment(@_onMessage)

    #log.info
    console.log("RPC: Subscribing message on channel: #{Meteor.config.redis.channels.fromBBBApps}")
    @subClient.psubscribe(Meteor.config.redis.channels.fromBBBApps)

  # Construct and send a message to bbb-web to validate the user
  sendValidateToken: (meetingId, userId, authToken) ->
    console.log "\n\n i am sending a validate_auth_token with " + userId + "" + meetingId

    message = {
      "payload": {
        "auth_token": authToken
        "userid": userId
        "meeting_id": meetingId
      },
      "header": {
        "timestamp": new Date().getTime()
        "reply_to": meetingId + "/" + userId
        "name": "validate_auth_token"
      }
    }
    if authToken? and userId? and meetingId?
      @pubClient.publish(Meteor.config.redis.channels.toBBBApps.meeting, JSON.stringify(message))
    else
      console.log "did not have enough information to send a validate_auth_token message"

  _onSubscribe: (channel, count) ->
    #Meteor.call("addToCollection");
    console.log "Subscribed to #{channel}"

  _onMessage: (pattern, channel, jsonMsg) =>
    # TODO: this has to be in a try/catch block, otherwise the server will
    # crash if the message has a bad format
    console.log "ON MESSAGE"
    message = JSON.parse(jsonMsg)
    correlationId = message.payload?.reply_to or message.header?.reply_to
    
    unless message.header?.name is "keep_alive_reply"
      console.log "\nchannel=" + channel
      console.log "correlationId=" + correlationId if correlationId?
      console.log "eventType=" + message.header?.name + "\n"
      #log.debug({ pattern: pattern, channel: channel, message: message}, "Received a message from redis")
      console.log "GOT MESSAGE:" + jsonMsg

    if message.header?.name is "user_joined_message"
      console.log "this is user_joined_message"

      Meteor.call("addToCollection", message.payload.user.userid, message.payload.meeting_id);

      console.log "end"
