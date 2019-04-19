'use strict'

class Ledger {
  // name: a string that uniquely identifies the ledger
  // description: an informal string
  // accounts: a Map from string to Accounts objects
  // transactions: an array of Transaction objects

  constructor (name) {
    this.name = name
    this.description = ''
    this.accounts = new Map()
    this.transactions = []
  }

  setDescription (description) {
    this.description = description
  }

  addAccount (account) {
    if (this.accounts.has(account.name)) {
      return new Error('ledger already contains an account with the same name')
    }

    if (account.parent !== null) {
      if (!this.accounts.has(account.parent.name)) {
        return new Error('parent of the account is not in the ledger')
      }
      const p = this.accounts.get(account.parent.name)
      p.children.push(account)
    }

    this.accounts.set(account.name, account)

    return this
  }

  addTransaction (transaction) {
  }
}

class Account {
  // - name: string that uniquely identifies the account
  // - description: informal string
  // - parent: Account object, or null
  constructor (name, parent = null) {
    this.name = name
    this.description = ''
    this.parent = parent
    this.children = []
  }

  setDescription (description) {
    this.description = description
  }
}

class Transaction {
  // date: a javascript Date, corresponding to the date of the transaction.
  // description: string (possibly empty) to describe the transaction.
  // debits: array of Debit objects.
  // credits: array of Credit objects.

  constructor (date, debits, credits) {
    let sum = 0
    if (debits.length === 0) {
      return new Error('no debit in transaction')
    }
    for (let d of debits) {
      if (!(d instanceof Debit)) {
        return new Error('wrong object type in debits')
      }
      sum += d.amount
    }
    if (credits.length === 0) {
      return new Error('no credit in transaction')
    }
    for (let c of credits) {
      if (!(c instanceof Credit)) {
        return new Error('wrong object type in credits')
      }
      sum -= c.amount
    }
    if (sum !== 0) {
      return new Error('imbalanced transaction')
    }

    this.date = date
    this.description = ''
    this.debits = debits
    this.credits = credits
  }

  setDescription (description) {
    this.description = description
  }
}

class Debit {
  // - account: an Account object
  // - amount: an integer (amount in cents)
  constructor (account, amount) {
    this.account = account
    this.amount = amount
  }
}

class Credit {
  // - account: an Account object
  // - amount: an integer (amount in cents)
  constructor (account, amount) {
    this.account = account
    this.amount = amount
  }
}

module.exports = Object.freeze({
  Ledger: Ledger,
  Account: Account,
  Transaction: Transaction,
  Debit: Debit,
  Credit: Credit
})
