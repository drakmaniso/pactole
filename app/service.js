'use strict'

function log(msg) {
  console.log(`[service] ${msg}`)
}

oninstall = (event) => {
	log('Installed.')
}

onactivate = (event) => {
	event.waitUntil(clients.claim())
	log('Activated.')
}

onfetch = (event) => {
	//log(`Fetch: ${event.request.url}`)
	switch(event.request.url) {
    case 'http://localhost:8383/accounts.json':
			event.respondWith(new Response('{"name": "foobar"}'))
		default:
	}
//  event.respondWith(
//    caches.match(event.request)
//      .then(function(response) {
//         if (response) {
//           return response
//         }
//        return fetch(event.request)
//      }
//    )
//  )
}

onmessage = (event) => {
  log(`Received ${event.data.msg}.`)
  switch(event.data.msg) {
    case 'open':
      send({msg: 'update'})
      break
    case 'get accounts':
      log('sending accounts reply')
      event.ports[0].postMessage({
        msg: 'accounts',
        accounts: dummyAccounts,
      })
      break
    case 'get transactions':
      log('sending transactions reply')
      event.ports[0].postMessage({
        msg: 'transactions',
        transactions: dummyTransactions,
      })
      break;
  }
}

async function send(message) {
  const all = await clients.matchAll({
    includeUnctonrolled: true
  })
  log(`Sending ${message.msg} to ${all.length} client(s)...`)
  for(const c of all) {
    c.postMessage(message)
  }
}

const dummyAccounts = [
  {name: 'Mon Compte', kind: 'assets'},
  {name: 'Solde Initial', kind: 'equity'},
  {name: 'Salaire', kind: 'income'},
  {name: 'Allocations', kind: 'income'},
  {name: 'Autre', kind: 'income'},
  {name: 'Alimentation', kind: 'expense'},
  {name: 'Habillement', kind: 'expense'},
  {name: 'Loyer', kind: 'expense'},
  {name: 'Frais bancaires', kind: 'expense'},
  {name: 'Électricité', kind: 'expense'},
  {name: 'Téléphone', kind: 'expense'},
  {name: 'Santé', kind: 'expense'},
  {name: 'Loisirs', kind: 'expense'},
  {name: 'Transports', kind: 'expense'},
  {name: 'Économies', kind: 'expense'},
  {name: 'Divers', kind: 'expense'},
]

const dummyTransactions = [
  {date: new Date(2019, 4, 2), debits: [{account: 'Allocations', amount: 50000}], credits: [{account: 'Mon Compte', amount: 50000}], description: 'AAH', reconciled: false},
  {date: new Date(2019, 4, 2), debits: [{account: 'Allocations', amount: 20000}], credits: [{account: 'Mon Compte', amount: 20000}], description: '', reconciled: false},
  {date: new Date(2019, 4, 3), debits: [{account: 'Loyer', amount: 56000}], credits: [{account: 'Mon Compte', amount: 56000}], description: '', reconciled: false},
  {date: new Date(2019, 4, 3), debits: [{account: 'Électricité', amount: 15000}], credits: [{account: 'Mon Compte', amount: 15000}], description: '', reconciled: false},
  {date: new Date(2019, 4, 3), debits: [{account: 'Téléphone', amount: 3000}], credits: [{account: 'Mon Compte', amount: 3000}], description: '', reconciled: false},
  {date: new Date(2019, 4, 18), debits: [{account: 'Alimentation', amount: 6000}], credits: [{account: 'Mon Compte', amount: 6000}], description: 'courses Super U', reconciled: false},
  {date: new Date(2019, 4, 18), debits: [{account: 'Divers', amount: 2000}], credits: [{account: 'Mon Compte', amount: 2000}], description: 'distributeur', reconciled: false},
  {date: new Date(2019, 4, 20), debits: [{account: 'Habillement', amount: 3200}], credits: [{account: 'Mon Compte', amount: 3200}], description: 'La Halle aux Vêtements', reconciled: false},
  {date: new Date(2019, 4, 21), debits: [{account: 'Divers', amount: 2000}], credits: [{account: 'Mon Compte', amount: 2000}], description: 'distributeur', reconciled: false},
  {date: new Date(2019, 4, 23), debits: [{account: 'Transports', amount: 5500}], credits: [{account: 'Mon Compte', amount: 5500}], description: 'essence', reconciled: false},
  {date: new Date(2019, 4, 24), debits: [{account: 'Loisirs', amount: 3500}], credits: [{account: 'Mon Compte', amount: 3500}], description: 'Raspberry Pi', reconciled: false},
]
