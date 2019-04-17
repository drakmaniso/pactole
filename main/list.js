'use strict'

module.exports = Object.freeze({
  render: render
})

const { ipcMain, BrowserWindow } = require('electron')

let expanses = [
  {date: '2014-02-03', description: 'foo', value: 33},
  {date: '2018-03-01', description: 'bar', value: 42.25}
]

ipcMain.on('add-expanse', (evt, exp) => {
  console.log(exp)
  expanses.push(exp)
  render()
})


function getList () {
  return expanses
}

function render () {
  const win = BrowserWindow.getFocusedWindow()
  win.webContents.send('update-list', expanses)
}
