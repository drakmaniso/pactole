'use strict'

import * as ledger from './ledger.js'

const log = console.log

async function test() {
  log('Opening the ledger...')
  let acc = await ledger.open('First')
  log('Ledger opened:')
  log(acc)
}

test()
