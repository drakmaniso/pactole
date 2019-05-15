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

const dummy = {
  "name": "simple",
  "description": "",
  "assets": {
    "name": "Assets",
    "description": "",
    "children": [
      {
        "name": "Compte courant",
        "description": "",
        "children": []
      }
    ]
  },
  "liabilities": {
    "name": "Liabilities",
    "description": "",
    "children": []
  },
  "equity": {
    "name": "Equity",
    "description": "",
    "children": []
  },
  "income": {
    "name": "Income",
    "description": "",
    "children": [
      {
        "name": "Allocations",
        "description": "",
        "children": []
      },
      {
        "name": "Salaire",
        "description": "",
        "children": []
      }
    ]
  },
  "expenses": {
    "name": "Expenses",
    "description": "",
    "children": [
      {
        "name": "Alimentation",
        "description": "",
        "children": []
      },
      {
        "name": "Factures",
        "description": "",
        "children": []
      },
      {
        "name": "Frais bancaires",
        "description": "",
        "children": []
      },
      {
        "name": "Habillement",
        "description": "",
        "children": []
      },
      {
        "name": "Loisirs",
        "description": "",
        "children": []
      },
      {
        "name": "Loyer",
        "description": "",
        "children": []
      },
      {
        "name": "Santé",
        "description": "",
        "children": []
      },
      {
        "name": "Transports",
        "description": "",
        "children": []
      }
    ]
  },
  "transactions": [
    {
      "date": "2019-05-09T10:00:00.000Z",
      "description": "Montant initial",
      "debits": [
        {
          "account": "Compte courant",
          "amount": 3000
        }
      ],
      "credits": [
        {
          "account": "Equity",
          "amount": 3000
        }
      ],
      "reconciled": false
    },
    {
      "date": "2019-05-09T10:00:00.000Z",
      "description": "First expense",
      "debits": [
        {
          "account": "Loyer",
          "amount": 500
        }
      ],
      "credits": [
        {
          "account": "Compte courant",
          "amount": 500
        }
      ],
      "reconciled": false
    }
  ]
}

console.log(JSON.stringify(ledger, null, 2))

export default ledger
