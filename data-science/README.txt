Данные: IMDb movies extensive dataset (Kaggle, stefanoleone992), файлы IMDb movies.csv и IMDb ratings.csv.
Скачать как movies.csv / ratings.csv:
curl -sL -o movies.csv  "https://raw.githubusercontent.com/sahildit/IMDB-Movies-Extensive-Dataset-Analysis/master/data1/IMDb%20movies.csv"
curl -sL -o ratings.csv "https://raw.githubusercontent.com/sahildit/IMDB-Movies-Extensive-Dataset-Analysis/master/data1/IMDb%20ratings.csv"

python3 -m venv .venv && .venv/bin/pip install pandas
.venv/bin/python tasks9.py        # вывод всех 15 заданий, сохранён в output9.txt
tasks9.ipynb — то же в виде ноутбука (ячейки уже выполнены)
