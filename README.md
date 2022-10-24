# !!! (Внимание) На данный момент в разработке. Если хочешь помочь с проектом, то велком
# ЕСИА
Методы и классы для авторизации через ЕСИА и получения данных по API

## TODO:
1. Реализовать остальные методы API
1. Улучшить интерфейсы ответов из ЕСИА (избавиться от сокращений по типу "`sbj_id`")
1. Реализовать стратегию для [omniauth](https://github.com/omniauth/omniauth)
1. Переписать расширение на GO с использованием последней версии gogost и без постоянного чтения из файла
1. Написать тесты
1. Подробно описать процесс получения и регистрации сертификата
1. Написать инструмент для замены P12FromGostCSP - OpenSource и без Windows
1. Добавить инструкцию по установке на сервер без доступа в интернет
1. Добавить sig файлы (RBS)
1. Добавить yard документацию кода
1. Улучшить базовую документацию
1. Провести нагрузочное тестирование
1. Выложить на [rubygems](https://rubygems.org)

## Установка

1. Добавляем в `Gemfile`:
  `gem 'esia-ruby', github: 'iwdt/esia-ruby'`

1. [Получаем сертификат](https://info.gosuslugi.ru/articles/Получение_тестового_сертификата_для_регистрации_ИС/) и регистрируем его в ЕСИА
1. Необходимо иметь флешку или КриптоПРО контейнер (набор файлов - `header.key`, `masks.key`, `masks2.key`, `name.key`, `primary.key`, `primary2.key`) и пароль
1. Сконвертировать ЭЦП в PCKS#12
   * Скачиваем и устанавливаем [КриптоПРО CSP](https://www.cryptopro.ru/products/csp) (триальной версии достаточно)
   * Запускаем "Инструменты КриптоПРО"
   * Переходим во вкладку Контейнеры, он подгрузит контейнер "MySite.001" с флешки (у него будет уже нормальное имя), жмем Импортировать
   * Покупаем и устанавливаем [P12FromGostCSP](http://soft.lissi.ru/ls_product/utils/p12fromcsp/)
   * Запускаем P12FromGostCSP, он подгрузит ключ из КриптоПРО. Жмем Экспортировать, выбираем папку
   * Мы получили файл в фомате `pfx`

1. Сконвертировать сертификат и ключ в `pem` формат
   * Переходим в директорию с файлом `p12.pfx`
   * Формируем приватный ключ
     ```bash
     docker run --rm -v `pwd`:`pwd` -w `pwd` -it rnix/openssl-gost openssl pkcs12 -in p12.pfx -nocerts -out key.pem -nodes`
     ```
   * Формируем сертификат
     ```bash
     docker run –rm -v `pwd`:`pwd`-w `pwd` -it rnix/openssl-gost openssl pkcs12 -in p12.pfx -nokeys -out cert.pem
     ```
   * Сохраняем в удобное место файлы `key.pem` и `cert.pem`
    
1. (Опционально) Проверем что все прошло успешно

   * Генерим публичный ключ
     ```bash
     docker run –rm -v `pwd`:`pwd` -w `pwd` rnix/openssl-gost openssl x509 -pubkey -noout -in cert.pem > pubkey.pem
     ```
   * Создаем сообщение
     ```bash
     echo "Some Data" > file.txt
     ```
   * Подписываем сообщение
     ```bash
     docker run --rm -v `pwd`:`pwd` -w `pwd` rnix/openssl-gost openssl dgst -md_gost12_256 -sign key.pem file.txt | base64 > signed.txt
     ```

   * Раскодируем из base64 в бинарный формат:
     ```bash
     base64 -D -in signed.txt > signed.bin
     ```

   * И проверяем подпись, сравнивая с исходным файлом и подписью:
     ```bash
     docker run --rm -v `pwd`:`pwd` -w `pwd` rnix/openssl-gost openssl dgst -md_gost12_256 -verify pubkey.pem -signature signed.bin file.txt
     ```

## Использование

1. Настройка:

   * Сертификат и приватный ключ в формате `.pem` кладем в удобное место
   * Глобальные настройки подключения к ЕСИА
   ```ruby
   require 'esia-ruby'

   ESIA.configure do |config|
     config.certificate_path = Rails.root.join('config/credentials/cert.pem').to_s # Полный путь до сертификата
     config.private_key_path = Rails.root.join('config/credentials/key.pem').to_s # Полный путь до приватного ключа
     config.scope = "openid fullname contacts email mobile" # Список разрешений
     config.client_id = "CLIENT_ID" # Зарегестрированный в ЕСИА client id
     config.base_url = "https://esia-portal1.test.gosuslugi.ru" # Базовая ссылка на ЕСИА
   end
   ```
   * Создаем клиент для запросов:

   ```ruby
   client = ESIA::Client.new
   ```

   * Получаем ссылку перехода пользователя для авторизации:

   ```ruby
   uri = client.oauth2_uri(redirect_to: 'http://localhost:3000/auth/esia/callback')
   ```

   * После успешной авторизации, пользоваетеля переведет на ранее указанный `redirect_to` с переданными query string параметрами `code` и `state`. Нам необходимо `code` обменять на токен:

   ```ruby
   code = params[:code]
   token = client.fetch_token code: code, redirect_to: 'http://localhost:3000/auth/esia/callback'
   ```

   * Получаем пользователя:

   ```ruby
   user = client.fetch_user token: token
   ```

   * Получаем контакты:

   ```ruby
   contacts = client.fetch_contacts token: token, params: { embed: '(elements)' }
   ```