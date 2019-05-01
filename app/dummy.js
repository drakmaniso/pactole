'use strict'

import * as accounting from './accounting.js'

const ledger = new accounting.Ledger('simple')
ledger.assets.addChild(new accounting.Assets('Compte courant'))
ledger.expenses.addChild(new accounting.Expenses('Alimentation'))
ledger.expenses.addChild(new accounting.Expenses('Factures'))
ledger.expenses.addChild(new accounting.Expenses('Frais bancaires'))
ledger.expenses.addChild(new accounting.Expenses('Habillement'))
ledger.expenses.addChild(new accounting.Expenses('Loisirs'))
ledger.expenses.addChild(new accounting.Expenses('Loyer'))
ledger.expenses.addChild(new accounting.Expenses('Santé'))
ledger.expenses.addChild(new accounting.Expenses('Transports'))
ledger.income.addChild(new accounting.Income('Allocations'))
ledger.income.addChild(new accounting.Income('Salaire'))

let t = new accounting.Transaction(new Date(),
  [new accounting.Debit(ledger.getAccount('assets', 'Compte courant'), 3000)],
  [new accounting.Credit(ledger.equity, 3000)])
t.setDescription('Montant initial')
ledger.addTransaction(t)

t = new accounting.Transaction(new Date(),
  [new accounting.Debit(ledger.getAccount('expenses', 'Loyer'), 500)],
  [new accounting.Credit(ledger.getAccount('assets', 'Compte courant'), 500)])
t.setDescription('First expense')
ledger.addTransaction(t)

//console.log(JSON.stringify(ledger, null, 2))

function addTransaction (evt, transaction) {
  console.log(`addTransaction: ${transaction.description}`)
  let t = new accounting.Transaction(
    new Date(transaction.date),
    transaction.debits.map(d => new Debit(ledger.accounts.get(d.account), d.amount)),
    transaction.credits.map(c => new Credit(ledger.accounts.get(c.account), c.amount))
  )
  t.setDescription(transaction.description)
  ledger.addTransaction(t)
  ledgerUpdated()
}

export default ledger
