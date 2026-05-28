import { createI18n } from 'vue-i18n'
import ca from './locales/ca.json'
import es from './locales/es.json'
import en from './locales/en.json'
import ru from './locales/ru.json'

const savedLocale = localStorage.getItem('locale')

const i18n = createI18n({
  legacy: false,
  locale: savedLocale || 'ca',
  fallbackLocale: 'ca',
  messages: { ca, es, en, ru },
})

export default i18n
