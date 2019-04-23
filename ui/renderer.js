// This file is required by the index.html file and will
// be executed in the renderer process for that window.
// All of the Node.js APIs are available in this process.

'use strict'

const { ipcRenderer } = require('electron')
const acc = require('../main/accounting.js')

document.getElementById('add-expanse').addEventListener('click', evt => {
  evt.preventDefault()
  console.log('plop')
  let exp = {
    date: document.getElementById('add-date').valueAsDate.getTime(),
    description: document.getElementById('add-description').value,
    value: document.getElementById('add-value').valueAsNumber
  }
  ipcRenderer.send('add-expanse', exp)
})

ipcRenderer.on('ledgerUpdated', (evt, ledger) => {
  console.log(`ledgerUpdated: ${ledger}`)
  const expEl = document.getElementById('transactions')
  expEl.innerHTML = ''
  for (let t of ledger.transactions) {
    let item = document.createElement('li')
    item.textContent = `${t.date}: ${t.description}`
    expEl.appendChild(item)
  }
})
