'use strict'

const ledger = new Ledger('simple')
ledger.assets.addChild(new Assets('Bank Account'))

let t = new Transaction(new Date(), [new Debit(ledger.assets.children[0], 3000)],
  [new Credit(ledger.equity, 3000)])
t.setDescription('Opening Balance')
ledger.addTransaction(t)

t = new Transaction(new Date(), [new Debit(ledger.expenses, 50)], [new Credit(ledger.assets.children[0], 50)])
t.setDescription('First expense')
ledger.addTransaction(t)

console.log(JSON.stringify(ledger, null, 2))

function addTransaction (evt, transaction) {
  console.log(`addTransaction: ${transaction.description}`)
  let t = new Transaction(
    new Date(transaction.date),
    transaction.debits.map(d => new Debit(ledger.accounts.get(d.account), d.amount)),
    transaction.credits.map(c => new Credit(ledger.accounts.get(c.account), c.amount))
  )
  t.setDescription(transaction.description)
  ledger.addTransaction(t)
  ledgerUpdated()
}
