# Практические задания по concat() и merge() в Pandas
# Данные: IMDb movies extensive dataset (movies.csv, ratings.csv)
import pandas as pd

pd.set_option('display.width', 200)
pd.set_option('display.max_columns', 20)

movies = pd.read_csv('movies.csv', low_memory=False)
ratings = pd.read_csv('ratings.csv')
# в этой версии датасета колонка title локализована (итальянские названия), для вывода берём original_title
movies['year'] = pd.to_numeric(movies['year'], errors='coerce')  # в колонке есть мусор вроде 'TV Movie 2019'

print('movies:', movies.shape, ' ratings:', ratings.shape)


def task(n, text):
    print(f'\n{"=" * 70}\nЗадание {n}. {text}\n{"=" * 70}')


# ---------------- pd.concat() ----------------

task(1, 'Два DataFrame вручную, вертикально, ignore_index=True')
df1 = pd.DataFrame({'title': ['Tenet', 'Soul', 'Nomadland', 'Mank', 'Minari'], 'year': 2020})
df2 = pd.DataFrame({'title': ['Joker', 'Parasite', '1917', 'Us', 'Midsommar'], 'year': 2019})
df_2019_2020 = pd.concat([df1, df2], ignore_index=True)
print(df_2019_2020)

task(2, 'part1 (первые 1000) + part2 (следующие 1000), проверка совпадения')
part1 = movies.iloc[:1000]
part2 = movies.iloc[1000:2000]
restored = pd.concat([part1, part2])
print('совпадает с movies.iloc[:2000]:', restored.equals(movies.iloc[:2000]))

task(3, 'ids + budgets горизонтально (axis=1)')
sample = movies.head(10)
ids = sample[['imdb_title_id']]
budgets = sample[['budget']]
print(pd.concat([ids, budgets], axis=1))

task(4, 'info + extra горизонтально, 6 колонок без дубля imdb_title_id')
info = movies[['imdb_title_id', 'title', 'year']]
extra = movies[['imdb_title_id', 'duration', 'country']]
joined = pd.concat([info, extra.drop(columns='imdb_title_id')], axis=1)
print(joined.head())
print('колонок:', joined.shape[1], list(joined.columns))  # 3 + 3 - 1 общий id = 5 (6 было бы с дублем imdb_title_id)

task(5, 'action + comedy вертикально')
action = movies[movies['genre'].str.contains('Action', na=False)]
comedy = movies[movies['genre'].str.contains('Comedy', na=False)]
action_comedy = pd.concat([action, comedy])
print(f'action={len(action)}, comedy={len(comedy)}, action_comedy={len(action_comedy)} строк')
print('(фильмы с обоими жанрами попали дважды:', action_comedy['imdb_title_id'].duplicated().sum(), ')')

task(6, 'high_rated + low_rated с колонкой category')
high_rated = ratings[ratings['mean_vote'] >= 8].assign(category='high')
low_rated = ratings[ratings['mean_vote'] < 5].assign(category='low')
rated = pd.concat([high_rated, low_rated], ignore_index=True)
print(rated[['imdb_title_id', 'mean_vote', 'category']].head())
print(rated['category'].value_counts())

# ---------------- pd.merge() ----------------

task(7, 'inner join movies + ratings')
inner = pd.merge(movies, ratings, on='imdb_title_id', how='inner')
print('фильмов после inner join:', len(inner))

task(8, 'left join, выбранные колонки, первые 10')
left = pd.merge(movies, ratings, on='imdb_title_id', how='left')
print(left[['title', 'year', 'director', 'mean_vote', 'total_votes']].head(10))

task(9, 'right join (ratings слева)')
right = pd.merge(ratings, movies, on='imdb_title_id', how='left')  # ratings слева = left join от ratings
print('строк:', len(right))
print('рейтингов без фильма в movies:', right['title'].isna().sum(), '(в этой версии датасета ratings и movies совпадают 1:1)')

task(10, 'outer join + indicator')
outer = pd.merge(movies, ratings, on='imdb_title_id', how='outer', indicator=True)
print(outer['_merge'].value_counts())
print('\nа) фильмы без рейтинга:')
print(outer[outer['_merge'] == 'left_only'][['imdb_title_id', 'title', 'year']].head())
print('\nб) рейтинги без фильма:')
print(outer[outer['_merge'] == 'right_only'][['imdb_title_id', 'mean_vote', 'total_votes']].head())

task(11, 'личные оценки, left join на movies')
bonus = pd.DataFrame({
    'imdb_title_id': ['tt0111161', 'tt0068646', 'tt0468569', 'tt0071562'],
    'my_personal_score': [10, 9.5, 9.8, 9.7],
})
with_bonus = pd.merge(movies, bonus, on='imdb_title_id', how='left')
print(with_bonus[with_bonus['my_personal_score'].notna()][['imdb_title_id', 'original_title', 'year', 'my_personal_score']])

task(12, 'Christopher Nolan + рейтинги, сортировка по mean_vote')
nolan = movies[movies['director'] == 'Christopher Nolan']
nolan = pd.merge(nolan, ratings, on='imdb_title_id', how='left').sort_values('mean_vote', ascending=False)
print(nolan[['original_title', 'year', 'mean_vote', 'total_votes']])

task(13, 'countries через split/explode, country_count, join по первой стране')
countries = movies['country'].str.split(', ').explode().dropna().drop_duplicates().to_frame('country')
print('уникальных стран:', len(countries))
country_count = (movies['country'].str.split(', ').explode()
                 .value_counts().rename_axis('country').reset_index(name='film_count'))
movies_cc = movies.assign(first_country=movies['country'].str.split(', ').str[0])
movies_cc = pd.merge(movies_cc, country_count, left_on='first_country', right_on='country', how='left')
print(movies_cc[['first_country', 'film_count']].drop_duplicates()
      .sort_values('film_count', ascending=False).head(10).to_string(index=False))

task(14, 'фильмы США + рейтинги, топ-15 по total_votes')
usa = movies[movies['country'] == 'USA']
usa = pd.merge(usa, ratings, on='imdb_title_id', how='left')
print(usa.nlargest(15, 'total_votes')[['original_title', 'year', 'total_votes', 'mean_vote']].to_string(index=False))

task(15, 'old (<1980) / new (>=2010), period, сводная по mean_vote')
old = pd.merge(movies[movies['year'] < 1980], ratings, on='imdb_title_id', how='left').assign(period='old')
new = pd.merge(movies[movies['year'] >= 2010], ratings, on='imdb_title_id', how='left').assign(period='new')
periods = pd.concat([old, new], ignore_index=True)
print(periods.pivot_table(values='mean_vote', index='period', aggfunc=['mean', 'count']))
