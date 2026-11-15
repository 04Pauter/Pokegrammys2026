import { createI18n } from 'vue-i18n'
import ca from './locales/ca.json'
import es from './locales/es.json'
import en from './locales/en.json'
import ru from './locales/ru.json'

const savedLocale = localStorage.getItem('locale')
const availableLocales = ['ca', 'es', 'en', 'ru']

/* Regla de plural en rus: una / poques / moltes.
   La regla per defecte de vue-i18n és `min(count, 2)`, que no
   diferencia 2 (голоса) de 5 (голосов). */
function russianPlural(choice) {
  if (choice === 0) return 0
  const mod10 = choice % 10
  const mod100 = choice % 100
  const isTeen = mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)
  if (mod10 === 1 && mod100 !== 11) return 1
  if (isTeen) return 2
  return 3
}

const i18n = createI18n({
  legacy: false,
  locale: availableLocales.includes(savedLocale) ? savedLocale : 'es',
  fallbackLocale: 'es',
  messages: { ca, es, en, ru },
  pluralRules: {
    ru: russianPlural
  }
})

export default i18n
