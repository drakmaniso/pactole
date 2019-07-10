'use strict'

///////////////////////////////////////////////////////////////////////////////

export function get(name) {
  const s = localStorage.getItem(name)
  if (!s) {
    const d = defaults[name]
    localStorage.setItem(name, JSON.stringify(d))
    return d
  }
  return JSON.parse(s)
}

export function set(name, value) {
  const s = localStorage.setItem(name, JSON.stringify(value))
}

const defaults = {
  mode: 'calendar',
  useCategories: false,
  categories: [
    { name: 'Maison', icon: '\uf015' },
    { name: 'Santé', icon: '\uf0f1' },
    { name: 'Nourriture', icon: '\uf2e7' },
    { name: 'Habillement', icon: '\uf553' },
    { name: 'Transport', icon: '\uf1b9' },
    { name: 'Loisirs', icon: '\uf11b' },
    { name: 'Autre', icon: '\uf128' },
  ],
  useReconciliation: false,
}
