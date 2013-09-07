chai = require 'chai'
sinon = require 'sinon'
chai.use require 'sinon-chai'

expect = chai.expect

describe 'hello-world', ->
  beforeEach ->
    @robot =
      respond: sinon.spy()
      hear: sinon.spy()

    require('../src/dinosaur-comics')(@robot)

  it 'responds to request for latest comic', ->
    expect(@robot.respond).to.have.been.calledWith(/dino(saur)? comics?$/i)

  it 'responds to request for random comic', ->
    expect(@robot.respond).to.have.been.calledWith(/dino(saur)? comics? random$/i)
