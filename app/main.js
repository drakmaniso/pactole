'use strict'

import * as client from './client.js'

function log(msg) {
  console.log(`[client] ${msg}`)
}

if (!('serviceWorker' in navigator)) {
  log('FATAL: Service workers are not supported by the navigator.')
  throw(new Error('FATAL: Service workers are not supported by the navigator.'))
}

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

  window.onhashchange = () => {
    document.getElementById('transactions-main').hidden = true
    document.getElementById('summary-main').hidden = true
    document.getElementById('settings-main').hidden = true
    document.getElementById(`${location.hash}-main`.slice(1)).hidden = false
  }

  document.getElementById('expense-action').onclick = () => {
    document.getElementById('transactions-list').hidden = true
    document.getElementById('banner').hidden = true
    document.getElementById('banner-dialog').hidden = false
    document.getElementById('expense-dialog').hidden = false
  }
  document.getElementById('expense-cancel').onclick = () => {
    document.getElementById('expense-dialog').hidden = true
    document.getElementById('banner-dialog').hidden = true
    document.getElementById('banner').hidden = false
    document.getElementById('transactions-list').hidden = false
  }
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
