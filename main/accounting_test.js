'use strict'

const acc = require('./accounting.js')

let l = new acc.Ledger("simple")
console.log(l)
console.log(l.setDescription("My simple ledger"))

let foo = new acc.Account("foo")
console.log(foo)

let bar = new acc.Account("bar")
let foobar = new acc.Account("foo")
let baz = new acc.Account("baz", bar)

console.log(l.addAccount(foo))
console.log(l.addAccount(baz))
console.log(l.addAccount(bar))
console.log(l.addAccount(foobar))
console.log(l.addAccount(baz))

let e = new acc.Transaction(new Date(), [], [])
console.log(e)
e = new acc.Transaction(new Date(), [new acc.Debit(foo, 33)], [])
console.log(e)
e = new acc.Transaction(new Date(), [new acc.Debit(foo, 22)], [new acc.Credit(bar, 33)])
console.log(e)
e = new acc.Transaction(new Date(), [new acc.Credit(foo, 33)], [new acc.Credit(bar, 33)])
console.log(e)
e = new acc.Transaction(new Date(), [new acc.Debit(foo, 33)], [new acc.Debit(bar, 33)])
console.log(e)


let t1 = new acc.Transaction(
  new Date(),
  [new acc.Debit(foo, 33)],
  [new acc.Credit(bar, 33)]
)
console.log(t1)

let t2 = new acc.Transaction(
  new Date(),
  [new acc.Debit(foo, 20), new acc.Debit(foo, 80)],
  [new acc.Credit(bar, 70), new acc.Credit(baz, 30)]
)
console.log(t2)
