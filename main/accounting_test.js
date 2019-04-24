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

let foo = new acc.Account('foo')
assert.ok(foo instanceof acc.Account)
assert.equal(foo.name, 'foo')

let bar = new acc.Account('bar')
assert.ok(bar instanceof acc.Account)

let foobar = new acc.Account('foo')
assert.ok(foobar instanceof acc.Account)

let baz = new acc.Account('baz', bar)
assert.ok(baz instanceof acc.Account)

assert.doesNotThrow(() => l.addAccount(foo))
assert.throws(() => l.addAccount(baz))
assert.doesNotThrow(() => l.addAccount(bar))
assert.throws(() => l.addAccount(foobar))
assert.doesNotThrow(() => l.addAccount(baz))

assert.throws(() => { _ = new acc.Transaction(new Date(), [], []) })
assert.throws(() => { _ = new acc.Transaction(new Date(), [new acc.Debit(foo, 33)], []) })
assert.throws(() => { _ = new acc.Transaction(new Date(), [new acc.Debit(foo, 22)], [new acc.Credit(bar, 33)]) })
assert.throws(() => { _ = new acc.Transaction(new Date(), [new acc.Credit(foo, 33)], [new acc.Credit(bar, 33)]) })
assert.throws(() => { _ = new acc.Transaction(new Date(), [new acc.Debit(foo, 33)], [new acc.Debit(bar, 33)]) })

let t1
assert.doesNotThrow(() => {
  t1 = new acc.Transaction(
    new Date(2000, 0, 1, 8),
    [new acc.Debit(foo, 33)],
    [new acc.Credit(bar, 33)]
  )
})
assert.ok(t1 instanceof acc.Transaction)

let t2
assert.doesNotThrow(() => {
  t2 = new acc.Transaction(
    new Date(2000, 0, 3, 8),
    [new acc.Debit(foo, 20), new acc.Debit(foo, 80)],
    [new acc.Credit(bar, 70), new acc.Credit(baz, 30)]
  )
})
assert.ok(t2 instanceof acc.Transaction)

let t3
assert.doesNotThrow(() => {
  t3 = new acc.Transaction(
    new Date(2000, 0, 2, 8),
    [new acc.Debit(foo, 20), new acc.Debit(foo, 80)],
    [new acc.Credit(bar, 70), new acc.Credit(baz, 30)]
  )
})
assert.ok(t2 instanceof acc.Transaction)

l.addTransaction(t1)
l.addTransaction(t3)
l.addTransaction(t2)
console.log(JSON.stringify(l, null, 2))
