'use strict'

module.exports = Object.freeze({
  setup: setup,
  save: save
})

const { app } = require('electron')
const fs = require('fs')
const path = require('path')

let datapath = '.'

function setup () {
  datapath = path.join(app.getPath('userData'), 'datastore.txt')
}

function save () {
  fs.writeFile(datapath, 'Hello, World!', 'utf8', function () {})
}
