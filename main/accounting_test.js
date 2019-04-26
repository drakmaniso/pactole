'use strict'

const assert = require('assert').strict
const acc = require('./accounting.js')

let _ // used to silence standard 'variable not used' complaints
if (_) {}

let l = new acc.Ledger('simple')
assert.ok(l instanceof acc.Ledger)
assert.equal(l.name, 'simple')
l.setDescription('My simple ledger')
assert.equal(l.description, 'My simple ledger')

/*assert.doesNotThrow(() => l.addAccount(new acc.Account('foo')))
assert.doesNotThrow(() => l.addAccount(new acc.Account('bar')))
assert.throws(() => l.addAccount(new acc.Account('foo')))
assert.doesNotThrow(() => l.account('foo').addChild('baz'))*/

assert.throws(() => { _ = new acc.Transaction(new Date(), [], []) })
assert.throws(() => { _ = new acc.Transaction(new Date(), [new acc.Debit(l.expenses, 33)], []) })
assert.throws(() => { _ = new acc.Transaction(new Date(), [new acc.Debit(l.expenses, 22)], [new acc.Credit(l.assets, 33)]) })
assert.throws(() => { _ = new acc.Transaction(new Date(), [new acc.Credit(l.expenses, 33)], [new acc.Credit(l.assets, 33)]) })
assert.throws(() => { _ = new acc.Transaction(new Date(), [new acc.Debit(l.expenses, 33)], [new acc.Debit(l.assets, 33)]) })

let t1
assert.doesNotThrow(() => {
  t1 = new acc.Transaction(
    new Date(2000, 0, 1, 8),
    [new acc.Debit(l.expenses, 33)],
    [new acc.Credit(l.assets, 33)]
  )
})
assert.ok(t1 instanceof acc.Transaction)

let t2
assert.doesNotThrow(() => {
  t2 = new acc.Transaction(
    new Date(2000, 0, 3, 8),
    [new acc.Debit(l.expenses, 20), new acc.Debit(l.expenses, 80)],
    [new acc.Credit(l.assets, 70), new acc.Credit(l.assets, 30)]
  )
})
assert.ok(t2 instanceof acc.Transaction)

let t3
assert.doesNotThrow(() => {
  t3 = new acc.Transaction(
    new Date(2000, 0, 2, 8),
    [new acc.Debit(l.expenses, 20), new acc.Debit(l.expenses, 80)],
    [new acc.Credit(l.assets, 70), new acc.Credit(l.assets, 30)]
  )
})
assert.ok(t2 instanceof acc.Transaction)

l.addTransaction(t1)
l.addTransaction(t3)
l.addTransaction(t2)
console.log(JSON.stringify(l, null, 2))
