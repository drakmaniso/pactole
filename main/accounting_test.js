'use strict'

const assert = require('assert').strict
const acc = require('./accounting.js')

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

assert.ok(l.addAccount(foo) instanceof acc.Ledger)
assert.ok(l.addAccount(baz) instanceof Error)
assert.ok(l.addAccount(bar) instanceof acc.Ledger)
assert.ok(l.addAccount(foobar) instanceof Error)
assert.ok(l.addAccount(baz) instanceof acc.Ledger)

let e = new acc.Transaction(new Date(), [], [])
assert.ok(e instanceof Error, e)
e = new acc.Transaction(new Date(), [new acc.Debit(foo, 33)], [])
assert.ok(e instanceof Error)
e = new acc.Transaction(new Date(), [new acc.Debit(foo, 22)], [new acc.Credit(bar, 33)])
assert.ok(e instanceof Error)
e = new acc.Transaction(new Date(), [new acc.Credit(foo, 33)], [new acc.Credit(bar, 33)])
assert.ok(e instanceof Error)
e = new acc.Transaction(new Date(), [new acc.Debit(foo, 33)], [new acc.Debit(bar, 33)])
assert.ok(e instanceof Error)

let t1 = new acc.Transaction(
  new Date(),
  [new acc.Debit(foo, 33)],
  [new acc.Credit(bar, 33)]
)
assert.ok(t1 instanceof acc.Transaction)

let t2 = new acc.Transaction(
  new Date(),
  [new acc.Debit(foo, 20), new acc.Debit(foo, 80)],
  [new acc.Credit(bar, 70), new acc.Credit(baz, 30)]
)
assert.ok(t2 instanceof acc.Transaction)
