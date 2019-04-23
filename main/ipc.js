'use strict'

module.exports = Object.freeze({
  ledgerUpdated: ledgerUpdated
})

const { ipcMain, BrowserWindow } = require('electron')
const acc = require('./accounting.js')

let ledger = new acc.Ledger('simple')
let bank = new acc.Account('Bank Account')
ledger.addAccount(bank)
let expenses = new acc.Account('Expenses')
ledger.addAccount(expenses)
let t = new acc.Transaction(new Date(), [new acc.Debit(expenses, 50)], [new acc.Credit(bank, 50)])
t.setDescription('First transaction')
ledger.addTransaction(t)

ipcMain.on('add-expanse', (evt, exp) => {
  console.log(exp)
  let t = new acc.Transaction(new Date(exp.date), [new acc.Debit(expenses, exp.value)], [new acc.Credit(bank, exp.value)])
  console.log(t)
  t.setDescription(exp.description)
  ledger.addTransaction(t)
  ledgerUpdated()
})

function ledgerUpdated () {
  const win = BrowserWindow.getFocusedWindow()
  win.webContents.send('ledgerUpdated', ledger)
}
