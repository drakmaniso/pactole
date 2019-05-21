'use strict'

const dayNames = [
  'Lundi',
  'Mardi',
  'Mercredi',
  'Jeudi',
  'Vendredi',
  'Samedi',
  'Dimanche',
]

const monthNames = [
  'Janvier',
  'Février',
  'Mars',
  'Avril',
  'Mai',
  'Juin',
  'Juillet',
  'Août',
  'Septembre',
  'Octobre',
  'Novembre',
  'Décembre',
]

export function sameDate(a, b) {
  return a.getDate() === b.getDate()
    && a.getMonth() === b.getMonth()
    && a.getFullYear() === b.getFullYear()
}

export function dayNumber(date) {
  return date.getDate()
}

export function dayName(date) {
  let day = (date.getDay() + 6) % 7
  return dayNames[day]
}

export function monthName(date) {
  return monthNames[date.getMonth()]
}
