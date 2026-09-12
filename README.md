# Docker TODO App

FastAPI、PostgreSQL、Docker Compose で動くシンプルな TODO アプリです。

Docker、DB、GitHub Issue/PR URL、`owner/repo#123` を貼ると、ローカルの作業キューとしてキーワードやタグを見やすく表示します。外部サービスに書き込まないので、未整理の調査メモや次回作業TODOを手元だけに残せます。

## 公開前の注意

- `.env` にはDBユーザー名やパスワードなどの秘密情報が入るため、GitHubにはアップロードしません。
- `.gitignore` と `.dockerignore` で `.env` を除外しています。
- AIアシスタントや共同作業者がローカルファイルを読める環境では、`.env` も読めてしまう可能性があります。実運用のパスワード、APIキー、トークンはローカル検証用リポジトリに置かず、必要になった時点でGitHub SecretsやクラウドのSecret Managerへ移してください。
- 誤って秘密情報をGitHubにpushした場合は、ファイルを消すだけでなく、該当するパスワードやトークンを必ず再発行してください。

## 起動方法

1. `.env.example` を参考に `.env` を作成します。

```bash
cp .env.example .env
```

既に `.env` がある場合は、次の3つの値が空でないことを確認します。

```text
DB_USER=todo_user
DB_PASSWORD=change_me
DB_NAME=tododb
```

公開用のサンプル値なので、外部に公開する環境では別の強い値に変更してください。

### ローカルDBのパスワードを忘れた/変えたい場合

PostgreSQLのDockerボリュームを初期化済みの場合、`.env` の `DB_PASSWORD` を変えるだけでは既存DBユーザーのパスワードは変わりません。

データを捨ててよい場合は、`.env` を更新してからDBボリュームごと作り直します。

```bash
docker compose -p github-todo-app down -v
make start
```

データを残したい場合は、`.env` を更新したあとDBコンテナを作り直し、PostgreSQL側のパスワードも変更します。

```bash
docker compose -p github-todo-app up -d --force-recreate db
docker compose -p github-todo-app exec db sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "ALTER USER \"$POSTGRES_USER\" WITH PASSWORD '\''$POSTGRES_PASSWORD'\'';"'
docker compose -p github-todo-app up -d --force-recreate web
```

現在のWSL環境で `docker` が見つからない場合は、Docker Desktop の WSL integration を有効にしてから実行してください。

2. コンテナを起動します。

```bash
make start
```

3. ブラウザで開きます。

```text
http://localhost:8000
```

## 毎日使うコマンド

Docker Composeの細かいコマンドを覚えなくても使えるように、よく使う操作は `Makefile` にまとめています。

```bash
make start
make status
make stop
```

- `make start`: ローカルアプリを起動します。
- `make status`: `todo-db` と `todo-web` の状態を確認します。
- `make stop`: DBデータを残したままコンテナを止めます。
- `make check`: `http://localhost:8000` と `/todos` の疎通を確認します。
- `make db-shell`: `todo-db` のPostgreSQLに入ります。

起動後のURL:

```text
http://localhost:8000
```

## 補足

- `todo-gate` ネットワークは Docker Compose がプロジェクト用ネットワークとして自動作成します。
- PostgreSQL のデータは `db_data` ボリュームに保存されます。
- DB を外部ツールから見る場合は `localhost:5433` に接続します。

## よく使うコマンド

```bash
make logs-web
make logs-db
make stop
```
