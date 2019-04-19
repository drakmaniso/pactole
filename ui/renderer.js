// This file is required by the index.html file and will
// be executed in the renderer process for that window.
// All of the Node.js APIs are available in this process.

'use strict'

const { ipcRenderer } = require('electron')

document.getElementById('add-expanse').addEventListener('click', evt => {
  evt.preventDefault()
  console.log('plop')
  let exp = {
    date: document.getElementById('add-date').value,
    description: document.getElementById('add-description').value,
    value: document.getElementById('add-value').value
  }
  ipcRenderer.send('add-expanse', exp)
})

ipcRenderer.on('update-list', (evt, expanses) => {
  console.log(`update-list: ${expanses.length}`)
  const expEl = document.getElementById('expanse-list')
  expEl.innerHTML = ''
  for (let e of expanses) {
    let item = document.createElement('li')
    item.textContent = `${e.date}: ${e.description} ${e.value}`
    expEl.appendChild(item)
  }
})
