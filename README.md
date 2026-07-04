# Docker TODO App

FastAPI、PostgreSQL、Docker Compose で動くシンプルな TODO アプリです。

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

2. コンテナを起動します。

```bash
docker compose up -d --build
```

3. ブラウザで開きます。

```text
http://localhost:8000
```

## 補足

- `todo-gate` ネットワークは Docker Compose が自動作成します。
- PostgreSQL のデータは `db_data` ボリュームに保存されます。
- DB を外部ツールから見る場合は `localhost:5432` に接続します。

## よく使うコマンド

```bash
docker compose logs web
docker compose logs db
docker compose down
```
