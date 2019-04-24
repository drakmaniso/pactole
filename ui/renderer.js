// This file is required by the index.html file and will
// be executed in the renderer process for that window.
// All of the Node.js APIs are available in this process.

'use strict'

const { ipcRenderer } = require('electron')

document.getElementById('add-expanse').addEventListener('click', evt => {
  evt.preventDefault()
  let date = document.getElementById('add-date').valueAsDate.getTime()
  let desc = document.getElementById('add-description').value
  let value = document.getElementById('add-value').valueAsNumber
  ipcRenderer.send('addTransaction', {
    date: date,
    description: desc,
    debits: [{ account: 'Expenses', amount: value }],
    credits: [{ account: 'Bank Account', amount: value }]
  })
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
