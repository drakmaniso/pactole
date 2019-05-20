'use strict'

import * as client from './client.js'

function log(msg) {
  console.log(`[client] ${msg}`)
}

if (!('serviceWorker' in navigator)) {
  log('FATAL: Service workers are not supported by the navigator.')
  throw(new Error('FATAL: Service workers are not supported by the navigator.'))
}

navigator.storage.persist().then(persisted => {
  if(persisted) {
    log('Persistent storage allowed.')
    navigator.storage.estimate().then(info => {
      log(`Persistent usage: ${Math.round(info.usage/1024)}kb (quota: ${Math.round(info.quota/1024)}kb).`)
    })
  } else {
    log('*** NOT Persisted! ***')
  }
})

onload = () => {
  navigator.serviceWorker.register('/app/service.js')
    .then((registration) => {
      log(`Service registration successful (scope: ${registration.scope})`)
      registration.onupdatefound = () => {
        let w = registration.installing
        log(`A new service is being installed...`)
        w.onstatechange = (event) => {
          if(event.target.state === 'installed') {
            log(`The new service has been installed.`)
            //TODO: restart service?
            //location.reload(true)
          }
        }
      }
    })
    .catch((err) => {
      log(`Service registration failed: ${err}`)
    })
}

//navigator.serviceWorker.startMessages()

navigator.serviceWorker.ready.then((registration) => {
  client.setup(registration.active)
  main()
})

function main() {
	log(`Starting application...`)

  client.addUpdateListener(onUpdate)
  client.addAccountsListener(onAccounts)

	client.send({msg: 'open', name: 'Mon Compte'})

  window.scrollTo(0, document.body.scrollHeight)

  wireHTML()
}

function onUpdate(message) {
  log(`onUpdate ${message}`)
  client.send({msg: 'get accounts'})
}

function onAccounts(message) {
  log(`onAccounts (${message.accounts.length})`)
  return
  const sidebar = document.getElementById('sidebar')
  while(sidebar.hasChildNodes()) {
    sidebar.removeChild(sidebar.firstChild)
  }
  //const shadow = sidebar.attachShadow({mode: 'open'})
  const list = document.createElement('ul')
  list.id = 'transactions-income-actions'
  //shadow.appendChild(list)
  for(const a of message.accounts) {
    const b = document.createElement('button')
    b.textContent = a.name
    b.setAttribute('class', 'action')
    b.setAttribute('value', a.name)
    list.appendChild(b)
  }
  sidebar.appendChild(list)
}

function id(id) { return document.getElementById(id) }

function wireHTML() {
  window.onhashchange = () => {
    id('transactions').hidden = true
    id('summary').hidden = true
    id('settings').hidden = true
    id('expense').hidden = true
    switch(location.hash) {
      case '#transactions':
        id('expense-navigation').hidden = true
        id('navigation').hidden = false
        id('transactions').hidden = false
        break
      case '#summary':
        id('expense-navigation').hidden = true
        id('navigation').hidden = false
        id('summary').hidden = false
        break
      case '#settings':
        id('expense-navigation').hidden = true
        id('navigation').hidden = false
        id('settings').hidden = false
        break
      case '#expense':
        id('navigation').hidden = true
        id('expense-navigation').hidden = false
        id('expense').hidden = false
        break
    }
  }

  id('expense-cancel').onclick = () => {
    window.history.back()
  }
  id('expense-close').onclick = () => {
    window.history.back()
  }
}
