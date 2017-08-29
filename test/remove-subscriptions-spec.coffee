_                  = require 'lodash'
mongojs            = require 'mongojs'
Datastore          = require 'meshblu-core-datastore'
RemoveSubscriptions = require '../'

describe 'RemoveSubscriptions', ->
  beforeEach (done) ->
    @datastore = new Datastore
      database: mongojs 'subscription-manager-test'
      collection: 'subscriptions'

    @datastore.remove done

  beforeEach ->
    @uuidAliasResolver = resolve: (uuid, callback) => callback(null, uuid)
    @sut = new RemoveSubscriptions {@datastore, @uuidAliasResolver}

  describe '->do', ->
    context 'when given a valid request', ->
      beforeEach (done) ->
        subscription = {subscriberUuid:'superman', emitterUuid: 'spiderman', type:'broadcast'}
        @datastore.insert subscription, done

      beforeEach (done) ->
        subscription = {subscriberUuid:'superman', emitterUuid: 'batman', type:'broadcast'}
        @datastore.insert subscription, done

      beforeEach (done) ->
        request =
          metadata:
            toUuid: 'superman'
            responseId: 'its-electric'
          rawData: JSON.stringify({emitterUuid: null})

        @sut.do request, (error, @response) => done error

      it 'should not have a subscription', (done) ->
        @datastore.find {subscriberUuid: 'superman'}, (error, subscriptions) =>
          return done error if error?
          expect(subscriptions).to.deep.equal []
          done()

      it 'should return a 204', ->
        expectedResponse =
          metadata:
            responseId: 'its-electric'
            code: 204
            status: 'No Content'

        expect(@response).to.deep.equal expectedResponse

    context 'when given a invalid request', ->
      beforeEach (done) ->
        request =
          metadata:
            responseId: 'its-electric'
          rawData: JSON.stringify({subscriberUuid:'superman', type:'broadcast'})

        @sut.do request, (error, @response) => done error

      it 'should not have a subscription', (done) ->
        @datastore.find {subscriberUuid: 'superman', emitterUuid: 'spiderman', type: 'broadcast'}, (error, subscriptions) =>
          return done error if error?
          expect(subscriptions).to.deep.equal []
          done()

      it 'should return a 422', ->
        expectedResponse =
          metadata:
            responseId: 'its-electric'
            code: 422
            status: 'Unprocessable Entity'

        expect(@response).to.deep.equal expectedResponse
