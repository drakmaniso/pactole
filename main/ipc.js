'use strict'

module.exports = Object.freeze({
  ledgerUpdated: ledgerUpdated
})

const { ipcMain, BrowserWindow } = require('electron')
const acc = require('./accounting.js')

const ledger = new acc.Ledger('simple')
ledger.assets.addChild(new acc.Assets('Bank Account'))

let t = new acc.Transaction(new Date(), [new acc.Debit(ledger.assets.children[0], 3000)],
  [new acc.Credit(ledger.equity, 3000)])
t.setDescription('Opening Balance')
ledger.addTransaction(t)

t = new acc.Transaction(new Date(), [new acc.Debit(ledger.expenses, 50)], [new acc.Credit(ledger.assets.children[0], 50)])
t.setDescription('First expense')
ledger.addTransaction(t)

console.log(JSON.stringify(ledger, null, 2))

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
