# Этап 3 без проверки формата: показывает, что параметризация сама по себе
# обрабатывает апостроф как обычное значение.
import os
import psycopg

username = input("Введите логин: ")
with psycopg.connect(os.environ["DATABASE_URL"]) as conn:
    with conn.cursor() as cursor:
        cursor.execute(
            "SELECT id, username, full_name FROM app_users WHERE username = %s",
            (username,),
        )
        rows = cursor.fetchall()
        print(rows if rows else "Пользователь не найден")
