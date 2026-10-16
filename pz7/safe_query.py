# Этап 3-4. Безопасный запрос: параметры + проверка формата.
import os
import re
import sys

import psycopg

username = input("Введите логин: ")

if not re.fullmatch(r"[A-Za-z0-9_]{3,30}", username):
    print("Ошибка: логин должен содержать 3-30 символов: "
          "латинские буквы, цифры или знак подчёркивания.")
    sys.exit(1)

connection_string = os.environ["DATABASE_URL"]

with psycopg.connect(connection_string) as conn:
    with conn.cursor() as cursor:
        cursor.execute(
            """
            SELECT id, username, full_name
            FROM app_users
            WHERE username = %s
            """,
            (username,),
        )
        rows = cursor.fetchall()

        if rows:
            for row in rows:
                print(row)
        else:
            print("Пользователь не найден")
