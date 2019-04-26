'use strict'

let datastore = require('./datastore.js')
let ipc = require('./ipc.js')

const { app, BrowserWindow } = require('electron')

let win

function createWindow () {
  win = new BrowserWindow({
    width: 800,
    height: 600,
    webPreferences: {
      nodeIntegration: true,
      allowEval: false
    }
  })

  win.loadFile('ui/index.html')
  datastore.setup()
  datastore.save()

  //win.webContents.openDevTools()

  win.on('closed', function () {
    win = null
  })

  win.webContents.on('dom-ready', () => {
    console.log('window shown')
    ipc.ledgerUpdated()
  })
}

app.on('ready', createWindow)

app.on('window-all-closed', function () {
  // On macOS it is common for applications and their menu bar
  // to stay active until the user quits explicitly with Cmd + Q
  if (process.platform !== 'darwin') app.quit()
})

app.on('activate', function () {
  // On macOS it's common to re-create a window in the app when the
  // dock icon is clicked and there are no other windows open.
  if (win === null) createWindow()
})
