# Этап 2. Небезопасное формирование запроса.
# Только печатает текст запроса, к базе НЕ подключается.

username = input("Введите логин: ")

query = (
    "SELECT id, username FROM app_users "
    + "WHERE username = '" + username + "'"
)

print(query)
