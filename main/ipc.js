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

ipcMain.on('addTransaction', (evt, transaction) => {
  console.log(`addTransaction: ${transaction.description}`)
  let t = new acc.Transaction(
    new Date(transaction.date), 
    transaction.debits.map(d => new acc.Debit(ledger.accounts.get(d.account), d.amount)), 
    transaction.credits.map(c => new acc.Credit(ledger.accounts.get(c.account), c.amount)) 
  )
  t.setDescription(transaction.description)
  ledger.addTransaction(t)
  ledgerUpdated()
})

function ledgerUpdated () {
  const win = BrowserWindow.getFocusedWindow()
  win.webContents.send('ledgerUpdated', ledger)
}
