'use strict'

import * as datastore from './datastore.js'

const foo = {
  name: "Foo",
  children: [],
}
foo.children.push(foo)
const bar = {
  name: "Bar",
  descendants: [],
}
bar.descendants.push(foo)

console.log('Opening database...')

datastore.open()
  .then(function() {
    console.log('Datastore opened. Adding foo...')
    return datastore.add2(foo, 'assets')
  })
  .then(function() {
    console.log('Foo added. Getting foo...')
    return datastore.get2('Foo', 'assets')
  })
  .then(function(foo2) {
    console.log('Foo received:')
    console.log(foo2)
    if (foo2.children[0] === foo2) {
      console.log('Foo cycle preserved!')
    } else {
      console.log('*** Foo cycle NOT preserved. ***')
    }
  })
  .then(function() {
    console.log('Adding bar...')
    return datastore.add2(bar, 'ledgers')
  })
  .then(function() {
    console.log('Bar added. Getting foo and bar...')
    return datastore.get3('Foo', 'Bar')
  })
  .then(function (args) {
    console.log('Foo and Bar received:')
    console.log(args)
    let [foo2, bar2] = args
    console.log(foo2)
    console.log(bar2)
    if (bar2.descendants[0] === foo2) {
      console.log('Cross-store reference preserved!')
    } else {
      console.log('*** Cross-store reference NOT preserved. ***')
    }
  })
  .catch(err => {
    console.log(`Top-level error: ${err}`)
  })

if (datastore.hasError()) {
  console.log(`Datastore sticky error: ${datastore.error()}`)
}
